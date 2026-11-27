
from pathlib import Path
import pandas as pd

base = Path("outputs/audit")

files = [
    "resource_format_inventory.csv",
    "resource_sheet_inventory.csv"
]

for filename in files:
    path = base / filename

    print(f"\n{'=' * 70}")
    print(filename)
    print("=" * 70)

    if not path.exists():
        print("Fichier introuvable")
        continue

    df = pd.read_csv(path)

    print("Colonnes :", list(df.columns))
    print(df.to_string(index=False, max_rows=100))
