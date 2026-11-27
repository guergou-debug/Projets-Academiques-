
# ============================================================
# MOROCCO-STAY — FONCTIONS UTILITAIRES
# ============================================================

format_number <- function(x, digits = 0) {
  
  vapply(x, function(value) {
    
    if (is.na(value)) {
      return("Non disponible")
    }
    
    format(
      round(value, digits),
      big.mark = " ",
      decimal.mark = ",",
      scientific = FALSE,
      trim = TRUE
    )
    
  }, character(1))
}


format_percent <- function(x, digits = 1) {
  
  vapply(x, function(value) {
    
    if (is.na(value)) {
      return("Non disponible")
    }
    
    paste0(
      format(
        round(100 * value, digits),
        decimal.mark = ",",
        nsmall = digits
      ),
      " %"
    )
    
  }, character(1))
}


get_overview_kpis <- function(data, selected_year = 2019) {
  
  panel <- data$panel_destination %>%
    filter(year == selected_year)
  
  comparable <- panel %>%
    filter(!is.na(destination_nights))
  
  total_nights <- sum(
    comparable$destination_nights,
    na.rm = TRUE
  )
  
  total_beds <- sum(
    comparable$capacity_beds,
    na.rm = TRUE
  )
  
  proxy <- if (total_beds > 0) {
    total_nights / (total_beds * 365)
  } else {
    NA_real_
  }
  
  list(
    nights = total_nights,
    beds = total_beds,
    proxy = proxy,
    destinations = n_distinct(comparable$destination),
    osm = nrow(data$osm)
  )
}
