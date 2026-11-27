
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

CITIES = {
    "Marrakech": {
        "bbox": [31.50, -8.10, 31.75, -7.85]
    },
    "Casablanca": {
        "bbox": [33.45, -7.75, 33.70, -7.45]
    },
    "Agadir": {
        "bbox": [30.30, -9.75, 30.55, -9.45]
    },
    "Tanger": {
        "bbox": [35.65, -5.95, 35.85, -5.70]
    }
}

CKAN_API = (
    "https://www.data.gov.ma/data/api/3/action"
)

OVERPASS_URL = "https://overpass-api.de/api/interpreter"

USER_AGENT = (
    "MoroccoStayResearch/1.0 "
    "(academic economic research; contact: asamahgagara@gmail.com)"
)

RAW_OSM = ROOT / "data/raw/osm"
RAW_TOURISM = ROOT / "data/raw/tourism"
PROCESSED = ROOT / "data/processed"
AUDIT = ROOT / "outputs/audit"

for path in [RAW_OSM, RAW_TOURISM, PROCESSED, AUDIT]:
    path.mkdir(parents=True, exist_ok=True)
