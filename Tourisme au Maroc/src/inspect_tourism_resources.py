
from pathlib import Path
import json
import zipfile
import logging

import pandas as pd

# ---------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------

ROOT = Path(__file__).resolve().parents[1]
RAW_TOURISM = ROOT / "data" / "raw" / "tourism"
AUDIT_DIR = ROOT / "outputs" / "audit"

AUDIT_DIR.mkdir(parents=True, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(levelname)s | %(message)s"
)

# ---------------------------------------------------------
# DETECTION DU FORMAT REEL
# ---------------------------------------------------------

def detect_format(path):
    try:
        with open(path, "rb") as f:
            signature = f.read(8192)

        if signature.startswith(b"PK\x03\x04"):
            if zipfile.is_zipfile(path):
                with zipfile.ZipFile(path) as z:
                    names = z.namelist()

                if "[Content_Types].xml" in names:
                    return "xlsx"
                return "zip"

        if signature.startswith(bytes.fromhex("D0CF11E0A1B11AE1")):
            return "xls"

        if signature.startswith(b"%PDF"):
            return "pdf"

        stripped = signature.lstrip()

        if stripped.startswith((b"{", b"[")):
            return "json"

        if stripped.lower().startswith(
            (b"<!doctype html", b"<html", b"<table")
        ):
            return "html"

        if b"," in signature or b";" in signature or b"\t" in signature:
            return "text"

        return "unknown"

    except Exception as exc:
        logging.warning("%s : %s", path.name, exc)
        return "error"


# ---------------------------------------------------------
# LECTURE DES RESSOURCES
# ---------------------------------------------------------

def safe_value(value):
    if pd.isna(value):
        return None

    if hasattr(value, "isoformat"):
        return value.isoformat()

    if isinstance(value, (str, int, float, bool)):
        return value

    return str(value)


def inspect_excel(path, file_format):
    engine = "openpyxl" if file_format == "xlsx" else "xlrd"

    results = []
    samples = []

    try:
        excel = pd.ExcelFile(path, engine=engine)

        for sheet in excel.sheet_names:
            df = pd.read_excel(
                path,
                sheet_name=sheet,
                engine=engine
            )

            results.append({
                "filename": path.name,
                "format": file_format,
                "sheet": sheet,
                "rows": len(df),
                "columns": len(df.columns),
                "column_names": " | ".join(
                    str(c) for c in df.columns
                ),
                "status": "SUCCESS"
            })

            samples.append({
                "filename": path.name,
                "sheet": sheet,
                "columns": [str(c) for c in df.columns],
                "records": [
                    {
                        str(k): safe_value(v)
                        for k, v in row.items()
                    }
                    for row in df.head(8).to_dict("records")
                ]
            })

    except Exception as exc:
        results.append({
            "filename": path.name,
            "format": file_format,
            "sheet": None,
            "rows": None,
            "columns": None,
            "column_names": None,
            "status": f"ERROR: {exc}"
        })

    return results, samples


def inspect_text(path):
    try:
        df = pd.read_csv(
            path,
            sep=None,
            engine="python",
            encoding="utf-8-sig"
        )

        return {
            "filename": path.name,
            "format": "text",
            "rows": len(df),
            "columns": len(df.columns),
            "column_names": " | ".join(map(str, df.columns)),
            "status": "SUCCESS"
        }

    except Exception as exc:
        return {
            "filename": path.name,
            "format": "text",
            "rows": None,
            "columns": None,
            "column_names": None,
            "status": f"ERROR: {exc}"
        }


# ---------------------------------------------------------
# EXECUTION
# ---------------------------------------------------------

def main():

    if not RAW_TOURISM.exists():
        raise FileNotFoundError(RAW_TOURISM)

    files = sorted(
        p for p in RAW_TOURISM.rglob("*")
        if p.is_file()
    )

    inventory = []
    sheets = []
    samples = []

    logging.info("%s fichiers à inspecter", len(files))

    for path in files:

        fmt = detect_format(path)

        inventory.append({
            "filename": path.name,
            "relative_path": str(path.relative_to(ROOT)),
            "size_kb": round(path.stat().st_size / 1024, 2),
            "extension": path.suffix.lower(),
            "detected_format": fmt
        })

        logging.info("%s -> %s", path.name, fmt)

        if fmt in ("xlsx", "xls"):
            sheet_results, sheet_samples = inspect_excel(
                path, fmt
            )
            sheets.extend(sheet_results)
            samples.extend(sheet_samples)

        elif fmt == "text":
            sheets.append(inspect_text(path))

        elif fmt in ("pdf", "json", "zip", "unknown"):
            logging.info(
                "Inspection tabulaire différée : %s", path.name
            )

    pd.DataFrame(inventory).to_csv(
        AUDIT_DIR / "resource_format_inventory.csv",
        index=False,
        encoding="utf-8-sig"
    )

    pd.DataFrame(sheets).to_csv(
        AUDIT_DIR / "resource_sheet_inventory.csv",
        index=False,
        encoding="utf-8-sig"
    )

    with open(
        AUDIT_DIR / "resource_samples.json",
        "w",
        encoding="utf-8"
    ) as f:
        json.dump(
            samples,
            f,
            ensure_ascii=False,
            indent=2,
            default=str
        )

    logging.info("Inspection terminée.")
    logging.info("Résultats : %s", AUDIT_DIR)


if __name__ == "__main__":
    main()
