
from pathlib import Path
import pandas as pd

BASE = Path("data/raw/tourism")

patterns = {
    "NUITEES_PAR_DESTINATION":
        "evolution-nuitees-realisees*",
    "CAPACITE_PAR_DESTINATION":
        "evolution-par-destination-de-la-capacite*",
    "CAPACITE_PAR_CATEGORIE":
        "evolution-par-categorie-de-la-capacite*",
}

for label, pattern in patterns.items():
    files = list(BASE.glob(pattern))

    print(f"\n{'=' * 80}")
    print(label)
    print("=" * 80)

    if not files:
        print("Fichier introuvable")
        continue

    df = pd.read_excel(files[0], sheet_name=0)

    print("Dimensions :", df.shape)
    print(df.to_string(index=False))
