
from pathlib import Path
import pandas as pd
import re

BASE = Path("data/raw/tourism")

KEYWORDS = [
    "tourisme", "touriste", "nuitée", "nuit",
    "hôtel", "hotel", "hébergement", "hebergement",
    "arrivée", "arrivee", "capacité", "capacite",
    "occupation", "recette", "voyage", "lit"
]

def display_rows(df, title, filter_rows=False):
    print(f"\n{'=' * 90}")
    print(title)
    print(f"Dimensions : {df.shape}")
    print("=" * 90)

    for i, row in df.iterrows():
        values = [
            f"{j}:{str(v)[:65]}"
            for j, v in enumerate(row)
            if pd.notna(v) and str(v).strip()
        ]

        if not values:
            continue

        text = " ".join(values).lower()

        if filter_rows and not any(k in text for k in KEYWORDS):
            continue

        print(f"Ligne {i}: " + " | ".join(values))


patterns = [
    ("indicateurs-sectoriels-tourisme-2010-2020*", "Tourisme"),
    ("indicateurs-sectoriels-2012-2022*FR_2025*", None),
    ("indicateurs-sectoriels-2012-2022*FR.xlsx*", None),
]

for pattern, selected_sheet in patterns:
    files = list(BASE.glob(pattern))

    for file in files:
        print(f"\n\nFICHIER : {file.name}")

        try:
            xls = pd.ExcelFile(file)
            print("Feuilles :", xls.sheet_names)

            for sheet in xls.sheet_names:
                if selected_sheet and sheet != selected_sheet:
                    continue

                df = pd.read_excel(
                    file,
                    sheet_name=sheet,
                    header=None
                )

                if selected_sheet:
                    display_rows(df, sheet)
                else:
                    # En-têtes et premières lignes pour comprendre
                    # la structure générale du tableau.
                    display_rows(df.head(15), f"{sheet} - début")

                    # Toutes les lignes comportant des indicateurs
                    # liés au tourisme.
                    display_rows(
                        df,
                        f"{sheet} - lignes pertinentes",
                        filter_rows=True
                    )

        except Exception as e:
            print("ERREUR :", e)
