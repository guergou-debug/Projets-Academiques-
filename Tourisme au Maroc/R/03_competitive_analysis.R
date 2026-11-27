
# ============================================================
# MOROCCO-STAY
# 03 — INDICATEURS DE STRUCTURE ET DE CONCENTRATION
# ============================================================

library(tidyverse)

# 1. Charger le panel
panel <- read_csv(
  file.path(DATA_PROCESSED, "panel_destination.csv"),
  show_col_types = FALSE
)

# 2. Parts de marché et ratios annuels

# ============================================================
# CORRECTION DU LOCATION QUOTIENT : PERIMETRE COMPARABLE
# ============================================================

market_indicators_corrected <- panel_destination %>%
  filter(!is.na(destination_nights)) %>%
  group_by(year) %>%
  mutate(
    total_nights_comparable = sum(destination_nights),
    total_capacity_comparable = sum(capacity_beds),

    demand_share_corrected =
      destination_nights / total_nights_comparable,

    supply_share_corrected =
      capacity_beds / total_capacity_comparable,

    location_quotient_corrected =
      demand_share_corrected / supply_share_corrected
  ) %>%
  ungroup()

# Résultats 2019
cat("\n--- LQ CORRIGE EN 2019 ---\n")

print(
  market_indicators_corrected %>%
    filter(year == 2019) %>%
    select(
      destination,
      demand_share_corrected,
      supply_share_corrected,
      location_quotient_corrected
    ) %>%
    arrange(desc(location_quotient_corrected))
)

# Contrôle des sommes
cat("\n--- CONTROLE DES PARTS ---\n")

print(
  market_indicators_corrected %>%
    filter(year == 2019) %>%
    summarise(
      total_demand_share = sum(demand_share_corrected),
      total_supply_share = sum(supply_share_corrected)
    )
)

# Export
write_csv(
  market_indicators_corrected,
  file.path(DATA_PROCESSED, "market_indicators_corrected.csv")
)
market_indicators <- panel %>%
  group_by(year) %>%
  mutate(
    total_nights = sum(destination_nights, na.rm = TRUE),
    total_capacity = sum(capacity_beds, na.rm = TRUE),
    
    demand_share = destination_nights / total_nights,
    supply_share = capacity_beds / total_capacity,
    
    location_quotient = demand_share / supply_share
  ) %>%
  ungroup() %>%
  arrange(destination, year)

# 3. Croissance annuelle des nuitées et capacités
growth_indicators <- market_indicators %>%
  group_by(destination) %>%
  arrange(year, .by_group = TRUE) %>%
  mutate(
    nights_growth = destination_nights /
      lag(destination_nights) - 1,
    
    capacity_growth = capacity_beds /
      lag(capacity_beds) - 1
  ) %>%
  ungroup()

# 4. CAGR 2012-2019
cagr_indicators <- growth_indicators %>%
  filter(year %in% c(2012, 2019)) %>%
  select(
    destination,
    year,
    destination_nights,
    capacity_beds
  ) %>%
  pivot_wider(
    names_from = year,
    values_from = c(destination_nights, capacity_beds)
  ) %>%
  mutate(
    cagr_nights = if_else(
      !is.na(destination_nights_2012) &
        !is.na(destination_nights_2019),
      (destination_nights_2019 /
         destination_nights_2012)^(1/7) - 1,
      NA_real_
    ),
    
    cagr_capacity = (
      capacity_beds_2019 /
        capacity_beds_2012
    )^(1/7) - 1
  )

# 5. HHI annuel : concentration de la demande et de l'offre
hhi_indicators <- market_indicators %>%
  group_by(year) %>%
  summarise(
    hhi_demand = sum(demand_share^2, na.rm = TRUE),
    hhi_supply = sum(supply_share^2, na.rm = TRUE),
    n_destinations_demand = sum(!is.na(demand_share)),
    n_destinations_supply = sum(!is.na(supply_share)),
    .groups = "drop"
  )

# 6. Résultats 2019
cat("\n--- A. PARTS DE MARCHE EN 2019 ---\n")

print(
  market_indicators %>%
    filter(year == 2019) %>%
    select(
      destination,
      destination_nights,
      capacity_beds,
      demand_share,
      supply_share,
      location_quotient
    ) %>%
    arrange(desc(demand_share))
)

cat("\n--- B. CROISSANCE ANNUELLE 2019 ---\n")

print(
  growth_indicators %>%
    filter(year == 2019) %>%
    select(
      destination,
      nights_growth,
      capacity_growth
    ) %>%
    arrange(desc(nights_growth))
)

cat("\n--- C. CAGR 2012-2019 ---\n")

print(
  cagr_indicators %>%
    select(
      destination,
      cagr_nights,
      cagr_capacity
    ) %>%
    arrange(desc(cagr_nights))
)

cat("\n--- D. HHI ---\n")
print(hhi_indicators)

# 7. Export des résultats
write_csv(
  market_indicators,
  file.path(DATA_PROCESSED, "market_indicators.csv")
)

write_csv(
  growth_indicators,
  file.path(DATA_PROCESSED, "growth_indicators.csv")
)

write_csv(
  cagr_indicators,
  file.path(DATA_PROCESSED, "cagr_indicators.csv")
)

write_csv(
  hhi_indicators,
  file.path(DATA_PROCESSED, "hhi_indicators.csv")
)

cat("\nINDICATEURS CONCURRENTIELS CALCULES.\n")



# ============================================================
# CORRECTION DU LOCATION QUOTIENT : PERIMETRE COMPARABLE
# ============================================================

market_indicators_corrected <- panel_destination %>%
  filter(!is.na(destination_nights)) %>%
  group_by(year) %>%
  mutate(
    total_nights_comparable = sum(destination_nights),
    total_capacity_comparable = sum(capacity_beds),
    
    demand_share_corrected =
      destination_nights / total_nights_comparable,
    
    supply_share_corrected =
      capacity_beds / total_capacity_comparable,
    
    location_quotient_corrected =
      demand_share_corrected / supply_share_corrected
  ) %>%
  ungroup()

# Résultats 2019
cat("\n--- LQ CORRIGE EN 2019 ---\n")

print(
  market_indicators_corrected %>%
    filter(year == 2019) %>%
    select(
      destination,
      demand_share_corrected,
      supply_share_corrected,
      location_quotient_corrected
    ) %>%
    arrange(desc(location_quotient_corrected))
)

# Contrôle des sommes
cat("\n--- CONTROLE DES PARTS ---\n")

print(
  market_indicators_corrected %>%
    filter(year == 2019) %>%
    summarise(
      total_demand_share = sum(demand_share_corrected),
      total_supply_share = sum(supply_share_corrected)
    )
)

# Export
write_csv(
  market_indicators_corrected,
  file.path(DATA_PROCESSED, "market_indicators_corrected.csv")
)
