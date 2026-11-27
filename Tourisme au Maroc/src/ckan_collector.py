
import requests
import pandas as pd
import json
import time
import logging
import re

from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlparse
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

from config import (
    CKAN_API,
    USER_AGENT,
    AUDIT,
    RAW_TOURISM
)


# ============================================================
# 1. CONFIGURATION
# ============================================================

AUDIT.mkdir(parents=True, exist_ok=True)
RAW_TOURISM.mkdir(parents=True, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s"
)

logger = logging.getLogger(__name__)

ROWS_PER_PAGE = 100
MAX_PAGES = 5
WAIT_BETWEEN_DATASETS = 1

SUPPORTED_FORMATS = {
    "csv": "csv",
    "xls": "xls",
    "xlsx": "xlsx"
}

# Licences ouvertes reconnues.
# Les licences inconnues restent dans l'inventaire,
# mais leurs fichiers ne sont pas téléchargés automatiquement.
OPEN_LICENSES = {
    "odc-odbl",
    "odc-pddl",
    "odc-by",
    "cc-by",
    "cc-by-sa",
    "cc0",
    "cc-zero",
    "public-domain"
}


# ============================================================
# 2. SESSION HTTP ET GESTION DES ERREURS
# ============================================================

session = requests.Session()

session.headers.update({
    "User-Agent": USER_AGENT
})

retry_strategy = Retry(
    total=5,
    connect=5,
    read=5,
    backoff_factor=2,
    status_forcelist=[
        429,
        500,
        502,
        503,
        504
    ],
    allowed_methods=["GET"],
    respect_retry_after_header=True
)

adapter = HTTPAdapter(
    max_retries=retry_strategy,
    pool_connections=5,
    pool_maxsize=5
)

session.mount("https://", adapter)
session.mount("http://", adapter)


# ============================================================
# 3. FONCTIONS UTILITAIRES
# ============================================================

def current_timestamp():

    return datetime.now(
        timezone.utc
    ).isoformat()


def normalize_text(value):

    if value is None:
        return ""

    return str(value).strip().lower()


def safe_filename(value):

    value = str(value or "resource")

    value = re.sub(
        r"[^\w.-]+",
        "_",
        value,
        flags=re.UNICODE
    )

    return value.strip("._")[:100]


def normalize_license(license_id):

    return normalize_text(license_id)


def is_open_license(license_id):

    return normalize_license(
        license_id
    ) in OPEN_LICENSES


# ============================================================
# 4. ACTION CKAN
# ============================================================

def ckan_action(action, params=None):

    url = f"{CKAN_API.rstrip('/')}/{action}"

    response = session.get(
        url,
        params=params or {},
        timeout=(20, 90)
    )

    response.raise_for_status()

    result = response.json()

    if not result.get("success"):

        raise RuntimeError(
            f"CKAN API error for {action}: {result}"
        )

    return result["result"]


# ============================================================
# 5. RECHERCHE DES DATASETS TOURISTIQUES
# ============================================================

def discover_tourism_datasets():

    queries = [
        "tourisme",
        "tourism",
        "capacité hôtelière",
        "nuitées",
        "arrivées touristiques",
        "recettes touristiques",
        "établissements hébergement touristique",
        "hébergement touristique",
        "établissements hôteliers",
        "indicateurs tourisme"
    ]

    packages = {}

    logger.info("Starting CKAN dataset discovery")

    for query in queries:

        logger.info(f"Searching: {query}")

        try:

            for page in range(MAX_PAGES):

                result = ckan_action(
                    "package_search",
                    {
                        "q": query,
                        "rows": ROWS_PER_PAGE,
                        "start": page * ROWS_PER_PAGE
                    }
                )

                datasets = result.get(
                    "results",
                    []
                )

                if not datasets:
                    break

                for dataset in datasets:

                    dataset_id = dataset.get("id")

                    if dataset_id:
                        packages[dataset_id] = dataset

                total = result.get("count", 0)

                if (page + 1) * ROWS_PER_PAGE >= total:
                    break

        except Exception as error:

            logger.error(
                f"Search failed for '{query}': {error}"
            )

        # Petite pause entre les recherches
        time.sleep(1)

    logger.info(
        f"Datasets discovered: {len(packages)}"
    )

    return list(packages.values())


# ============================================================
# 6. INVENTAIRE DES RESSOURCES
# ============================================================

def build_resource_inventory(packages):

    records = []

    dataset_errors = []

    for index, package in enumerate(packages, start=1):

        dataset_id = package.get("id")

        logger.info(
            f"Inspecting dataset {index}/{len(packages)}: "
            f"{package.get('title')}"
        )

        try:

            details = ckan_action(
                "package_show",
                {"id": dataset_id}
            )

            license_id = (
                details.get("license_id")
                or package.get("license_id")
            )

            for resource in details.get(
                "resources",
                []
            ):

                records.append({

                    "dataset_id": details.get("id"),

                    "dataset_name": details.get("name"),

                    "dataset_title": details.get("title"),

                    "dataset_notes": details.get("notes"),

                    "organization": (
                        details.get("organization") or {}
                    ).get("title"),

                    "license_id": license_id,

                    "license_title": details.get(
                        "license_title"
                    ),

                    "resource_id": resource.get("id"),

                    "resource_name": resource.get("name"),

                    "description": resource.get(
                        "description"
                    ),

                    "format": resource.get("format"),

                    "url": resource.get("url"),

                    "last_modified": resource.get(
                        "last_modified"
                    ),

                    "created": resource.get("created"),

                    "retrieved_at": current_timestamp()

                })

        except Exception as error:

            logger.error(
                f"Dataset details unavailable: {dataset_id} | {error}"
            )

            dataset_errors.append({

                "dataset_id": dataset_id,

                "dataset_title": package.get("title"),

                "error": str(error),

                "retrieved_at": current_timestamp()

            })

        time.sleep(WAIT_BETWEEN_DATASETS)

    inventory = pd.DataFrame(records)

    if dataset_errors:

        pd.DataFrame(dataset_errors).to_csv(
            AUDIT / "ckan_dataset_errors.csv",
            index=False,
            encoding="utf-8-sig"
        )

    return inventory


# ============================================================
# 7. TÉLÉCHARGEMENT DES RESSOURCES
# ============================================================

def download_resource(row):

    resource_id = str(row["resource_id"])

    resource_name = safe_filename(
        row["resource_name"]
    )

    dataset_name = safe_filename(
        row["dataset_name"]
    )

    fmt = normalize_text(row["format"])

    license_id = normalize_license(
        row["license_id"]
    )

    url = row["url"]

    # Vérification du format
    if fmt not in SUPPORTED_FORMATS:

        return "SKIPPED_FORMAT", None

    # Vérification de la licence
    if license_id not in OPEN_LICENSES:

        return "SKIPPED_LICENSE", None

    # Vérification de l'URL
    if not isinstance(url, str):

        return "INVALID_URL", None

    parsed_url = urlparse(url)

    if parsed_url.scheme not in {"http", "https"}:

        return "INVALID_URL", None

    if not parsed_url.netloc:

        return "INVALID_URL", None

    extension = SUPPORTED_FORMATS[fmt]

    filename = (
        f"{dataset_name}_{resource_name}_"
        f"{resource_id}.{extension}"
    )

    filename = safe_filename(filename)

    destination = RAW_TOURISM / filename

    # Ne pas télécharger une ressource déjà présente
    if destination.exists() and destination.stat().st_size > 0:

        return "ALREADY_EXISTS", str(destination)

    try:

        response = session.get(
            url,
            timeout=(20, 120),
            stream=True
        )

        response.raise_for_status()

        temporary_path = destination.with_suffix(
            destination.suffix + ".part"
        )

        total_bytes = 0

        with open(temporary_path, "wb") as file:

            for chunk in response.iter_content(
                chunk_size=1024 * 1024
            ):

                if chunk:

                    file.write(chunk)

                    total_bytes += len(chunk)

        if total_bytes == 0:

            temporary_path.unlink(
                missing_ok=True
            )

            return "EMPTY_FILE", None

        temporary_path.replace(destination)

        logger.info(
            f"Downloaded: {filename} ({total_bytes} bytes)"
        )

        return "DOWNLOADED", str(destination)

    except Exception as error:

        logger.error(
            f"Download failed: {resource_id} | {error}"
        )

        return f"FAILED: {error}", None


# ============================================================
# 8. TRAITEMENT DE TOUTES LES RESSOURCES
# ============================================================

def download_open_resources(inventory):

    if inventory.empty:

        logger.warning("No resources available.")

        return pd.DataFrame()

    results = []

    logger.info(
        f"Starting download of {len(inventory)} resources"
    )

    for index, row in inventory.iterrows():

        logger.info(
            f"Resource {index + 1}/{len(inventory)}: "
            f"{row['resource_name']}"
        )

        status, local_path = download_resource(row)

        results.append({

            "resource_id": row["resource_id"],

            "dataset_title": row["dataset_title"],

            "resource_name": row["resource_name"],

            "format": row["format"],

            "license_id": row["license_id"],

            "status": status,

            "local_path": local_path,

            "retrieved_at": current_timestamp()

        })

        time.sleep(1)

    return pd.DataFrame(results)


# ============================================================
# 9. SAUVEGARDE DES INVENTAIRES ET RAPPORTS
# ============================================================

def save_audit_files(packages, inventory, download_report):

    # Inventaire des datasets
    with open(
        AUDIT / "ckan_datasets.json",
        "w",
        encoding="utf-8"
    ) as file:

        json.dump(
            packages,
            file,
            ensure_ascii=False,
            indent=2
        )

    # Inventaire des ressources
    inventory.to_csv(
        AUDIT / "ckan_resource_inventory.csv",
        index=False,
        encoding="utf-8-sig"
    )

    # Rapport des téléchargements
    if not download_report.empty:

        download_report.to_csv(
            AUDIT / "ckan_download_report.csv",
            index=False,
            encoding="utf-8-sig"
        )


# ============================================================
# 10. PROGRAMME PRINCIPAL
# ============================================================

def main():

    print("\n" + "=" * 60)
    print("MOROCCO-STAY | OPEN DATA COLLECTION")
    print("=" * 60)

    # Étape 1 : découverte
    packages = discover_tourism_datasets()

    print(
        f"\nDatasets identified: {len(packages)}"
    )

    if not packages:

        logger.error("No datasets discovered.")

        return

    # Étape 2 : inventaire
    inventory = build_resource_inventory(packages)

    print(
        f"Resources identified: {len(inventory)}"
    )

    # Sauvegarde immédiate de l'inventaire
    inventory.to_csv(
        AUDIT / "ckan_resource_inventory.csv",
        index=False,
        encoding="utf-8-sig"
    )

    # Étape 3 : téléchargement
    download_report = download_open_resources(
        inventory
    )

    # Étape 4 : sauvegarde des audits
    save_audit_files(
        packages,
        inventory,
        download_report
    )

    # Étape 5 : bilan
    print("\n" + "=" * 60)
    print("OPEN DATA COLLECTION REPORT")
    print("=" * 60)

    if not download_report.empty:

        print(
            download_report["status"]
            .value_counts()
            .to_string()
        )

        successful = download_report[
            "status"
        ].isin([
            "DOWNLOADED",
            "ALREADY_EXISTS"
        ]).sum()

        print(
            f"\nSuccessfully available: {successful}"
        )

        print(
            f"Total resources: {len(download_report)}"
        )

    print(
        f"\nDatasets identified: {len(packages)}"
    )

    print(
        f"Resources identified: {len(inventory)}"
    )

    print(
        f"Tourism data directory: {RAW_TOURISM}"
    )

    print("=" * 60)


if __name__ == "__main__":
    main()
