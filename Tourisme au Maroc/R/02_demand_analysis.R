
# ============================================================
# MOROCCO-STAY
# 02 — CONSTRUCTION DU PANEL DEMANDE-CAPACITE
# ============================================================

library(tidyverse)
library(janitor)

# 1. Importation
tourism_destination <- read_csv(
  file.path(DATA_PROCESSED, "tourism_destination.csv"),
  show_col_types = FALSE
)

capacity_destination <- read_csv(
  file.path(DATA_PROCESSED, "capacity_destination.csv"),
  show_col_types = FALSE
)

# 2. Préparation des nuitées
demand <- tourism_destination %>%
  transmute(
    year,
    dimension_key,
    destination_nights = value,
    destination_label_nights = dimension_label
  )

# 3. Préparation de la capacité
supply <- capacity_destination %>%
  transmute(
    year,
    dimension_key,
    capacity_beds = value,
    destination_label_capacity = dimension_label
  )

# 4. Fusion sur destination et année
panel_destination <- full_join(
  demand,
  supply,
  by = c("year", "dimension_key")
) %>%
  mutate(
    destination = coalesce(
      destination_label_nights,
      destination_label_capacity
    ),
    
    annual_bed_capacity = capacity_beds * 365,
    
    # Indicateur approximatif, pas un taux d'occupation officiel
    capacity_pressure_proxy = if_else(
      !is.na(destination_nights) &
        !is.na(annual_bed_capacity) &
        annual_bed_capacity > 0,
      destination_nights / annual_bed_capacity,
      NA_real_
    )
  ) %>%
  arrange(destination, year)

# 5. Contrôles
cat("\n--- A. DIMENSIONS DU PANEL ---\n")
print(dim(panel_destination))

cat("\n--- B. DESTINATIONS ---\n")
print(
  panel_destination %>%
    distinct(dimension_key, destination) %>%
    arrange(destination)
)

cat("\n--- C. COMPLETUDE ---\n")
print(
  panel_destination %>%
    group_by(destination) %>%
    summarise(
      n_years = n_distinct(year),
      missing_nights = sum(is.na(destination_nights)),
      missing_capacity = sum(is.na(capacity_beds)),
      .groups = "drop"
    )
)

cat("\n--- D. VERIFICATION IFRANE ---\n")
print(
  panel_destination %>%
    filter(str_detect(str_to_lower(destination), "ifrane"))
)

cat("\n--- E. INDICATEUR DE PRESSION ---\n")
print(
  panel_destination %>%
    filter(year == 2019) %>%
    select(
      destination,
      destination_nights,
      capacity_beds,
      capacity_pressure_proxy
    ) %>%
    arrange(desc(capacity_pressure_proxy))
)

cat("\n--- F. DOUBLONS ---\n")
print(
  panel_destination %>%
    count(year, dimension_key) %>%
    filter(n > 1)
)

# 6. Export
write_csv(
  panel_destination,
  file.path(DATA_PROCESSED, "panel_destination.csv")
)

cat("\nPANEL DESTINATION CREE ET ENREGISTRE.\n")
