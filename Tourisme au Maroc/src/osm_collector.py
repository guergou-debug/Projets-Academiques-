
import requests
import pandas as pd
import json
import time
import logging

from datetime import datetime, timezone
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

from config import (
    CITIES,
    OVERPASS_URL,
    USER_AGENT,
    RAW_OSM,
    PROCESSED
)


# ============================================================
# 1. CONFIGURATION
# ============================================================

RAW_OSM.mkdir(parents=True, exist_ok=True)
PROCESSED.mkdir(parents=True, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s"
)

logger = logging.getLogger(__name__)

MAX_ATTEMPTS = 4
WAIT_BETWEEN_CITIES = 20

TOURISM_TYPES = [
    "hotel",
    "guest_house",
    "hostel",
    "motel",
    "apartment",
    "bed_and_breakfast",
    "resort"
]


# ============================================================
# 2. SESSION HTTP ET RETRIES
# ============================================================

session = requests.Session()

session.headers.update({
    "User-Agent": USER_AGENT
})

retry_strategy = Retry(
    total=3,
    connect=3,
    read=3,
    backoff_factor=5,
    status_forcelist=[429, 500, 502, 503, 504],
    allowed_methods=["POST"],
    respect_retry_after_header=True
)

adapter = HTTPAdapter(
    max_retries=retry_strategy,
    pool_connections=2,
    pool_maxsize=2
)

session.mount("https://", adapter)


# ============================================================
# 3. CONSTRUCTION DE LA REQUÊTE OVERPASS
# ============================================================

def build_query(bbox):

    south, west, north, east = bbox

    values = "|".join(TOURISM_TYPES)

    return f"""
    [out:json][timeout:90];

    (
      nwr["tourism"~"^({values})$"]
      ({south},{west},{north},{east});
    );

    out center tags;
    """


# ============================================================
# 4. EXTRACTION DES DONNÉES D'UNE VILLE
# ============================================================

def collect_city(city, bbox):

    query = build_query(bbox)

    response = session.post(
        OVERPASS_URL,
        data={"data": query},
        timeout=(20, 120)
    )

    response.raise_for_status()

    data = response.json()

    timestamp = datetime.now(
        timezone.utc
    ).isoformat()

    raw_file = RAW_OSM / f"{city.lower()}_raw.json"

    with open(raw_file, "w", encoding="utf-8") as file:
        json.dump(
            data,
            file,
            ensure_ascii=False,
            indent=2
        )

    records = []

    for element in data.get("elements", []):

        tags = element.get("tags", {})
        center = element.get("center", {})

        latitude = element.get(
            "lat",
            center.get("lat")
        )

        longitude = element.get(
            "lon",
            center.get("lon")
        )

        records.append({

            "osm_id": element.get("id"),

            "osm_type": element.get("type"),

            "city": city,

            "name": tags.get("name"),

            "tourism_type": tags.get("tourism"),

            "stars": tags.get("stars"),

            "rooms": tags.get("rooms"),

            "beds": tags.get("beds"),

            "latitude": latitude,

            "longitude": longitude,

            "postcode": tags.get("addr:postcode"),

            "street": tags.get("addr:street"),

            "website": tags.get("website"),

            "brand": tags.get("brand"),

            "operator": tags.get("operator"),

            "source": "OpenStreetMap",

            "retrieved_at": timestamp

        })

    return records


# ============================================================
# 5. COLLECTE AVEC GESTION DES ERREURS
# ============================================================

def collect_city_safely(city, bbox):

    for attempt in range(1, MAX_ATTEMPTS + 1):

        try:

            logger.info(
                f"{city} | Attempt {attempt}/{MAX_ATTEMPTS}"
            )

            records = collect_city(city, bbox)

            logger.info(
                f"{city} | {len(records)} objects retrieved"
            )

            return records, "SUCCESS", None

        except requests.exceptions.HTTPError as error:

            status = (
                error.response.status_code
                if error.response is not None
                else None
            )

            logger.warning(
                f"{city} | HTTP error: {error}"
            )

            if status not in [429, 500, 502, 503, 504]:
                return [], "FAILED", str(error)

        except (
            requests.exceptions.RequestException,
            ValueError
        ) as error:

            logger.warning(
                f"{city} | Connection/data error: {error}"
            )

        except Exception as error:

            logger.exception(
                f"{city} | Unexpected error"
            )

            return [], "FAILED", str(error)

        if attempt < MAX_ATTEMPTS:

            wait_time = 15 * (2 ** (attempt - 1))

            logger.info(
                f"{city} | Waiting {wait_time} seconds..."
            )

            time.sleep(wait_time)

    return [], "FAILED", "Maximum attempts reached"


# ============================================================
# 6. SAUVEGARDE ET FUSION DES DONNÉES
# ============================================================

def save_results(records):

    if not records:
        logger.warning("No new records to save.")
        return

    new_df = pd.DataFrame(records)

    csv_file = PROCESSED / "hotels_osm.csv"

    if csv_file.exists():

        old_df = pd.read_csv(csv_file)

        df = pd.concat(
            [old_df, new_df],
            ignore_index=True
        )

    else:

        df = new_df

    # Contrôle des coordonnées
    df["latitude"] = pd.to_numeric(
        df["latitude"],
        errors="coerce"
    )

    df["longitude"] = pd.to_numeric(
        df["longitude"],
        errors="coerce"
    )

    df = df.dropna(
        subset=["osm_id", "osm_type"]
    )

    df = df[
        df["latitude"].between(-90, 90)
        & df["longitude"].between(-180, 180)
    ]

    # Déduplication par identifiant OSM
    df = df.drop_duplicates(
        subset=["osm_type", "osm_id"],
        keep="last"
    )

    df.to_csv(
        csv_file,
        index=False,
        encoding="utf-8-sig"
    )

    df.to_parquet(
        PROCESSED / "hotels_osm.parquet",
        index=False
    )

    logger.info(
        f"Dataset saved: {len(df)} unique establishments"
    )


# ============================================================
# 7. RAPPORT DE COLLECTE
# ============================================================

def save_collection_report(results):

    report = pd.DataFrame(results)

    report.to_csv(
        RAW_OSM / "collection_report.csv",
        index=False,
        encoding="utf-8-sig"
    )


# ============================================================
# 8. PROGRAMME PRINCIPAL
# ============================================================

def main():

    all_records = []
    collection_results = []

    cities = list(CITIES.items())

    logger.info("Starting OpenStreetMap collection")

    for index, (city, config) in enumerate(cities):

        logger.info(f"Collecting accommodation data: {city}")

        records, status, error = collect_city_safely(
            city,
            config["bbox"]
        )

        all_records.extend(records)

        collection_results.append({

            "city": city,

            "status": status,

            "records_retrieved": len(records),

            "error": error,

            "retrieved_at": datetime.now(
                timezone.utc
            ).isoformat()

        })

        if index < len(cities) - 1:

            logger.info(
                f"Waiting {WAIT_BETWEEN_CITIES} seconds "
                "before next city"
            )

            time.sleep(WAIT_BETWEEN_CITIES)

    # Sauvegarde des résultats, même si certaines villes échouent
    save_results(all_records)

    save_collection_report(collection_results)

    report = pd.DataFrame(collection_results)

    print("\n" + "=" * 55)
    print("OPENSTREETMAP COLLECTION REPORT")
    print("=" * 55)

    print(
        report[
            ["city", "status", "records_retrieved"]
        ].to_string(index=False)
    )

    print("=" * 55)

    print(
        f"New objects collected: {len(all_records)}"
    )

    print(
        f"Successful cities: "
        f"{(report['status'] == 'SUCCESS').sum()}/{len(cities)}"
    )

    print(
        f"Failed cities: "
        f"{(report['status'] == 'FAILED').sum()}/{len(cities)}"
    )

    print("=" * 55)


if __name__ == "__ain__":
    main()
