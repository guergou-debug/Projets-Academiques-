#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script 04: Fusion du jeu de données WDI existant et de la série NTL Harmonisée (2000-2025).

Description:
------------
1. Appelle directement le fichier CSV WDI existant dans data/raw/.
2. Charge la série temporelle NTL harmonisée produite par 03_process_ntl.py.
3. Fusionne les deux bases sur l'année ('year').
4. Calcule l'indice d'intensité lumineuse par habitant :
   ntl_per_capita = ntl_sum_adj / population
5. Génère la base de données finale dans data/final/niger_ntl_gdp_2000_2025.csv.
"""

from pathlib import Path
import pandas as pd


def load_existing_wdi(raw_dir: Path) -> pd.DataFrame:
    """Recherche et charge le fichier WDI déjà enregistré dans data/raw/."""
    # Recherche dans data/raw/wdi/ ou data/raw/
    wdi_files = list(raw_dir.glob("**/wdi*.csv")) + list(raw_dir.glob("**/*wdi*.csv")) + list(raw_dir.glob("**/niger_wdi*.csv"))
    
    # Filtrer pour exclure d'éventuels fichiers temporaires
    wdi_files = [f for f in wdi_files if f.is_file()]

    if not wdi_files:
        raise FileNotFoundError(
            f"Aucun fichier WDI n'a été trouvé dans {raw_dir}.\n"
            "Assurez-vous que votre fichier WDI y est bien enregistré sous forme de fichier CSV."
        )

    wdi_path = wdi_files[0]
    print(f"[✓] Fichier WDI trouvé et appelé : {wdi_path}")
    return pd.read_csv(wdi_path)


def build_final_dataset(data_dir: Path) -> pd.DataFrame:
    """Fusionne la base WDI existante avec la base NTL harmonisée et dérive ntl_per_capita."""
    raw_dir = data_dir / "raw"
    ntl_file = data_dir / "intermediate" / "ntl_processed" / "niger_ntl_harmonized_2000_2025.csv"

    # 1. Appel direct des données WDI existantes
    df_wdi = load_existing_wdi(raw_dir)

    # 2. Appel de la série NTL Harmonisée
    if not ntl_file.exists():
        raise FileNotFoundError(
            f"La base NTL harmonisée est introuvable sous : {ntl_file}\n"
            "Veuillez exécuter au préalable le script 'python scripts/03_process_ntl.py'."
        )
    df_ntl = pd.read_csv(ntl_file)

    # 3. Fusion sur la colonne 'year'
    df_merged = pd.merge(df_wdi, df_ntl, on="year", how="inner")

    # 4. Calcul de l'indice de lumière totale par habitant
    df_merged["ntl_per_capita"] = df_merged["ntl_sum_adj"] / df_merged["population"]

    # Calcul optionnel du taux de croissance annuel des lumières (% Δ NTL)
    df_merged["ntl_growth"] = df_merged["ntl_sum_adj"].pct_change() * 100

    # Réorganisation propre des colonnes pour l'analyse économétrique
    columns_order = [
        "year",
        "gdp_real",
        "gdp_growth",
        "population",
        "gdp_pc_real",
        "ntl_sum_adj",
        "ntl_mean_adj",
        "ntl_per_capita",
        "ntl_growth",
        "ntl_lit_count",
        "sensor",
        "dummy_viirs"
    ]

    final_cols = [col for col in columns_order if col in df_merged.columns]
    remaining_cols = [col for col in df_merged.columns if col not in final_cols]

    df_final = df_merged[final_cols + remaining_cols].copy()
    df_final = df_final.sort_values("year").reset_index(drop=True)

    return df_final


def main():
    project_root = Path(__file__).resolve().parent.parent
    data_dir = project_root / "data"
    final_dir = data_dir / "final"
    final_dir.mkdir(parents=True, exist_ok=True)

    print("==================================================")
    print(" Fusion WDI (Existant) + NTL Harmonisé (2000-2025)")
    print("==================================================")

    # Construction de la base finale
    df_final = build_final_dataset(data_dir)

    # Sauvegarde finale
    output_path = final_dir / "niger_ntl_gdp_2000_2025.csv"
    df_final.to_csv(output_path, index=False)

    print(f"\n[✓] Jeu de données final créé avec succès ({len(df_final)} lignes) :")
    print(f"    -> {output_path}")

    print("\nAperçu des colonnes finales :")
    print(df_final.head(3))


if __name__ == "__main__":
    main()