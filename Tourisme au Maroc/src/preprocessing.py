#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
MOROCCO-STAY — Prétraitement des données touristiques marocaines
Conçu pour les fichiers CKAN présents dans data/raw/tourism/.

Usage (depuis la racine du projet) :
    python src/preprocessing.py
    python src/preprocessing.py --verbose

Le script ne modifie jamais data/raw/. Il ne confond pas les données OSM
avec des annonces Airbnb. Les classeurs sectoriels complexes sont inventoriés
séparément et ne sont pas fusionnés automatiquement aux séries annuelles.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import logging
import re
import sys
from datetime import datetime
from io import BytesIO
from pathlib import Path
from typing import Any

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RAW_TOURISM = ROOT / "data" / "raw" / "tourism"
PROCESSED = ROOT / "data" / "processed"
AUDIT = ROOT / "outputs" / "audit"

# Préfixes observés dans l'inventaire réel transmis par l'utilisateur.
# On ne dépend pas des UUID CKAN, ni de l'extension parfois absente.
SOURCE_SPECS = {
    "tourism_destination": {
        "prefix": "evolution-nuitees-realisees-etablissements-d-hebergement-touristique-par-destination-2012-2020_",
        "indicator": "Nuitées réalisées par destination",
        "unit": "nuitées",
        "dimension": "geography",
        "output": "tourism_destination.csv",
    },
    "capacity_destination": {
        "prefix": "evolution-par-destination-de-la-capacite-hoteliere-classee-en-lits-2012-2020_",
        "indicator": "Capacité hôtelière classée par destination",
        "unit": "lits",
        "dimension": "geography",
        "output": "capacity_destination.csv",
    },
    "capacity_category": {
        "prefix": "evolution-par-categorie-de-la-capacite-hoteliere-classee-en-lits-2012-2020_",
        "indicator": "Capacité hôtelière classée par catégorie",
        "unit": "lits",
        "dimension": "category",
        "output": "capacity_category.csv",
    },
    "tourism_market_nights": {
        "prefix": "evolution-par-marche-des-nuitees-realisees-etablissements-d-hebergement-touristique-2012-2020_",
        "indicator": "Nuitées réalisées par marché",
        "unit": "nuitées",
        "dimension": "market",
        "output": "tourism_market_nights.csv",
    },
    "arrivals_nationality": {
        "prefix": "evolution-par-nationalite-des-arrivees-des-touristes-aux-postes-frontieres-2012-2020_",
        "indicator": "Arrivées de touristes aux postes frontières par nationalité",
        "unit": "arrivées",
        "dimension": "nationality",
        "output": "arrivals_nationality.csv",
    },
    "arrivals_entry_point": {
        "prefix": "evolution-par-point-d-entree-des-arrivees-des-touristes-aux-postes-frontieres-2012-2020_",
        "indicator": "Arrivées de touristes par point d'entrée",
        "unit": "arrivées",
        "dimension": "entry_point",
        "output": "arrivals_entry_point.csv",
    },
}

YEAR_RE = re.compile(r"^(?:19|20)\d{2}$")
LOG = logging.getLogger("morocco_stay.preprocessing")


def setup_dirs() -> None:
    for folder in (PROCESSED, AUDIT):
        folder.mkdir(parents=True, exist_ok=True)


def find_source(prefix: str) -> Path | None:
    """Recherche récursive, préfixe CKAN exact, extension non obligatoire."""
    matches = [
        p for p in RAW_TOURISM.rglob("*")
        if p.is_file() and p.name.lower().startswith(prefix.lower())
    ]
    if len(matches) > 1:
        # Ne pas choisir silencieusement entre deux versions du même fichier.
        raise RuntimeError(
            f"Plusieurs fichiers correspondent au préfixe {prefix!r}: "
            + ", ".join(str(p.relative_to(ROOT)) for p in matches)
        )
    return matches[0] if matches else None


def file_kind(path: Path) -> str:
    """Détecte le conteneur Excel par signature, même sans extension."""
    with path.open("rb") as f:
        sig = f.read(8)
    if sig.startswith(b"PK"):
        return "xlsx"
    if sig.startswith(bytes.fromhex("D0CF11E0A1B11AE1")):
        return "xls"
    raise ValueError(f"Format non reconnu (signature {sig!r}) : {path.name}")


def read_workbook(path: Path) -> dict[str, pd.DataFrame]:
    kind = file_kind(path)
    engine = "openpyxl" if kind == "xlsx" else "xlrd"
    data = path.read_bytes()
    book = pd.ExcelFile(BytesIO(data), engine=engine)
    return {
        sheet: pd.read_excel(BytesIO(data), sheet_name=sheet, header=None, engine=engine)
        for sheet in book.sheet_names
    }


def clean_label(value: Any) -> str | None:
    if pd.isna(value):
        return None
    text = str(value).replace("\n", " ").strip()
    text = re.sub(r"\s+", " ", text)
    if not text or text.lower() in {"nan", "none", "total général"}:
        return None
    return text


def parse_numeric(value: Any) -> float | None:
    if pd.isna(value):
        return None
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return float(value)
    s = str(value).strip().replace("\u00a0", "").replace(" ", "")
    if not s or s.lower() in {"nan", "nd", "n.d.", "-", "…"}:
        return None
    # Les tableaux observés utilisent des nombres entiers, parfois avec séparateurs.
    if re.fullmatch(r"-?\d{1,3}(?:[.,]\d{3})+", s):
        s = s.replace(".", "").replace(",", "")
    else:
        s = s.replace(",", ".")
    try:
        return float(s)
    except ValueError:
        return None


def year_from_cell(value: Any) -> int | None:
    if pd.isna(value):
        return None
    s = str(value).strip()
    if YEAR_RE.fullmatch(s):
        return int(s)
    # cellules Excel parfois numériques (2012.0)
    try:
        n = float(value)
        if n.is_integer() and 1900 <= n <= 2100:
            return int(n)
    except (TypeError, ValueError):
        pass
    return None


def identify_header(df: pd.DataFrame) -> tuple[int, list[tuple[int, int]]]:
    """Repère la ligne portant les années, sans supposer qu'elle est ligne 1."""
    best_row, best_years = -1, []
    for r in range(min(len(df), 12)):
        years = [(c, y) for c, v in enumerate(df.iloc[r].tolist())
                 if (y := year_from_cell(v)) is not None]
        if len(years) > len(best_years):
            best_row, best_years = r, years
    if best_row < 0 or len(best_years) < 3:
        raise ValueError("Impossible d'identifier au moins trois colonnes annuelles.")
    return best_row, best_years


def normalize_geo(label: str | None) -> str | None:
    if label is None:
        return None
    key = re.sub(r"\s+", " ", label.strip().lower())
    aliases = {
        "agadir-tag hazout": "Agadir-Taghazout",
        "agadir taghazout": "Agadir-Taghazout",
        "agadir+taghazout": "Agadir-Taghazout",
        "agadir - taghazout": "Agadir-Taghazout",
        "agadir-taghazout": "Agadir-Taghazout",
    }
    return aliases.get(key, label)


def table_to_long(path: Path, spec: dict[str, str]) -> pd.DataFrame:
    sheets = read_workbook(path)
    # Les six tableaux prioritaires sont de petits tableaux de synthèse.
    # On choisit la feuille contenant le plus de colonnes d'années détectées.
    candidates = []
    for sheet, frame in sheets.items():
        try:
            header_row, year_cols = identify_header(frame)
            candidates.append((len(year_cols), sheet, frame, header_row, year_cols))
        except ValueError:
            continue
    if not candidates:
        raise ValueError(f"Aucune feuille avec colonnes annuelles détectée : {path.name}")
    candidates.sort(key=lambda x: x[0], reverse=True)
    _, sheet, frame, header_row, year_cols = candidates[0]

    # Première colonne non annuelle contenant des libellés = dimension.
    year_indices = {c for c, _ in year_cols}
    label_col = next(
        (c for c in range(frame.shape[1]) if c not in year_indices
         and frame.iloc[header_row + 1:, c].map(clean_label).notna().sum() > 0),
        None
    )
    if label_col is None:
        raise ValueError(f"Colonne de libellés introuvable : {path.name}")

    rows = []
    for ridx in range(header_row + 1, len(frame)):
        label = clean_label(frame.iat[ridx, label_col])
        if label is None:
            continue
        # Élimine les lignes de titres, notes et agrégats vides.
        for col, year in year_cols:
            value = parse_numeric(frame.iat[ridx, col])
            if value is None:
                continue
            row = {
                "year": year,
                "period": str(year),
                "period_type": "calendar_year",
                "indicator": spec["indicator"],
                "unit": spec["unit"],
                "dimension": spec["dimension"],
                "dimension_label": label,
                "dimension_key": normalize_geo(label) if spec["dimension"] == "geography" else label,
                "value": value,
                "source_file": path.name,
                "source_sheet": sheet,
                "source_row": ridx + 1,
            }
            rows.append(row)

    out = pd.DataFrame(rows)
    if out.empty:
        raise ValueError(f"Aucune observation numérique extraite : {path.name}")
    if out.duplicated(["year", "dimension_label"]).any():
        dup = out.loc[out.duplicated(["year", "dimension_label"], keep=False),
                      ["year", "dimension_label"]]
        raise ValueError(f"Doublons année-dimension dans {path.name}: {dup.head().to_dict('records')}")
    return out


def process_osm() -> tuple[int, str]:
    candidates = [
        ROOT / "data" / "processed" / "hotels_osm.csv",
        ROOT / "data" / "processed" / "hotels_osm.parquet",
    ]
    source = next((p for p in candidates if p.exists()), None)
    if source is None:
        LOG.warning("Table OSM prétraitée introuvable (hotels_osm.csv/parquet).")
        return 0, "absent"
    if source.suffix == ".parquet":
        df = pd.read_parquet(source)
    else:
        df = pd.read_csv(source)
    # Copie normalisée ; aucune assimilation aux annonces de location courte durée.
    df["data_source"] = "OpenStreetMap"
    df["is_airbnb_listing"] = pd.NA
    df["osm_observation_note"] = "Objet OSM ; ne constitue pas une annonce Airbnb vérifiée."
    target = PROCESSED / "osm_accommodation.csv"
    df.to_csv(target, index=False, encoding="utf-8-sig")
    return len(df), str(target.relative_to(ROOT))


def inventory_complex_sectorial() -> list[dict[str, Any]]:
    prefixes = (
        "indicateurs-sectoriels-",
        "indicateurs-sectoriels-tourisme-",
        "indicateurs-tourisme-",
        "activites-sectorielles-tourisme_",
        "recettes-en-devises-",
        "liste-des-etablissements-d-hebergement-touristique_",
    )
    records = []
    for p in sorted(RAW_TOURISM.rglob("*")):
        if p.is_file() and p.name.lower().startswith(prefixes):
            try:
                sheets = read_workbook(p)
                detail = "; ".join(f"{name}:{df.shape[0]}x{df.shape[1]}"
                                   for name, df in sheets.items())
                status = "inventoried_not_merged"
            except Exception as exc:
                detail = f"lecture impossible: {type(exc).__name__}: {exc}"
                status = "needs_manual_inspection"
            records.append({
                "file": p.name,
                "relative_path": str(p.relative_to(ROOT)),
                "size_kb": round(p.stat().st_size / 1024, 1),
                "sheets_dimensions": detail,
                "processing_status": status,
            })
    return records


def main() -> int:
    parser = argparse.ArgumentParser(description="Prétraitement MOROCCO-STAY")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(levelname)s | %(message)s"
    )
    setup_dirs()
    if not RAW_TOURISM.exists():
        LOG.error("Dossier introuvable : %s", RAW_TOURISM)
        return 2

    run_rows, dictionary, quality = [], [], []
    failures = []
    print("\nMOROCCO-STAY | Prétraitement des sources touristiques\n")

    for key, spec in SOURCE_SPECS.items():
        try:
            path = find_source(spec["prefix"])
            if path is None:
                raise FileNotFoundError(
                    f"Aucun fichier avec le préfixe réel attendu : {spec['prefix']}"
                )
            df = table_to_long(path, spec)
            target = PROCESSED / spec["output"]
            df.to_csv(target, index=False, encoding="utf-8-sig")
            run_rows.append({
                "dataset": key, "status": "success", "rows": len(df),
                "source": str(path.relative_to(ROOT)), "output": str(target.relative_to(ROOT))
            })
            dictionary.append({
                "dataset": key, "output_file": spec["output"],
                "columns": ", ".join(df.columns),
                "description": spec["indicator"], "unit": spec["unit"],
                "dimension": spec["dimension"],
            })
            quality.append({
                "dataset": key, "source_file": path.name,
                "rows": len(df), "missing_values": int(df.isna().sum().sum()),
                "duplicate_year_dimension": int(df.duplicated(["year", "dimension_label"]).sum()),
                "min_year": int(df["year"].min()), "max_year": int(df["year"].max()),
                "status": "OK",
            })
            print(f"OK   {key:25s} {len(df):5d} observations -> {spec['output']}")
        except Exception as exc:
            failures.append((key, str(exc)))
            run_rows.append({"dataset": key, "status": "FAILED", "rows": 0,
                             "source": "", "output": "", "error": str(exc)})
            quality.append({"dataset": key, "status": "FAILED", "error": str(exc)})
            print(f"FAIL {key}: {exc}")

    try:
        n_osm, osm_path = process_osm()
        print(f"OK   {'osm_accommodation':25s} {n_osm:5d} lignes")
    except Exception as exc:
        n_osm, osm_path = 0, ""
        failures.append(("osm_accommodation", str(exc)))
        print(f"FAIL osm_accommodation: {exc}")

    complex_inventory = inventory_complex_sectorial()
    pd.DataFrame(complex_inventory).to_csv(
        AUDIT / "complex_sources_inventory.csv", index=False, encoding="utf-8-sig"
    )
    pd.DataFrame(run_rows).to_csv(
        AUDIT / "preprocessing_run_summary.csv", index=False, encoding="utf-8-sig"
    )
    pd.DataFrame(dictionary).to_csv(
        AUDIT / "preprocessing_data_dictionary.csv", index=False, encoding="utf-8-sig"
    )
    pd.DataFrame(quality).to_csv(
        AUDIT / "preprocessing_quality_report.csv", index=False, encoding="utf-8-sig"
    )
    summary = {
        "project": "MOROCCO-STAY",
        "run_at": datetime.now().astimezone().isoformat(timespec="seconds"),
        "raw_directory": str(RAW_TOURISM),
        "successful_priority_datasets": sum(r["status"] == "success" for r in run_rows),
        "expected_priority_datasets": len(SOURCE_SPECS),
        "failures": [{"dataset": k, "error": v} for k, v in failures],
        "osm_rows": n_osm,
        "osm_output": osm_path,
        "complex_sources_inventoried": len(complex_inventory),
        "note": "Les sources sectorielles complexes sont inventoriées mais non fusionnées automatiquement.",
    }
    (AUDIT / "preprocessing_run_summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    print("\n" + "=" * 68)
    if failures:
        print("PRÉTRAITEMENT INCOMPLET — certaines sources prioritaires ont échoué.")
        print(f"Jeux prioritaires réussis : {summary['successful_priority_datasets']}/{len(SOURCE_SPECS)}")
        print("Consulte outputs/audit/preprocessing_run_summary.csv et le rapport qualité.")
        return 1
    print("PRÉTRAITEMENT TERMINÉ — les six tables prioritaires ont été traitées.")
    print(f"Tables : {PROCESSED}")
    print(f"Audit  : {AUDIT}")
    print("=" * 68)
    return 0


if __name__ == "__main__":
    sys.exit(main())
