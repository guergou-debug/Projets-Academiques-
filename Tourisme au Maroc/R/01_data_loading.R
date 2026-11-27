

# ============================================================
# MOROCCO-STAY — CHARGEMENT CENTRALISE DES DONNEES
# Fichier : R/01_data_loading.R
# ============================================================

library(tidyverse)
library(janitor)

load_morocco_data <- function(data_dir = "data/processed") {
  
  # ----------------------------------------------------------
  # 1. INVENTAIRE DES FICHIERS
  # ----------------------------------------------------------
  
  files <- c(
    destination = "tourism_destination.csv",
    capacity_destination = "capacity_destination.csv",
    capacity_category = "capacity_category.csv",
    panel_destination = "panel_destination.csv",
    market_indicators = "market_indicators_corrected.csv",
    cagr = "cagr_indicators.csv",
    hhi = "hhi_indicators.csv",
    market_aggregates = "market_aggregate_shares.csv",
    international_markets = "international_markets_2019.csv",
    
    # Analyse Covid-19
    covid_destination = "covid_destination_impact.csv",
    covid_markets = "covid_market_impact.csv",
    covid_aggregate = "covid_aggregate_comparison.csv",
    covid_international_markets = "covid_international_markets.csv",
    
    # Données géographiques
    osm = "osm_accommodation.csv",
    
    # Arrivées touristiques
    arrivals_nationality = "arrivals_nationality.csv",
    arrivals_entry_point = "arrivals_entry_point.csv"
  )
  
  
  # ----------------------------------------------------------
  # 2. VERIFICATION DES FICHIERS
  # ----------------------------------------------------------
  
  missing_files <- files[
    !file.exists(file.path(data_dir, files))
  ]
  
  if (length(missing_files) > 0) {
    
    stop(
      "Fichiers de données manquants : ",
      paste(missing_files, collapse = ", ")
    )
  }
  
  
  # ----------------------------------------------------------
  # 3. IMPORTATION DES DONNEES
  # ----------------------------------------------------------
  
  data <- lapply(files, function(filename) {
    
    readr::read_csv(
      file.path(data_dir, filename),
      show_col_types = FALSE,
      progress = FALSE
    )
    
  })
  
  names(data) <- names(files)
  
  
  # ----------------------------------------------------------
  # 4. CONTROLES DES COLONNES INDISPENSABLES
  # ----------------------------------------------------------
  
  required_columns <- list(
    
    panel_destination = c(
      "year",
      "destination",
      "destination_nights",
      "capacity_beds",
      "capacity_pressure_proxy"
    ),
    
    hhi = c(
      "year",
      "hhi_demand",
      "hhi_supply"
    ),
    
    market_aggregates = c(
      "year",
      "dimension_label",
      "value",
      "market_share"
    ),
    
    covid_destination = c(
      "destination",
      "destination_nights_2019",
      "destination_nights_2020",
      "capacity_beds_2019",
      "capacity_beds_2020",
      "nights_change_pct",
      "capacity_change_pct"
    ),
    
    covid_markets = c(
      "dimension_label",
      "nights_2019",
      "nights_2020",
      "change_absolute",
      "change_pct"
    ),
    
    covid_aggregate = c(
      "destinations",
      "nights_2019",
      "nights_2020",
      "beds_2019",
      "beds_2020",
      "nights_change_pct",
      "capacity_change_pct",
      "pressure_2019",
      "pressure_2020"
    ),
    
    covid_international_markets = c(
      "dimension_label",
      "nights_2019",
      "nights_2020",
      "change_absolute",
      "change_pct"
    )
  )
  
  
  for (table_name in names(required_columns)) {
    
    absent <- setdiff(
      required_columns[[table_name]],
      names(data[[table_name]])
    )
    
    if (length(absent) > 0) {
      
      stop(
        "Colonnes manquantes dans ",
        table_name,
        " : ",
        paste(absent, collapse = ", ")
      )
    }
  }
  
  
  # ----------------------------------------------------------
  # 5. CONVERSION EXPLICITE DES ANNEES
  # ----------------------------------------------------------
  
  data <- lapply(data, function(x) {
    
    if ("year" %in% names(x)) {
      x <- x %>%
        mutate(year = as.integer(year))
    }
    
    x
    
  })
  
  
  # ----------------------------------------------------------
  # 6. CONTROLE DES DIMENSIONS
  # ----------------------------------------------------------
  
  message("\n--- MOROCCO-STAY : CONTROLE DU CHARGEMENT ---")
  
  for (table_name in names(data)) {
    
    message(
      table_name,
      " : ",
      nrow(data[[table_name]]),
      " lignes × ",
      ncol(data[[table_name]]),
      " colonnes"
    )
  }
  
  message("\nChargement des données MOROCCO-STAY terminé.")
  
  
  # ----------------------------------------------------------
  # 7. RETOUR DES DONNEES
  # ----------------------------------------------------------
  
  return(data)
}
