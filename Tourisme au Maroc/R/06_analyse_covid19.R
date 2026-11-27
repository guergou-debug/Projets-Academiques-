
# ============================================================
# 08 - MESURE DU CHOC COVID-19 PAR DESTINATION
# ============================================================

# 1. Données 2019 et 2020
covid_destination <- panel_destination %>%
  filter(year %in% c(2019, 2020)) %>%
  select(
    destination,
    year,
    destination_nights,
    capacity_beds
  ) %>%
  pivot_wider(
    names_from = year,
    values_from = c(destination_nights, capacity_beds),
    names_sep = "_"
  )

# 2. Calcul des variations
covid_destination <- covid_destination %>%
  mutate(
    nights_change =
      destination_nights_2020 - destination_nights_2019,
    
    nights_change_pct =
      destination_nights_2020 / destination_nights_2019 - 1,
    
    capacity_change_pct =
      capacity_beds_2020 / capacity_beds_2019 - 1
  ) %>%
  arrange(nights_change_pct)

cat("\n--- A. CHOC COVID PAR DESTINATION ---\n")

print(
  covid_destination %>%
    select(
      destination,
      destination_nights_2019,
      destination_nights_2020,
      nights_change_pct,
      capacity_change_pct
    )
)

# 3. Statistiques descriptives
cat("\n--- B. STATISTIQUES DU CHOC ---\n")

print(
  covid_destination %>%
    summarise(
      destinations_observees = sum(!is.na(nights_change_pct)),
      baisse_moyenne = mean(nights_change_pct, na.rm = TRUE),
      baisse_mediane = median(nights_change_pct, na.rm = TRUE),
      baisse_minimale = min(nights_change_pct, na.rm = TRUE),
      baisse_maximale = max(nights_change_pct, na.rm = TRUE)
    )
)

# 4. Export
write_csv(
  covid_destination,
  file.path(DATA_PROCESSED, "covid_destination_impact.csv")
)

cat("\nANALYSE DU CHOC COVID PAR DESTINATION TERMINEE.\n")




# ============================================================
# COMPARAISON AGREGEE : DEMANDE ET CAPACITE, 2019-2020
# ============================================================

covid_aggregate <- covid_destination %>%
  filter(!is.na(destination_nights_2019)) %>%
  summarise(
    destinations = n(),
    
    nights_2019 = sum(destination_nights_2019),
    nights_2020 = sum(destination_nights_2020),
    
    beds_2019 = sum(capacity_beds_2019),
    beds_2020 = sum(capacity_beds_2020),
    
    nights_change_pct = nights_2020 / nights_2019 - 1,
    capacity_change_pct = beds_2020 / beds_2019 - 1,
    
    pressure_2019 = nights_2019 / (beds_2019 * 365),
    pressure_2020 = nights_2020 / (beds_2020 * 365)
  )

cat("\n--- DEMANDE ET CAPACITE : 2019-2020 ---\n")
print(covid_aggregate)

cat("\n--- VARIATIONS EN POURCENTAGE ---\n")
print(
  covid_aggregate %>%
    select(
      nights_change_pct,
      capacity_change_pct,
      pressure_2019,
      pressure_2020
    )
)

write_csv(
  covid_aggregate,
  file.path(DATA_PROCESSED, "covid_aggregate_comparison.csv")
  
)



# ============================================================
#  COVID-19 : CHOC PAR MARCHE EMETTEUR
# ============================================================

covid_markets <- market_aggregates %>%
  filter(year %in% c(2019, 2020)) %>%
  select(dimension_label, year, value) %>%
  pivot_wider(
    names_from = year,
    values_from = value,
    names_prefix = "nights_"
  ) %>%
  mutate(
    change_absolute = nights_2020 - nights_2019,
    change_pct = nights_2020 / nights_2019 - 1
  ) %>%
  arrange(change_pct)

cat("\n--- A. CHOC COVID PAR MARCHE ---\n")
print(covid_markets)

cat("\n--- B. CONTRIBUTION AU RECUL TOTAL ---\n")
print(
  covid_markets %>%
    mutate(
      contribution_to_decline =
        (nights_2019 - nights_2020) /
        sum(nights_2019 - nights_2020)
    ) %>%
    select(
      dimension_label,
      change_absolute,
      change_pct,
      contribution_to_decline
    )
)

write_csv(
  covid_markets,
  file.path(DATA_PROCESSED, "covid_market_impact.csv")
)



# ============================================================
# COVID-19 : MARCHES INTERNATIONAUX DETAILLES
# ============================================================

covid_international <- international_markets %>%
  filter(year %in% c(2019, 2020)) %>%
  select(dimension_label, year, value) %>%
  pivot_wider(
    names_from = year,
    values_from = value,
    names_prefix = "nights_"
  ) %>%
  mutate(
    change_absolute = nights_2020 - nights_2019,
    change_pct = nights_2020 / nights_2019 - 1
  ) %>%
  arrange(change_pct)

cat("\n--- A. CHOC COVID PAR MARCHE INTERNATIONAL ---\n")
print(covid_international)

cat("\n--- B. CLASSEMENT DES MARCHES LES PLUS RESILIENTS ---\n")
print(
  covid_international %>%
    mutate(
      relative_resilience_rank = row_number()
    ) %>%
    select(
      relative_resilience_rank,
      dimension_label,
      change_pct,
      change_absolute
    )
)

write_csv(
  covid_international,
  file.path(DATA_PROCESSED, "covid_international_markets.csv")
)