#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script 03: Processus d'harmonisation des données NTL (DMSP & VIIRS) pour le Niger (2000-2025).

Méthodologie:
-------------
1. Lecture des extractions brutes GEE (DMSP/OLS et VIIRS/DNB).
2. Alignement et raccordement par facteur d'échelle (Ratio Scaling Factor) 
   au niveau agrégé pour garantir la continuité temporelle entre les capteurs.
3. Calcul des variables harmonisées : ntl_sum_adj, ntl_mean_adj, ntl_per_capita.
4. Exportation du jeu de données intermédiaire harmonisé.
"""

from pathlib import Path
import pandas as pd
import numpy as np


def load_raw_data(data_dir: Path) -> tuple[pd.DataFrame, pd.DataFrame]:
    """Charge les fichiers CSV bruts DMSP et VIIRS depuis le répertoire source."""
    raw_dir = data_dir / "raw"
    
    # Chemins des fichiers (supporte les sous-dossiers ntl, dmsp, viirs ou le dossier raw racine)
    dmsp_path = list(raw_dir.glob("**/niger_ntl_dmsp_2000_2011.csv")) + list(raw_dir.glob("*dmsp*.csv"))
    viirs_path = list(raw_dir.glob("**/niger_ntl_viirs_2012_2025.csv")) + list(raw_dir.glob("*viirs*.csv"))

    if not dmsp_path:
        raise FileNotFoundError("Le fichier CSV DMSP (niger_ntl_dmsp_2000_2011.csv) est introuvable dans data/raw/")
    if not viirs_path:
        raise FileNotFoundError("Le fichier CSV VIIRS (niger_ntl_viirs_2012_2025.csv) est introuvable dans data/raw/")

    df_dmsp = pd.read_csv(dmsp_path[0])
    df_viirs = pd.read_csv(viirs_path[0])

    return df_dmsp, df_viirs


def harmonize_series(df_dmsp: pd.DataFrame, df_viirs: pd.DataFrame) -> pd.DataFrame:
    """
    Raccorde la série DMSP (Digital Numbers) sur l'échelle VIIRS (Radiance)
    afin de créer une série homogène 2000-2025.
    """
    # Tri par année
    df_dmsp = df_dmsp.sort_values("year").reset_index(drop=True)
    df_viirs = df_viirs.sort_values("year").reset_index(drop=True)

    # Assurer l'alignement des colonnes principales
    cols_to_keep = ["year", "sensor", "ntl_sum", "ntl_mean", "ntl_lit_count"]
    df_dmsp = df_dmsp[cols_to_keep].copy()
    df_viirs = df_viirs[cols_to_keep].copy()

    # Concatenation brute
    df_full = pd.concat([df_dmsp, df_viirs], ignore_index=True)

    # -------------------------------------------------------------------------
    # HARMONISATION PAR FACTEUR D'ÉCHELLE AU POINT DE RACCORDEMENT (2012/2013)
    # -------------------------------------------------------------------------
    # On utilise la première année VIIRS disponible (2012 ou 2013) et la dernière année DMSP
    # pour calibrer le ratio d'intensité entre les deux capteurs.
    
    dmsp_last_sum = df_dmsp.loc[df_dmsp["year"] == df_dmsp["year"].max(), "ntl_sum"].values[0]
    viirs_first_sum = df_viirs.loc[df_viirs["year"] == df_viirs["year"].min(), "ntl_sum"].values[0]

    # Ratio d'échelle : conversion DMSP (DN) -> Équivalent Radiance VIIRS
    scale_factor = viirs_first_sum / dmsp_last_sum

    print(f"[INFO] Facteur d'échelle d'harmonisation DMSP/VIIRS : {scale_factor:.6f}")

    # Application de l'ajustement
    df_full["ntl_sum_adj"] = np.where(
        df_full["sensor"] == "DMSP/OLS",
        df_full["ntl_sum"] * scale_factor,
        df_full["ntl_sum"]
    )

    df_full["ntl_mean_adj"] = np.where(
        df_full["sensor"] == "DMSP/OLS",
        df_full["ntl_mean"] * scale_factor,
        df_full["ntl_mean"]
    )

    # Indicateur binaire de capteur (dummy économétrique pour contrôle en régression)
    df_full["dummy_viirs"] = (df_full["sensor"] == "VIIRS").astype(int)

    # Tri final
    df_full = df_full.sort_values("year").reset_index(drop=True)

    return df_full


def main():
    # Définition des chemins de projet
    project_root = Path(__file__).resolve().parent.parent
    data_dir = project_root / "data"
    output_dir = data_dir / "intermediate" / "ntl_processed"
    output_dir.mkdir(parents=True, exist_ok=True)

    print("==================================================")
    print(" Traitement et Harmonisation NTL Niger (2000-2025)")
    print("==================================================")

    # 1. Chargement des données brutes
    df_dmsp, df_viirs = load_raw_data(data_dir)
    print(f"[✓] Données DMSP chargées : {len(df_dmsp)} années ({df_dmsp['year'].min()}-{df_dmsp['year'].max()})")
    print(f"[✓] Données VIIRS chargées : {len(df_viirs)} années ({df_viirs['year'].min()}-{df_viirs['year'].max()})")

    # 2. Harmonisation des deux séries
    df_harmonized = harmonize_series(df_dmsp, df_viirs)

    # 3. Exportation vers data/intermediate/ntl_processed/
    output_path = output_dir / "niger_ntl_harmonized_2000_2025.csv"
    df_harmonized.to_csv(output_path, index=False)

    print(f"[✓] Série harmonisée enregistrée avec succès : {output_path}")
    print("\nAperçu des 5 premières lignes (DMSP ajusté) :")
    print(df_harmonized.head())
    print("\nAperçu des 5 dernières lignes (VIIRS) :")
    print(df_harmonized.tail())


if __name__ == "__main__":
    main()