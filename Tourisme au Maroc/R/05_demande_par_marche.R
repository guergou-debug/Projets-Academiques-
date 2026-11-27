
# ============================================================
# 05 - ANALYSE DE LA DEMANDE PAR MARCHES EMETTEURS
# ============================================================

library(tidyverse)
library(janitor)

# 1. Importation
market_nights <- read_csv(
  file.path(DATA_PROCESSED, "tourism_market_nights.csv"),
  show_col_types = FALSE
)

# 2. Séparation des agrégats
market_aggregates <- market_nights %>%
  filter(dimension_label %in% c("Résidents", "Non résidents"))

# 3. Evolution de la demande intérieure et internationale
cat("\n--- A. AGREGATS 2019 ---\n")

print(
  market_aggregates %>%
    filter(year == 2019) %>%
    select(dimension_label, value) %>%
    arrange(desc(value))
)

# 4. Parts de marché des agrégats
aggregate_shares <- market_aggregates %>%
  group_by(year) %>%
  mutate(
    total_aggregates = sum(value),
    market_share = value / total_aggregates
  ) %>%
  ungroup()

cat("\n--- B. PARTS DES AGREGATS EN 2019 ---\n")

print(
  aggregate_shares %>%
    filter(year == 2019) %>%
    select(year, dimension_label, value, market_share)
)

# 5. Croissance annuelle
aggregate_growth <- market_aggregates %>%
  arrange(dimension_label, year) %>%
  group_by(dimension_label) %>%
  mutate(
    annual_growth = value / lag(value) - 1
  ) %>%
  ungroup()

cat("\n--- C. CROISSANCE ANNUELLE EN 2019 ---\n")

print(
  aggregate_growth %>%
    filter(year == 2019) %>%
    select(dimension_label, annual_growth)
)

# 6. CAGR 2012-2019
aggregate_cagr <- market_aggregates %>%
  filter(year %in% c(2012, 2019)) %>%
  select(year, dimension_label, value) %>%
  pivot_wider(
    names_from = year,
    values_from = value,
    names_prefix = "value_"
  ) %>%
  mutate(
    cagr_2012_2019 =
      (value_2019 / value_2012)^(1 / 7) - 1
  )

cat("\n--- D. CAGR 2012-2019 ---\n")
print(aggregate_cagr)

# 7. Export
write_csv(
  aggregate_shares,
  file.path(DATA_PROCESSED, "market_aggregate_shares.csv")
)

write_csv(
  aggregate_growth,
  file.path(DATA_PROCESSED, "market_aggregate_growth.csv")
)

write_csv(
  aggregate_cagr,
  file.path(DATA_PROCESSED, "market_aggregate_cagr.csv")
)

cat("\nANALYSE DES AGREGATS TERMINEE.\n")






# ============================================================
# 06 - STRUCTURE DES MARCHES INTERNATIONAUX
# ============================================================

# 1. Exclusion des agrégats
international_markets <- market_nights %>%
  filter(
    !dimension_label %in% c("Résidents", "Non résidents")
  )

# 2. Classement des marchés en 2019
markets_2019 <- international_markets %>%
  filter(year == 2019) %>%
  arrange(desc(value)) %>%
  mutate(
    share_detailed = value / sum(value)
  )

cat("\n--- A. CLASSEMENT DES MARCHES EN 2019 ---\n")

print(
  markets_2019 %>%
    select(
      dimension_label,
      value,
      share_detailed
    )
)

# 3. Couverture des marchés détaillés
coverage_2019 <- international_markets %>%
  filter(year == 2019) %>%
  summarise(
    detailed_total = sum(value)
  ) %>%
  mutate(
    non_resident_total = market_aggregates %>%
      filter(
        year == 2019,
        dimension_label == "Non résidents"
      ) %>%
      pull(value),
    coverage_rate = detailed_total / non_resident_total,
    unexplained_gap = non_resident_total - detailed_total
  )

cat("\n--- B. COUVERTURE DU MARCHE INTERNATIONAL ---\n")
print(coverage_2019)

# 4. CAGR par marché détaillé
markets_cagr <- international_markets %>%
  filter(year %in% c(2012, 2019)) %>%
  select(year, dimension_label, value) %>%
  pivot_wider(
    names_from = year,
    values_from = value,
    names_prefix = "value_"
  ) %>%
  mutate(
    cagr_2012_2019 =
      (value_2019 / value_2012)^(1 / 7) - 1
  ) %>%
  arrange(desc(cagr_2012_2019))

cat("\n--- C. CROISSANCE DES MARCHES 2012-2019 ---\n")
print(markets_cagr)

# 5. Export
write_csv(
  markets_2019,
  file.path(DATA_PROCESSED, "international_markets_2019.csv")
)

write_csv(
  markets_cagr,
  file.path(DATA_PROCESSED, "international_markets_cagr.csv")
)

write_csv(
  coverage_2019,
  file.path(DATA_PROCESSED, "international_markets_coverage.csv")
)

cat("\nANALYSE DES MARCHES INTERNATIONAUX TERMINEE.\n")




# ============================================================
# 07 - CONCENTRATION DES MARCHES INTERNATIONAUX
# ============================================================

# 1. Parts de marché annuelles
market_concentration <- international_markets %>%
  group_by(year) %>%
  mutate(
    detailed_total = sum(value),
    market_share = value / detailed_total
  ) %>%
  arrange(year, desc(market_share)) %>%
  mutate(
    market_rank = row_number()
  ) %>%
  summarise(
    hhi = sum(market_share^2),
    cr3 = sum(market_share[market_rank <= 3]),
    cr5 = sum(market_share[market_rank <= 5]),
    detailed_total = first(detailed_total),
    n_markets = n(),
    .groups = "drop"
  )

# 2. Résultats
cat("\n--- A. CONCENTRATION ANNUELLE ---\n")

print(market_concentration)

# 3. Evolution entre 2012 et 2019
cat("\n--- B. COMPARAISON 2012 / 2019 ---\n")

print(
  market_concentration %>%
    filter(year %in% c(2012, 2019)) %>%
    select(year, hhi, cr3, cr5)
)

# 4. Export
write_csv(
  market_concentration,
  file.path(DATA_PROCESSED, "international_market_concentration.csv")
)

cat("\nINDICATEURS DE CONCENTRATION EXPORTES.\n")
