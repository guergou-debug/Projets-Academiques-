
# ============================================================
# MOROCCO-STAY | SHINY
# ETAPE 2 : AUDIT DES TABLES POUR L'APPLICATION
# ============================================================

library(tidyverse)
library(janitor)

# 1. Fichiers à connecter à l'application ---------------------

data_files <- c(
  destination = "tourism_destination.csv",
  capacity_destination = "capacity_destination.csv",
  capacity_category = "capacity_category.csv",
  panel_destination = "panel_destination.csv",
  market_indicators = "market_indicators_corrected.csv",
  cagr = "cagr_indicators.csv",
  hhi = "hhi_indicators.csv",
  market_aggregates = "market_aggregate_shares.csv",
  international_markets = "international_markets_2019.csv",
  covid_destination = "covid_destination_impact.csv",
  covid_markets = "covid_market_impact.csv",
  osm = "osm_accommodation.csv"
)

# 2. Importation ----------------------------------------------

data_tables <- lapply(data_files, function(filename) {
  path <- file.path("data/processed", filename)
  
  if (!file.exists(path)) {
    stop(paste("Fichier introuvable :", path))
  }
  
  read_csv(path, show_col_types = FALSE)
})

names(data_tables) <- names(data_files)

# 3. Audit des dimensions -------------------------------------

cat("\n========================================\n")
cat(" AUDIT DES TABLES SHINY\n")
cat("========================================\n")

dimensions <- map_dfr(names(data_tables), function(nm) {
  tibble(
    table = nm,
    rows = nrow(data_tables[[nm]]),
    columns = ncol(data_tables[[nm]])
  )
})

cat("\n--- A. DIMENSIONS ---\n")
print(dimensions, n = Inf)

# 4. Noms des colonnes ----------------------------------------

cat("\n--- B. NOMS DES VARIABLES ---\n")

for (nm in names(data_tables)) {
  cat("\nTABLE :", nm, "\n")
  print(names(data_tables[[nm]]))
}

# 5. Types des variables --------------------------------------

cat("\n--- C. TYPES DES VARIABLES ---\n")

for (nm in names(data_tables)) {
  cat("\nTABLE :", nm, "\n")
  print(
    tibble(
      variable = names(data_tables[[nm]]),
      type = map_chr(data_tables[[nm]], ~ class(.x)[1])
    )
  )
}

# 6. Aperçu des principales tables ----------------------------

tables_to_preview <- c(
  "panel_destination",
  "market_indicators",
  "cagr",
  "hhi",
  "market_aggregates",
  "international_markets",
  "covid_destination",
  "covid_markets"
)

cat("\n--- D. APERCU DES TABLES ANALYTIQUES ---\n")

for (nm in tables_to_preview) {
  cat("\nTABLE :", nm, "\n")
  print(head(data_tables[[nm]], 3))
}

# 7. Vérification des valeurs manquantes ----------------------

cat("\n--- E. VALEURS MANQUANTES ---\n")

missing_report <- map_dfr(names(data_tables), function(nm) {
  tibble(
    table = nm,
    missing_values = sum(is.na(data_tables[[nm]])),
    missing_percent = round(
      100 * mean(is.na(data_tables[[nm]])), 2
    )
  )
})

print(missing_report, n = Inf)

# 8. Export des audits ----------------------------------------

write_csv(
  dimensions,
  "outputs/audit/shiny_table_dimensions.csv"
)

write_csv(
  missing_report,
  "outputs/audit/shiny_missing_values.csv"
)

cat("\n========================================\n")
cat(" AUDIT SHINY TERMINE\n")
cat("========================================\n")
