# ============================================================
# 08 - VISUALISATIONS : PREPARATION
# ============================================================

library(tidyverse)
library(scales)

# Vérification des objets
required_objects <- c(
  "tourism_destination",
  "panel_destination",
  "market_indicators_corrected",
  "cagr_indicators",
  "hhi_indicators",
  "market_aggregates",
  "international_markets",
  "covid_destination",
  "covid_markets",
  "covid_international"
)

missing_objects <- required_objects[
  !vapply(required_objects, exists, logical(1))
]

cat("\n--- OBJETS MANQUANTS ---\n")
print(missing_objects)

cat("\n--- DIMENSIONS DES DONNEES ---\n")

print(dim(tourism_destination))
print(dim(panel_destination))
print(dim(market_indicators_corrected))
print(dim(cagr_indicators))
print(dim(hhi_indicators))

cat("\nPREPARATION DES VISUALISATIONS TERMINEE.\n")