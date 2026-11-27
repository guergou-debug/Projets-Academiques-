
# ============================================================
# MOROCCO-STAY
# Audit initial des données touristiques
# ============================================================

source("R/00_setup.R")

# Première table à auditer
file <- file.path(
  DATA_PROCESSED,
  "tourism_destination.csv"
)

if (!file.exists(file)) {
  stop("Fichier introuvable : ", file)
}

tourism_destination <- readr::read_csv(
  file,
  show_col_types = FALSE
)

# Dimensions
cat("\n--- DIMENSIONS ---\n")
print(dim(tourism_destination))

# Noms des variables
cat("\n--- VARIABLES ---\n")
print(names(tourism_destination))

# Aperçu
cat("\n--- APERÇU ---\n")
print(head(tourism_destination, 10))

# Structure
cat("\n--- STRUCTURE ---\n")
glimpse(tourism_destination)

# Valeurs manquantes
cat("\n--- VALEURS MANQUANTES ---\n")

missing_report <- tibble(
  variable = names(tourism_destination),
  missing_n = colSums(is.na(tourism_destination)),
  missing_pct = round(
    colMeans(is.na(tourism_destination)) * 100,
    2
  )
)

print(missing_report)

# Modalités des variables
cat("\n--- RÉSUMÉ ---\n")
print(summary(tourism_destination))


# ============================================================
# 2. AUDIT APPROFONDI : TOURISM_DESTINATION
# ============================================================

cat("\n========================================\n")
cat("AUDIT APPROFONDI : NUITÉES PAR DESTINATION\n")
cat("========================================\n")


# ------------------------------------------------------------
# A. Vérification des années
# ------------------------------------------------------------

cat("\n--- A. ANNÉES DISPONIBLES ---\n")

print(
  sort(unique(tourism_destination$year))
)

cat("\nNombre d'années : ",
    n_distinct(tourism_destination$year), "\n")


# ------------------------------------------------------------
# B. Vérification des destinations
# ------------------------------------------------------------

cat("\n--- B. DESTINATIONS ---\n")

destinations <- tourism_destination %>%
  distinct(dimension_key, dimension_label) %>%
  arrange(dimension_label)

print(destinations)

cat("\nNombre de destinations : ",
    nrow(destinations), "\n")


# ------------------------------------------------------------
# C. Recherche de doublons
# ------------------------------------------------------------

cat("\n--- C. DOUBLONS ---\n")

duplicates <- tourism_destination %>%
  count(year, dimension_key) %>%
  filter(n > 1)

print(duplicates)

if (nrow(duplicates) == 0) {
  cat("Aucun doublon année-destination.\n")
}


# ------------------------------------------------------------
# D. Vérification de la complétude du panel
# ------------------------------------------------------------

cat("\n--- D. COMPLÉTUDE DU PANEL ---\n")

panel_completeness <- tourism_destination %>%
  count(dimension_key, name = "n_years") %>%
  arrange(n_years)

print(panel_completeness)

cat(
  "\nNombre de couples année-destination attendus : ",
  12 * 9,
  "\n"
)


# ------------------------------------------------------------
# E. Contrôle des valeurs
# ------------------------------------------------------------

cat("\n--- E. CONTRÔLE DES VALEURS ---\n")

value_check <- tourism_destination %>%
  summarise(
    minimum = min(value, na.rm = TRUE),
    maximum = max(value, na.rm = TRUE),
    moyenne = mean(value, na.rm = TRUE),
    mediane = median(value, na.rm = TRUE),
    total = sum(value, na.rm = TRUE),
    valeurs_negatives = sum(value < 0, na.rm = TRUE),
    valeurs_nulles = sum(value == 0, na.rm = TRUE),
    valeurs_non_entieres = sum(
      abs(value - round(value)) > 1e-8,
      na.rm = TRUE
    )
  )

print(value_check)


# ------------------------------------------------------------
# F. Statistiques descriptives par destination
# ------------------------------------------------------------

cat("\n--- F. STATISTIQUES PAR DESTINATION ---\n")

destination_stats <- tourism_destination %>%
  group_by(dimension_label) %>%
  summarise(
    moyenne = mean(value),
    mediane = median(value),
    minimum = min(value),
    maximum = max(value),
    total_2012_2020 = sum(value),
    .groups = "drop"
  ) %>%
  arrange(desc(moyenne))

print(destination_stats)


# ------------------------------------------------------------
# G. Évolution annuelle nationale
# ------------------------------------------------------------

cat("\n--- G. ÉVOLUTION ANNUELLE ---\n")

annual_total <- tourism_destination %>%
  group_by(year) %>%
  summarise(
    total_nuitees = sum(value),
    nombre_destinations = n_distinct(dimension_key),
    .groups = "drop"
  ) %>%
  arrange(year) %>%
  mutate(
    croissance_pct = (
      total_nuitees / lag(total_nuitees) - 1
    ) * 100
  )

print(annual_total)


# ------------------------------------------------------------
# H. Contrôle des métadonnées
# ------------------------------------------------------------

cat("\n--- H. MÉTADONNÉES ---\n")

print(
  tourism_destination %>%
    distinct(
      indicator,
      unit,
      period_type,
      source_file,
      source_sheet
    )
)


# ------------------------------------------------------------
# I. Export des résultats d'audit
# ------------------------------------------------------------

write_csv(
  destination_stats,
  file.path(
    OUTPUT_AUDIT,
    "tourism_destination_statistics.csv"
  )
)

write_csv(
  annual_total,
  file.path(
    OUTPUT_AUDIT,
    "tourism_destination_annual_totals.csv"
  )
)

write_csv(
  panel_completeness,
  file.path(
    OUTPUT_AUDIT,
    "tourism_destination_panel_completeness.csv"
  )
)

cat("\nAUDIT APPROFONDI TERMINÉ.\n")






# ============================================================
# AUDIT APPROFONDI : CAPACITE HOTELIERE PAR DESTINATION
# ============================================================

capacity_destination <- readr::read_csv(
  file.path(DATA_PROCESSED, "capacity_destination.csv"),
  show_col_types = FALSE
)

cat("\n========================================\n")
cat("AUDIT : CAPACITE HOTELIERE PAR DESTINATION\n")
cat("========================================\n")

# A. Structure
cat("\n--- A. DIMENSIONS ET VARIABLES ---\n")
print(dim(capacity_destination))
print(names(capacity_destination))

# B. Période
cat("\n--- B. ANNEES ---\n")
print(sort(unique(capacity_destination$year)))
print(n_distinct(capacity_destination$year))

# C. Destinations
cat("\n--- C. DESTINATIONS ---\n")
print(
  capacity_destination %>%
    distinct(dimension_key, dimension_label) %>%
    arrange(dimension_label)
)

# D. Doublons
cat("\n--- D. DOUBLONS ANNEE-DESTINATION ---\n")
duplicates_capacity <- capacity_destination %>%
  count(year, dimension_key) %>%
  filter(n > 1)

print(duplicates_capacity)

# E. Complétude
cat("\n--- E. COMPLETUDE DU PANEL ---\n")
print(
  capacity_destination %>%
    count(dimension_key, name = "n_years") %>%
    arrange(n_years)
)

# F. Valeurs
cat("\n--- F. CONTROLE DES VALEURS ---\n")
print(
  capacity_destination %>%
    summarise(
      minimum = min(value, na.rm = TRUE),
      maximum = max(value, na.rm = TRUE),
      moyenne = mean(value, na.rm = TRUE),
      valeurs_manquantes = sum(is.na(value)),
      valeurs_negatives = sum(value < 0, na.rm = TRUE),
      valeurs_nulles = sum(value == 0, na.rm = TRUE),
      valeurs_non_entieres = sum(
        abs(value - round(value)) > 1e-8,
        na.rm = TRUE
      )
    )
)

# G. Statistiques par destination
cat("\n--- G. STATISTIQUES PAR DESTINATION ---\n")
print(
  capacity_destination %>%
    group_by(dimension_label) %>%
    summarise(
      moyenne = mean(value, na.rm = TRUE),
      minimum = min(value, na.rm = TRUE),
      maximum = max(value, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(moyenne))
)

# H. Métadonnées
cat("\n--- H. METADONNEES ---\n")
print(
  capacity_destination %>%
    distinct(indicator, unit, period_type, source_file, source_sheet)
)

cat("\nAUDIT CAPACITE TERMINE.\n")






# ============================================================
# AUDIT : CAPACITE HOTELIERE PAR CATEGORIE
# ============================================================

capacity_category <- readr::read_csv(
  file.path(DATA_PROCESSED, "capacity_category.csv"),
  show_col_types = FALSE
)

cat("\n========================================\n")
cat("AUDIT : CAPACITE PAR CATEGORIE\n")
cat("========================================\n")

# A. Structure
cat("\n--- A. DIMENSIONS ET VARIABLES ---\n")
print(dim(capacity_category))
print(names(capacity_category))

# B. Années
cat("\n--- B. ANNEES ---\n")
print(sort(unique(capacity_category$year)))

# C. Catégories
cat("\n--- C. CATEGORIES ---\n")
print(
  capacity_category %>%
    distinct(dimension_key, dimension_label) %>%
    arrange(dimension_label)
)

# D. Doublons
cat("\n--- D. DOUBLONS ANNEE-CATEGORIE ---\n")
duplicates_category <- capacity_category %>%
  count(year, dimension_key) %>%
  filter(n > 1)

print(duplicates_category)

# E. Complétude
cat("\n--- E. COMPLETUDE ---\n")
print(
  capacity_category %>%
    count(dimension_key, name = "n_years") %>%
    arrange(n_years)
)

# F. Contrôle des valeurs
cat("\n--- F. VALEURS ---\n")
print(
  capacity_category %>%
    summarise(
      minimum = min(value, na.rm = TRUE),
      maximum = max(value, na.rm = TRUE),
      moyenne = mean(value, na.rm = TRUE),
      valeurs_manquantes = sum(is.na(value)),
      valeurs_negatives = sum(value < 0, na.rm = TRUE),
      valeurs_nulles = sum(value == 0, na.rm = TRUE),
      valeurs_non_entieres = sum(
        abs(value - round(value)) > 1e-8,
        na.rm = TRUE
      )
    )
)

# G. Statistiques par catégorie
cat("\n--- G. STATISTIQUES PAR CATEGORIE ---\n")
print(
  capacity_category %>%
    group_by(dimension_label) %>%
    summarise(
      moyenne = mean(value, na.rm = TRUE),
      minimum = min(value, na.rm = TRUE),
      maximum = max(value, na.rm = TRUE),
      total_2012_2020 = sum(value, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(moyenne))
)

# H. Totaux annuels
cat("\n--- H. TOTAL ANNUEL PAR CATEGORIE ---\n")
print(
  capacity_category %>%
    group_by(year) %>%
    summarise(
      capacite_totale = sum(value, na.rm = TRUE),
      nombre_categories = n_distinct(dimension_key),
      .groups = "drop"
    ) %>%
    arrange(year)
)

# I. Métadonnées
cat("\n--- I. METADONNEES ---\n")
print(
  capacity_category %>%
    distinct(indicator, unit, period_type, source_file, source_sheet)
)

cat("\nAUDIT CAPACITE PAR CATEGORIE TERMINE.\n")



# ============================================================
# AUDIT : NUITEES PAR MARCHE TOURISTIQUE
# ============================================================

tourism_market_nights <- readr::read_csv(
  file.path(DATA_PROCESSED, "tourism_market_nights.csv"),
  show_col_types = FALSE
)

cat("\n========================================\n")
cat("AUDIT : NUITEES PAR MARCHE TOURISTIQUE\n")
cat("========================================\n")

# A. Structure
cat("\n--- A. STRUCTURE ---\n")
print(dim(tourism_market_nights))
print(names(tourism_market_nights))

# B. Périodes
cat("\n--- B. PERIODES ---\n")
print(sort(unique(tourism_market_nights$year)))
print(unique(tourism_market_nights$period_type))

# C. Marchés
cat("\n--- C. MARCHES ---\n")
print(
  tourism_market_nights %>%
    distinct(dimension_key, dimension_label) %>%
    arrange(dimension_label)
)

# D. Doublons
cat("\n--- D. DOUBLONS ANNEE-MARCHE ---\n")
duplicates_market <- tourism_market_nights %>%
  count(year, dimension_key) %>%
  filter(n > 1)

print(duplicates_market)

# E. Complétude
cat("\n--- E. COMPLETUDE ---\n")
print(
  tourism_market_nights %>%
    count(dimension_key, name = "n_years") %>%
    arrange(n_years)
)

# F. Valeurs
cat("\n--- F. CONTROLE DES VALEURS ---\n")
print(
  tourism_market_nights %>%
    summarise(
      minimum = min(value, na.rm = TRUE),
      maximum = max(value, na.rm = TRUE),
      moyenne = mean(value, na.rm = TRUE),
      valeurs_manquantes = sum(is.na(value)),
      valeurs_negatives = sum(value < 0, na.rm = TRUE),
      valeurs_nulles = sum(value == 0, na.rm = TRUE),
      valeurs_non_entieres = sum(
        abs(value - round(value)) > 1e-8,
        na.rm = TRUE
      )
    )
)

# G. Statistiques par marché
cat("\n--- G. STATISTIQUES PAR MARCHE ---\n")
print(
  tourism_market_nights %>%
    group_by(dimension_label) %>%
    summarise(
      moyenne = mean(value, na.rm = TRUE),
      minimum = min(value, na.rm = TRUE),
      maximum = max(value, na.rm = TRUE),
      total = sum(value, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(moyenne))
)

# H. Totaux annuels
cat("\n--- H. TOTAL ANNUEL ---\n")
print(
  tourism_market_nights %>%
    group_by(year) %>%
    summarise(
      total_nuitees = sum(value, na.rm = TRUE),
      nombre_marches = n_distinct(dimension_key),
      .groups = "drop"
    ) %>%
    arrange(year)
)

# I. Métadonnées
cat("\n--- I. METADONNEES ---\n")
print(
  tourism_market_nights %>%
    distinct(indicator, unit, period_type, source_file, source_sheet)
)

cat("\nAUDIT NUITEES PAR MARCHE TERMINE.\n")





# ============================================================
# DIAGNOSTIC : HIERARCHIE DES MARCHES TOURISTIQUES
# ============================================================

cat("\n--- A. VALEURS ANNUELLES DES AGREGATS ---\n")

market_aggregates <- tourism_market_nights %>%
  filter(dimension_key %in% c("Résidents", "Non résidents")) %>%
  select(year, dimension_key, value) %>%
  arrange(year, dimension_key)

print(market_aggregates, n = Inf)

cat("\n--- B. MARCHES GEOGRAPHIQUES DETAILLES ---\n")

market_detailed <- tourism_market_nights %>%
  filter(
    !dimension_key %in% c("Résidents", "Non résidents")
  ) %>%
  select(year, dimension_key, value) %>%
  arrange(year, desc(value))

print(market_detailed, n = Inf)

cat("\n--- C. SOMME DES MARCHES DETAILLES ---\n")

detailed_totals <- market_detailed %>%
  group_by(year) %>%
  summarise(
    total_marches_detailles = sum(value, na.rm = TRUE),
    .groups = "drop"
  )

aggregate_comparison <- market_aggregates %>%
  tidyr::pivot_wider(
    names_from = dimension_key,
    values_from = value
  ) %>%
  left_join(detailed_totals, by = "year") %>%
  mutate(
    ecart_vs_non_residents =
      total_marches_detailles - `Non résidents`,
    ratio_couverture_pct =
      total_marches_detailles / `Non résidents` * 100
  )

print(aggregate_comparison, n = Inf)

cat("\n--- D. CONTROLE DE COHERENCE AVEC LES NUITEES PAR DESTINATION ---\n")

destination_totals <- tourism_destination %>%
  group_by(year) %>%
  summarise(
    total_destinations = sum(value),
    .groups = "drop"
  )

print(
  aggregate_comparison %>%
    left_join(destination_totals, by = "year") %>%
    mutate(
      ecart_residents_nonresidents =
        `Résidents` + `Non résidents` - total_destinations
    ),
  n = Inf
)

cat("\nDIAGNOSTIC TERMINE.\n")





# ============================================================
# AUDIT : ARRIVEES TOURISTIQUES PAR NATIONALITE
# ============================================================

arrivals_nationality <- readr::read_csv(
  file.path(DATA_PROCESSED, "arrivals_nationality.csv"),
  show_col_types = FALSE
)

cat("\n========================================\n")
cat("AUDIT : ARRIVEES PAR NATIONALITE\n")
cat("========================================\n")

# A. Structure
cat("\n--- A. STRUCTURE ---\n")
print(dim(arrivals_nationality))
print(names(arrivals_nationality))

# B. Années et périodes
cat("\n--- B. PERIODES ---\n")
print(sort(unique(arrivals_nationality$year)))
print(unique(arrivals_nationality$period_type))

# C. Nationalités
cat("\n--- C. NATIONALITES ---\n")
print(
  arrivals_nationality %>%
    distinct(dimension_key, dimension_label) %>%
    arrange(dimension_label)
)

# D. Doublons
cat("\n--- D. DOUBLONS ANNEE-NATIONALITE ---\n")
duplicates_nationality <- arrivals_nationality %>%
  count(year, dimension_key) %>%
  filter(n > 1)

print(duplicates_nationality)

# E. Complétude
cat("\n--- E. COMPLETUDE ---\n")
print(
  arrivals_nationality %>%
    count(dimension_key, name = "n_years") %>%
    arrange(n_years)
)

# F. Valeurs
cat("\n--- F. CONTROLE DES VALEURS ---\n")
print(
  arrivals_nationality %>%
    summarise(
      minimum = min(value, na.rm = TRUE),
      maximum = max(value, na.rm = TRUE),
      moyenne = mean(value, na.rm = TRUE),
      valeurs_manquantes = sum(is.na(value)),
      valeurs_negatives = sum(value < 0, na.rm = TRUE),
      valeurs_nulles = sum(value == 0, na.rm = TRUE),
      valeurs_non_entieres = sum(
        abs(value - round(value)) > 1e-8,
        na.rm = TRUE
      )
    )
)

# G. Statistiques par nationalité
cat("\n--- G. STATISTIQUES PAR NATIONALITE ---\n")
print(
  arrivals_nationality %>%
    group_by(dimension_label) %>%
    summarise(
      moyenne = mean(value, na.rm = TRUE),
      minimum = min(value, na.rm = TRUE),
      maximum = max(value, na.rm = TRUE),
      total = sum(value, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(moyenne))
)

# H. Totaux annuels
cat("\n--- H. TOTAL ANNUEL ---\n")
print(
  arrivals_nationality %>%
    group_by(year) %>%
    summarise(
      total_arrivees = sum(value, na.rm = TRUE),
      nombre_modalites = n_distinct(dimension_key),
      .groups = "drop"
    ) %>%
    arrange(year)
)

# I. Métadonnées
cat("\n--- I. METADONNEES ---\n")
print(
  arrivals_nationality %>%
    distinct(indicator, unit, period_type, source_file, source_sheet)
)

cat("\nAUDIT ARRIVEES PAR NATIONALITE TERMINE.\n")




# ============================================================
# AUDIT 06 — ARRIVEES PAR POSTE FRONTIERE
# ============================================================

arrivals_entry_point <- readr::read_csv(
  file.path(DATA_PROCESSED, "arrivals_entry_point.csv"),
  show_col_types = FALSE
)

# A. STRUCTURE
cat("\n--- A. STRUCTURE ---\n")
print(dim(arrivals_entry_point))
print(names(arrivals_entry_point))

# B. PERIODES
cat("\n--- B. PERIODES ---\n")
print(sort(unique(arrivals_entry_point$year)))
print(unique(arrivals_entry_point$period_type))

# C. MODALITES
cat("\n--- C. MODALITES ---\n")
print(
  arrivals_entry_point %>%
    distinct(dimension_key, dimension_label) %>%
    arrange(dimension_label)
)

# D. DOUBLONS
cat("\n--- D. DOUBLONS ANNEE-POSTE ---\n")

duplicates_entry <- arrivals_entry_point %>%
  count(year, dimension_key) %>%
  filter(n > 1)

print(duplicates_entry)

# E. COMPLETUDE
cat("\n--- E. COMPLETUDE ---\n")
print(
  arrivals_entry_point %>%
    count(dimension_key, name = "n_years") %>%
    arrange(n_years)
)

# F. CONTROLE DES VALEURS
cat("\n--- F. CONTROLE DES VALEURS ---\n")
print(
  arrivals_entry_point %>%
    summarise(
      minimum = min(value, na.rm = TRUE),
      maximum = max(value, na.rm = TRUE),
      moyenne = mean(value, na.rm = TRUE),
      valeurs_manquantes = sum(is.na(value)),
      valeurs_negatives = sum(value < 0, na.rm = TRUE),
      valeurs_nulles = sum(value == 0, na.rm = TRUE),
      valeurs_non_entieres = sum(
        abs(value - round(value)) > 1e-8,
        na.rm = TRUE
      )
    )
)

# G. STATISTIQUES PAR POSTE
cat("\n--- G. STATISTIQUES PAR POSTE ---\n")
print(
  arrivals_entry_point %>%
    group_by(dimension_label) %>%
    summarise(
      moyenne = mean(value, na.rm = TRUE),
      minimum = min(value, na.rm = TRUE),
      maximum = max(value, na.rm = TRUE),
      total = sum(value, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(moyenne))
)

# H. EVOLUTION ANNUELLE PAR MODALITE
cat("\n--- H. EVOLUTION ANNUELLE ---\n")
print(
  arrivals_entry_point %>%
    group_by(year) %>%
    summarise(
      total_modalites = sum(value, na.rm = TRUE),
      nombre_modalites = n_distinct(dimension_key),
      .groups = "drop"
    ) %>%
    arrange(year)
)

# I. METADONNEES
cat("\n--- I. METADONNEES ---\n")
print(
  arrivals_entry_point %>%
    distinct(indicator, unit, period_type, source_file, source_sheet)
)


# ============================================================
# AUDIT 07 — COHERENCE DES AGREGATS PAR MODE DE TRANSPORT
# ============================================================

# A. Vérifier les aéroports
airport_check <- arrivals_entry_point %>%
  filter(grepl("^A ", dimension_key)) %>%
  group_by(year) %>%
  summarise(
    total_points = sum(value),
    .groups = "drop"
  ) %>%
  left_join(
    arrivals_entry_point %>%
      filter(dimension_key == "T.AIR") %>%
      select(year, total_agregat = value),
    by = "year"
  ) %>%
  mutate(
    ecart = total_agregat - total_points,
    couverture = 100 * total_points / total_agregat
  )

cat("\n--- A. AEROPORTS ---\n")
print(airport_check)

# B. Vérifier les ports
port_check <- arrivals_entry_point %>%
  filter(grepl("^P ", dimension_key)) %>%
  group_by(year) %>%
  summarise(
    total_points = sum(value),
    .groups = "drop"
  ) %>%
  left_join(
    arrivals_entry_point %>%
      filter(dimension_key == "T.MER") %>%
      select(year, total_agregat = value),
    by = "year"
  ) %>%
  mutate(
    ecart = total_agregat - total_points,
    couverture = 100 * total_points / total_agregat
  )

cat("\n--- B. PORTS ---\n")
print(port_check)

# C. Vérifier les postes terrestres
land_check <- arrivals_entry_point %>%
  filter(
    dimension_key %in% c(
      "T Bab Sebta",
      "T Béni Anzar"
    )
  ) %>%
  group_by(year) %>%
  summarise(
    total_points = sum(value),
    .groups = "drop"
  ) %>%
  left_join(
    arrivals_entry_point %>%
      filter(dimension_key == "T.TERRE") %>%
      select(year, total_agregat = value),
    by = "year"
  ) %>%
  mutate(
    ecart = total_agregat - total_points,
    couverture = 100 * total_points / total_agregat
  )

cat("\n--- C. POSTES TERRESTRES ---\n")
print(land_check)

# D. Synthèse des écarts
cat("\n--- D. SYNTHESE ---\n")

print(
  bind_rows(
    airport_check %>% mutate(mode = "AIR"),
    port_check %>% mutate(mode = "MER"),
    land_check %>% mutate(mode = "TERRE")
  ) %>%
    select(mode, year, total_points, total_agregat, ecart, couverture) %>%
    arrange(mode, year)
)

cat("\nAUDIT ARRIVEES PAR POSTE FRONTIERE TERMINE.\n")
