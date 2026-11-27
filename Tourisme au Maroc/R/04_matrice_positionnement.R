# ============================================================
# 04 - MATRICE DE POSITIONNEMENT DES DESTINATIONS
# ============================================================

library(tidyverse)
library(ggplot2)

# 1. Préparation des indicateurs
positioning_data <- cagr_indicators %>%
  select(destination, cagr_nights, cagr_capacity) %>%
  left_join(
    market_indicators_corrected %>%
      filter(year == 2019) %>%
      select(destination, location_quotient_corrected),
    by = "destination"
  ) %>%
  filter(
    !is.na(cagr_nights),
    !is.na(location_quotient_corrected)
  )

# 2. Seuils de comparaison
median_cagr <- median(positioning_data$cagr_nights)
reference_lq <- 1

# 3. Classification
positioning_data <- positioning_data %>%
  mutate(
    profile = case_when(
      location_quotient_corrected >= reference_lq &
        cagr_nights >= median_cagr ~ "Leaders dynamiques",
      
      location_quotient_corrected >= reference_lq &
        cagr_nights < median_cagr ~ "Spécialisés à croissance modérée",
      
      location_quotient_corrected < reference_lq &
        cagr_nights >= median_cagr ~ "Marchés émergents",
      
      TRUE ~ "Marchés en retrait relatif"
    )
  )

# 4. Tableau des résultats
cat("\n--- MATRICE DE POSITIONNEMENT ---\n")

print(
  positioning_data %>%
    select(
      destination,
      cagr_nights,
      location_quotient_corrected,
      profile
    ) %>%
    arrange(desc(cagr_nights))
)

# 5. Graphique
p_positioning <- ggplot(
  positioning_data,
  aes(
    x = location_quotient_corrected,
    y = cagr_nights,
    label = destination
  )
) +
  geom_vline(
    xintercept = 1,
    linetype = "dashed",
    color = "grey45"
  ) +
  geom_hline(
    yintercept = median_cagr,
    linetype = "dashed",
    color = "grey45"
  ) +
  geom_point(size = 3) +
  geom_text(
    nudge_y = 0.008,
    size = 3,
    check_overlap = TRUE
  ) +
  labs(
    title = "Positionnement concurrentiel des destinations touristiques",
    subtitle = paste(
      "LQ 2019 et CAGR des nuitées 2012-2019 |",
      "Seuil de croissance : médiane"
    ),
    x = "Location Quotient (LQ)",
    y = "CAGR des nuitées"
  ) +
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 1)
  ) +
  theme_minimal()

print(p_positioning)

# 6. Export
write_csv(
  positioning_data,
  file.path(DATA_PROCESSED, "destination_positioning.csv")
)

ggsave(
  file.path(OUTPUT_FIGURES, "destination_positioning.png"),
  p_positioning,
  width = 12,
  height = 8,
  dpi = 300
)

cat("\nMATRICE DE POSITIONNEMENT CALCULEE ET EXPORTEE.\n")