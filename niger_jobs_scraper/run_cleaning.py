import json
from pathlib import Path
import pandas as pd

from cleaning import (
    fix_mojibake,
    is_valid_offer_url,
    extract_all_metadata,
    deduplicate_offers,
)

# Résolution automatique de la racine du projet (indépendant du répertoire d'appel)
PROJECT_ROOT = Path(__file__).resolve().parent


def locate_raw_csv(root: Path) -> Path:
    """Recherche offres.csv dans les emplacements standards du projet."""
    candidates = [
        root / "data" / "processed" / "offres.csv",
        root / "data" / "offres.csv",
        root / "offres.csv",
    ]
    for path in candidates:
        if path.exists():
            return path
    raise FileNotFoundError(
        f"Fichier 'offres.csv' introuvable. Chemins vérifiés : {[str(p) for p in candidates]}"
    )


def main():
    input_path = locate_raw_csv(PROJECT_ROOT)
    output_dir = PROJECT_ROOT / "data" / "cleaned"
    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"[1/5] Chargement de : {input_path}")
    df_raw = pd.read_csv(input_path)

    print("[2/5] Réparation de l'encodage (Mojibake UTF-8/Latin-1)...")
    for col in df_raw.select_dtypes(include="object").columns:
        df_raw[col] = df_raw[col].apply(fix_mojibake)

    print("[3/5] Filtrage des vraies pages d'offres...")
    df_valid = df_raw[df_raw["url_offre"].apply(is_valid_offer_url)].copy()
    print(f"      -> {len(df_raw)} lignes brutes => {len(df_valid)} annonces valides")

    print("[4/5] Extraction des métadonnées et déduction géographique (Niger)...")
    df_extracted = extract_all_metadata(df_valid)

    print("[5/5] Dédoublonnage intra et inter-plateformes...")
    df_final = deduplicate_offers(df_extracted)
    print(f"      -> {len(df_final)} annonces uniques conservées")

    # Exports dans data/cleaned/
    csv_out = output_dir / "offres_nettoyees.csv"
    json_out = output_dir / "offres_nettoyees.json"
    parquet_out = output_dir / "offres_nettoyees.parquet"

    df_final.to_csv(csv_out, index=False, encoding="utf-8-sig")

    records_json = json.loads(df_final.to_json(orient="records", force_ascii=False))
    for rec in records_json:
        rec["sources_multiples"] = rec["sources_multiples"].split(" ; ") if rec["sources_multiples"] else []
        rec["urls_alternatives"] = rec["urls_alternatives"].split(" ; ") if rec["urls_alternatives"] else []

    with open(json_out, "w", encoding="utf-8") as f:
        json.dump(records_json, f, ensure_ascii=False, indent=2)

    try:
        df_final.to_parquet(parquet_out, index=False)
        parquet_msg = str(parquet_out)
    except ImportError:
        parquet_msg = "ignoré (pyarrow non installé)"

    print("\nExports générés avec succès :")
    print(f"  - CSV     : {csv_out}")
    print(f"  - JSON    : {json_out}")
    print(f"  - Parquet : {parquet_msg}")
    return df_final


if __name__ == "__main__":
    main()