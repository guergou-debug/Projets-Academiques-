
import json
import logging
from pathlib import Path
from datetime import datetime, timezone

import pandas as pd

from config import RAW_TOURISM, RAW_OSM, PROCESSED, AUDIT


# ============================================================
# 1. CONFIGURATION
# ============================================================

AUDIT.mkdir(parents=True, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s"
)

logger = logging.getLogger(__name__)

SUPPORTED_FILES = {".csv", ".xls", ".xlsx", ".parquet"}

timestamp = datetime.now(timezone.utc).isoformat()


# ============================================================
# 2. OUTILS
# ============================================================

def json_safe(value):

    if pd.isna(value):
        return None

    if hasattr(value, "isoformat"):
        return value.isoformat()

    return str(value)


def load_csv(path):

    # Détection automatique du séparateur
    try:
        return pd.read_csv(
            path,
            sep=None,
            engine="python",
            encoding="utf-8-sig"
        )
    except UnicodeDecodeError:
        return pd.read_csv(
            path,
            sep=None,
            engine="python",
            encoding="latin-1"
        )


def load_table(path):

    suffix = path.suffix.lower()

    if suffix == ".csv":
        return load_csv(path)

    if suffix in {".xls", ".xlsx"}:
        return pd.read_excel(path)

    if suffix == ".parquet":
        return pd.read_parquet(path)

    raise ValueError(f"Unsupported format: {suffix}")


# ============================================================
# 3. INVENTAIRE DES FICHIERS
# ============================================================

def inventory_files():

    records = []

    folders = {
        "tourism": RAW_TOURISM,
        "osm_raw": RAW_OSM,
        "processed": PROCESSED
    }

    for source, folder in folders.items():

        if not folder.exists():
            continue

        for path in folder.rglob("*"):

            if not path.is_file():
                continue

            records.append({

                "source": source,
                "filename": path.name,
                "extension": path.suffix.lower(),
                "relative_path": str(path),
                "size_kb": round(path.stat().st_size / 1024, 2),
                "modified_at": datetime.fromtimestamp(
                    path.stat().st_mtime,
                    timezone.utc
                ).isoformat(),
                "audit_status": (
                    "TO_INSPECT"
                    if path.suffix.lower() in SUPPORTED_FILES
                    else "NON_STRUCTURED_OR_UNSUPPORTED"
                )

            })

    return pd.DataFrame(records)


# ============================================================
# 4. PROFILAGE DES VARIABLES
# ============================================================

def profile_dataframe(df, filename, sheet_name, source):

    variables = []

    for column in df.columns:

        series = df[column]

        non_null = int(series.notna().sum())
        missing = int(series.isna().sum())

        examples = (
            series.dropna()
            .astype(str)
            .head(5)
            .tolist()
        )

        variables.append({

            "source": source,
            "filename": filename,
            "sheet": sheet_name,
            "variable": str(column),
            "dtype": str(series.dtype),
            "rows": len(df),
            "non_null": non_null,
            "missing": missing,
            "missing_pct": round(
                missing / len(df) * 100, 2
            ) if len(df) else None,
            "unique_values": int(series.nunique()),
            "examples": " | ".join(examples)

        })

    return variables


# ============================================================
# 5. INSPECTION DES FICHIERS
# ============================================================

def inspect_files(file_inventory):

    sheet_records = []
    variable_records = []
    samples = []

    for _, file_row in file_inventory.iterrows():

        path = Path(file_row["relative_path"])
        extension = path.suffix.lower()
        source = file_row["source"]

        if extension not in SUPPORTED_FILES:
            continue

        logger.info(f"Inspecting {path.name}")

        try:

            # Excel : examiner toutes les feuilles
            if extension in {".xls", ".xlsx"}:

                excel = pd.ExcelFile(path)

                for sheet in excel.sheet_names:

                    df = pd.read_excel(
                        path,
                        sheet_name=sheet
                    )

                    sheet_records.append({

                        "source": source,
                        "filename": path.name,
                        "sheet": sheet,
                        "rows": len(df),
                        "columns": len(df.columns),
                        "column_names": " | ".join(
                            map(str, df.columns)
                        ),
                        "status": "SUCCESS"

                    })

                    variable_records.extend(
                        profile_dataframe(
                            df,
                            path.name,
                            sheet,
                            source
                        )
                    )

                    samples.append({

                        "source": source,
                        "filename": path.name,
                        "sheet": sheet,
                        "columns": list(map(str, df.columns)),
                        "records": df.head(5).to_dict(
                            orient="records"
                        )

                    })

            # CSV et Parquet
            else:

                df = load_table(path)

                sheet_records.append({

                    "source": source,
                    "filename": path.name,
                    "sheet": "TABLE",
                    "rows": len(df),
                    "columns": len(df.columns),
                    "column_names": " | ".join(
                        map(str, df.columns)
                    ),
                    "status": "SUCCESS"

                })

                variable_records.extend(
                    profile_dataframe(
                        df,
                        path.name,
                        "TABLE",
                        source
                    )
                )

                samples.append({

                    "source": source,
                    "filename": path.name,
                    "sheet": "TABLE",
                    "columns": list(map(str, df.columns)),
                    "records": df.head(5).to_dict(
                        orient="records"
                    )

                })

        except Exception as error:

            logger.exception(
                f"Could not inspect {path.name}"
            )

            sheet_records.append({

                "source": source,
                "filename": path.name,
                "sheet": None,
                "rows": None,
                "columns": None,
                "column_names": None,
                "status": f"ERROR: {error}"

            })

    return (
        pd.DataFrame(sheet_records),
        pd.DataFrame(variable_records),
        samples
    )


# ============================================================
# 6. AUDIT SPÉCIFIQUE DE LA BASE OSM
# ============================================================

def audit_osm():

    csv_path = PROCESSED / "hotels_osm.csv"
    parquet_path = PROCESSED / "hotels_osm.parquet"

    if parquet_path.exists():
        df = pd.read_parquet(parquet_path)
    elif csv_path.exists():
        df = pd.read_csv(csv_path)
    else:
        logger.warning("OSM dataset not found.")
        return

    # Résumé par ville
    if "city" in df.columns:

        city_summary = (
            df.groupby("city")
            .agg(
                establishments=("osm_id", "count"),
                unique_names=("name", "nunique"),
                missing_names=(
                    "name",
                    lambda x: x.isna().sum()
                )
            )
            .reset_index()
        )

        city_summary.to_csv(
            AUDIT / "osm_city_summary.csv",
            index=False,
            encoding="utf-8-sig"
        )

    # Résumé par type d'hébergement
    if "tourism_type" in df.columns:

        type_summary = (
            df.groupby(
                ["city", "tourism_type"],
                dropna=False
            )
            .size()
            .reset_index(name="count")
        )

        type_summary.to_csv(
            AUDIT / "osm_type_summary.csv",
            index=False,
            encoding="utf-8-sig"
        )

    # Qualité générale
    quality = []

    for column in df.columns:

        quality.append({

            "variable": column,
            "dtype": str(df[column].dtype),
            "missing": int(df[column].isna().sum()),
            "missing_pct": round(
                df[column].isna().mean() * 100, 2
            ),
            "unique": int(df[column].nunique())

        })

    pd.DataFrame(quality).to_csv(
        AUDIT / "osm_quality.csv",
        index=False,
        encoding="utf-8-sig"
    )

    # Contrôle des doublons
    duplicate_count = df.duplicated(
        subset=["osm_type", "osm_id"]
    ).sum()

    # Contrôle géographique
    invalid_coordinates = 0

    if {"latitude", "longitude"}.issubset(df.columns):

        lat = pd.to_numeric(
            df["latitude"],
            errors="coerce"
        )

        lon = pd.to_numeric(
            df["longitude"],
            errors="coerce"
        )

        invalid_coordinates = int(
            (
                lat.isna()
                | lon.isna()
                | ~lat.between(-90, 90)
                | ~lon.between(-180, 180)
            ).sum()
        )

    summary = {

        "observations": len(df),

        "unique_osm_ids": int(
            df[["osm_type", "osm_id"]]
            .drop_duplicates()
            .shape[0]
        ),

        "duplicate_osm_ids": int(duplicate_count),

        "invalid_coordinates": invalid_coordinates,

        "cities": (
            df["city"].nunique()
            if "city" in df.columns
            else None
        ),

        "retrieved_at": timestamp

    }

    with open(
        AUDIT / "osm_global_quality.json",
        "w",
        encoding="utf-8"
    ) as file:

        json.dump(
            summary,
            file,
            ensure_ascii=False,
            indent=2
        )

    logger.info(f"OSM audit: {summary}")


# ============================================================
# 7. PROGRAMME PRINCIPAL
# ============================================================

def main():

    print("\n" + "=" * 60)
    print("MOROCCO-STAY | DATA AUDIT")
    print("=" * 60)

    # 1. Inventaire
    files = inventory_files()

    files.to_csv(
        AUDIT / "file_inventory.csv",
        index=False,
        encoding="utf-8-sig"
    )

    # 2. Inspection
    sheets, variables, samples = inspect_files(files)

    sheets.to_csv(
        AUDIT / "sheet_inventory.csv",
        index=False,
        encoding="utf-8-sig"
    )

    variables.to_csv(
        AUDIT / "variable_dictionary.csv",
        index=False,
        encoding="utf-8-sig"
    )

    with open(
        AUDIT / "data_samples.json",
        "w",
        encoding="utf-8"
    ) as file:

        json.dump(
            samples,
            file,
            ensure_ascii=False,
            indent=2,
            default=json_safe
        )

    # 3. Audit OSM
    audit_osm()

    # 4. Bilan
    print("\n" + "=" * 60)
    print("DATA AUDIT COMPLETED")
    print("=" * 60)

    print(f"Files identified: {len(files)}")
    print(f"Sheets/tables inspected: {len(sheets)}")
    print(f"Variables profiled: {len(variables)}")

    if not sheets.empty:

        print("\nInspection status:")

        print(
            sheets["status"]
            .value_counts()
            .to_string()
        )

    print(f"\nAudit directory: {AUDIT}")
    print("=" * 60)


if __name__ == "__main__":
    main()
