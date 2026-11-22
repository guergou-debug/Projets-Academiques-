import requests
import pandas as pd

COUNTRY = "NER"
START_YEAR = 2000
END_YEAR = 2025

INDICATORS = {
    "gdp_real": "NY.GDP.MKTP.KN",
    "gdp_growth": "NY.GDP.MKTP.KD.ZG",
    "population": "SP.POP.TOTL",
    "gdp_pc_real": "NY.GDP.PCAP.KD"
}


def get_wdi_indicator(indicator_code, variable_name):

    url = (
        f"https://api.worldbank.org/v2/country/{COUNTRY}/indicator/"
        f"{indicator_code}"
        f"?format=json&per_page=100"
    )

    response = requests.get(url, timeout=30)
    response.raise_for_status()

    data = response.json()[1]

    df = pd.DataFrame(data)

    df["year"] = pd.to_numeric(df["date"], errors="coerce")
    df[variable_name] = pd.to_numeric(df["value"], errors="coerce")

    df = df[["year", variable_name]]

    return df


# --------------------------------------------------
# Extraction
# --------------------------------------------------

wdi = pd.DataFrame({
    "year": range(START_YEAR, END_YEAR + 1)
})

for variable_name, indicator_code in INDICATORS.items():

    print(f"Extraction : {variable_name} ({indicator_code})")

    df = get_wdi_indicator(
        indicator_code,
        variable_name
    )

    wdi = wdi.merge(
        df,
        on="year",
        how="left"
    )


# --------------------------------------------------
# Nettoyage
# --------------------------------------------------

wdi = wdi.sort_values("year").reset_index(drop=True)

# Vérification de la période
wdi = wdi[
    (wdi["year"] >= START_YEAR) &
    (wdi["year"] <= END_YEAR)
]


# --------------------------------------------------
# Contrôles
# --------------------------------------------------

print("\n===== STRUCTURE =====")
print(wdi.info())

print("\n===== DONNÉES =====")
print(wdi)

print("\n===== VALEURS MANQUANTES =====")
print(wdi.isna().sum())


# --------------------------------------------------
# Sauvegarde
# --------------------------------------------------

output_path = "data/raw/wdi/wdi_niger_2000_2025.csv"

wdi.to_csv(
    output_path,
    index=False,
    encoding="utf-8"
)

print(f"\nFichier sauvegardé : {output_path}")
