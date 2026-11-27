
# ============================================================
# MOROCCO-STAY
# Configuration générale du projet
# ============================================================

# IMPORTANT :
# Ne pas utiliser rm(list = ls()) ici.
# Ce fichier est appelé par app.R et ne doit pas supprimer
# les objets déjà définis dans l'environnement.

# ------------------------------------------------------------
# 1. OPTIONS GENERALES
# ------------------------------------------------------------

options(
  stringsAsFactors = FALSE,
  scipen = 999,
  OutDec = "."
)

# ------------------------------------------------------------
# 2. RACINE DU PROJET
# ------------------------------------------------------------

ROOT <- normalizePath(
  getwd(),
  winslash = "/",
  mustWork = TRUE
)

# ------------------------------------------------------------
# 3. REPERTOIRES DU PROJET
# ------------------------------------------------------------

DATA_RAW <- file.path(ROOT, "data", "raw")
DATA_PROCESSED <- file.path(ROOT, "data", "processed")

OUTPUT_AUDIT <- file.path(ROOT, "outputs", "audit")
OUTPUT_FIGURES <- file.path(ROOT, "outputs", "figures")
OUTPUT_MAPS <- file.path(ROOT, "outputs", "maps")
OUTPUT_TABLES <- file.path(ROOT, "outputs", "tables")
OUTPUT_REPORTS <- file.path(ROOT, "outputs", "reports")

# ------------------------------------------------------------
# 4. PACKAGES DU PROJET
# ------------------------------------------------------------

PACKAGES <- c(
  "tidyverse",
  "readxl",
  "janitor",
  "scales",
  "shinyWidgets",
  "thematic",
  "ggplot2",
  "sf",
  "tmap",
  "patchwork",
  "corrplot",
  "spdep",
  "leaflet"
)

# Vérification des packages disponibles
installed <- rownames(installed.packages())

missing_packages <- setdiff(
  PACKAGES,
  installed
)

if (length(missing_packages) > 0) {
  
  message("ATTENTION : packages manquants :")
  
  print(missing_packages)
  
  message(
    "Installe ces packages localement avant de lancer le projet."
  )
  
} else {
  
  message("Tous les packages principaux sont disponibles.")
  
}

# ------------------------------------------------------------
# 5. CHARGEMENT DES PACKAGES ESSENTIELS
# ------------------------------------------------------------

suppressPackageStartupMessages({
  
  library(tidyverse)
  library(janitor)
  library(readxl)
  
})

# ------------------------------------------------------------
# 6. VERIFICATION DES DONNEES
# ------------------------------------------------------------

if (!dir.exists(DATA_PROCESSED)) {
  stop(
    "Le dossier data/processed est introuvable : ",
    DATA_PROCESSED
  )
}

# Vérifier la présence des fichiers préparés
processed_files <- list.files(
  DATA_PROCESSED,
  pattern = "\\.csv$",
  full.names = TRUE
)

if (length(processed_files) == 0) {
  stop("Aucun fichier CSV trouvé dans data/processed.")
}

# ------------------------------------------------------------
# 7. MESSAGES DE CONTROLE
# ------------------------------------------------------------

message("----------------------------------------")
message("MOROCCO-STAY - CONFIGURATION")
message("----------------------------------------")

message("Racine du projet : ", ROOT)

message(
  "Nombre de fichiers CSV : ",
  length(processed_files)
)

message("Configuration du projet terminée.")
message("----------------------------------------")
