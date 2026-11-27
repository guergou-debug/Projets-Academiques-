
# ============================================================
# MOROCCO-STAY — MODULE VUE D'ENSEMBLE
# Fichier : R/modules/mod_overview.R
# ============================================================

mod_overview_ui <- function(id) {
  
  ns <- shiny::NS(id)
  
  shiny::tagList(
    
    shiny::fluidRow(
      shiny::column(
        12,
        shiny::div(
          class = "intro-panel",
          shiny::h3("Le marché de l'hébergement touristique au Maroc"),
          shiny::p(
            "Tableau de bord d'intelligence économique : ",
            "demande, capacité d'hébergement et dynamiques territoriales."
          )
        )
      )
    ),
    
    shiny::fluidRow(
      shiny::column(
        3,
        shiny::uiOutput(ns("kpi_nights"))
      ),
      shiny::column(
        3,
        shiny::uiOutput(ns("kpi_beds"))
      ),
      shiny::column(
        3,
        shiny::uiOutput(ns("kpi_proxy"))
      ),
      shiny::column(
        3,
        shiny::uiOutput(ns("kpi_destinations"))
      )
    ),
    
    shiny::fluidRow(
      shiny::column(
        12,
        bslib::card(
          bslib::card_header("Dynamique de la demande touristique"),
          plotly::plotlyOutput(ns("demand_trend"), height = "330px")
        )
      )
    ),
    
    shiny::fluidRow(
      shiny::column(
        6,
        bslib::card(
          bslib::card_header("Évolution de la capacité hôtelière"),
          plotly::plotlyOutput(ns("supply_trend"), height = "320px")
        )
      ),
      shiny::column(
        6,
        bslib::card(
          bslib::card_header("Concentration de la demande territoriale"),
          plotly::plotlyOutput(ns("destination_ranking"), height = "320px")
        )
      )
    ),
    
    shiny::fluidRow(
      shiny::column(
        12,
        bslib::card(
          bslib::card_header("Rupture observée entre 2019 et 2020"),
          plotly::plotlyOutput(ns("covid_impact"), height = "320px")
        )
      )
    ),
    
    shiny::fluidRow(
      shiny::column(
        12,
        shiny::div(
          class = "method-note",
          shiny::strong("Note méthodologique : "),
          "Le proxy d'utilisation est calculé comme le rapport ",
          "entre les nuitées et la capacité annuelle théorique ",
          "(lits × 365). Il ne constitue pas un taux d'occupation ",
          "officiel. Les données 2020 sont présentées comme une ",
          "rupture descriptive, sans interprétation causale."
        )
      )
    )
  )
}


mod_overview_server <- function(id, data) {
  
  shiny::moduleServer(id, function(input, output, session) {
    
    # Périmètre comparable : destinations ayant des nuitées observées
    comparable_panel <- shiny::reactive({
      
      data$panel_destination %>%
        filter(!is.na(destination_nights))
    })
    
    # KPI : année de référence 2019
    kpis <- shiny::reactive({
      get_overview_kpis(data, 2019)
    })
    
    make_kpi <- function(label, value, subtitle) {
      
      shiny::div(
        class = "kpi-card",
        shiny::div(class = "kpi-label", label),
        shiny::div(class = "kpi-value", value),
        shiny::div(class = "kpi-subtitle", subtitle)
      )
    }
    
    output$kpi_nights <- shiny::renderUI({
      k <- kpis()
      make_kpi(
        "Nuitées réalisées — 2019",
        format_number(k$nights),
        "12 destinations comparables"
      )
    })
    
    output$kpi_beds <- shiny::renderUI({
      k <- kpis()
      make_kpi(
        "Capacité classée — 2019",
        format_number(k$beds),
        "Lits, même périmètre"
      )
    })
    
    output$kpi_proxy <- shiny::renderUI({
      k <- kpis()
      make_kpi(
        "Proxy d'utilisation",
        format_percent(k$proxy),
        "Nuitées / (lits × 365)"
      )
    })
    
    output$kpi_destinations <- shiny::renderUI({
      k <- kpis()
      make_kpi(
        "Destinations étudiées",
        as.character(k$destinations),
        "Avec données de nuitées"
      )
    })
    
    # 1. Evolution de la demande
    output$demand_trend <- plotly::renderPlotly({
      
      trend <- comparable_panel() %>%
        group_by(year) %>%
        summarise(
          nights = sum(destination_nights, na.rm = TRUE),
          .groups = "drop"
        )
      
      p <- ggplot2::ggplot(
        trend,
        ggplot2::aes(
          x = year,
          y = nights,
          text = paste0(
            "Année : ", year,
            "<br>Nuitées : ", format_number(nights)
          )
        )
      ) +
        ggplot2::geom_line(
          linewidth = 1.2,
          color = "#087E8B"
        ) +
        ggplot2::geom_point(
          size = 2.8,
          color = "#087E8B"
        ) +
        ggplot2::geom_vline(
          xintercept = 2020,
          linetype = "dashed",
          color = "#C65D3B"
        ) +
        ggplot2::scale_y_continuous(
          labels = scales::label_number(
            big.mark = " ",
            decimal.mark = ","
          )
        ) +
        ggplot2::scale_x_continuous(
          breaks = sort(unique(trend$year))
        ) +
        ggplot2::labs(
          x = NULL,
          y = "Nuitées",
          caption = "Périmètre : 12 destinations disposant de données"
        ) +
        ggplot2::theme_minimal(base_size = 12) +
        ggplot2::theme(
          panel.grid.minor = ggplot2::element_blank()
        )
      
      plotly::ggplotly(p, tooltip = "text") %>%
        plotly::config(displayModeBar = FALSE)
    })
    
    # 2. Evolution de la capacité
    output$supply_trend <- plotly::renderPlotly({
      
      trend <- comparable_panel() %>%
        group_by(year) %>%
        summarise(
          beds = sum(capacity_beds, na.rm = TRUE),
          .groups = "drop"
        )
      
      p <- ggplot2::ggplot(
        trend,
        ggplot2::aes(
          x = year,
          y = beds,
          text = paste0(
            "Année : ", year,
            "<br>Capacité : ", format_number(beds), " lits"
          )
        )
      ) +
        ggplot2::geom_line(
          linewidth = 1.2,
          color = "#23415C"
        ) +
        ggplot2::geom_point(
          size = 2.8,
          color = "#23415C"
        ) +
        ggplot2::scale_y_continuous(
          labels = scales::label_number(big.mark = " ")
        ) +
        ggplot2::scale_x_continuous(
          breaks = sort(unique(trend$year))
        ) +
        ggplot2::labs(
          x = NULL,
          y = "Nombre de lits"
        ) +
        ggplot2::theme_minimal(base_size = 12)
      
      plotly::ggplotly(p, tooltip = "text") %>%
        plotly::config(displayModeBar = FALSE)
    })
    
    # 3. Classement des destinations en 2019
    output$destination_ranking <- plotly::renderPlotly({
      
      ranking <- comparable_panel() %>%
        filter(year == 2019) %>%
        arrange(destination_nights) %>%
        mutate(
          destination = factor(
            destination,
            levels = destination
          )
        )
      
      p <- ggplot2::ggplot(
        ranking,
        ggplot2::aes(
          x = destination_nights,
          y = destination,
          text = paste0(
            destination,
            "<br>Nuitées : ",
            format_number(destination_nights)
          )
        )
      ) +
        ggplot2::geom_col(
          fill = "#087E8B",
          width = 0.7
        ) +
        ggplot2::scale_x_continuous(
          labels = scales::label_number(big.mark = " ")
        ) +
        ggplot2::labs(
          x = "Nuitées en 2019",
          y = NULL
        ) +
        ggplot2::theme_minimal(base_size = 11) +
        ggplot2::theme(
          panel.grid.minor = ggplot2::element_blank()
        )
      
      plotly::ggplotly(p, tooltip = "text") %>%
        plotly::config(displayModeBar = FALSE)
    })
    
    # 4. Impact descriptif 2019-2020
    output$covid_impact <- plotly::renderPlotly({
      
      covid <- data$covid_markets %>%
        mutate(
          variation = 100 * change_pct,
          dimension_label = factor(
            dimension_label,
            levels = dimension_label[order(variation)]
          )
        )
      
      p <- ggplot2::ggplot(
        covid,
        ggplot2::aes(
          x = dimension_label,
          y = variation,
          fill = dimension_label,
          text = paste0(
            dimension_label,
            "<br>Variation : ",
            format_percent(change_pct)
          )
        )
      ) +
        ggplot2::geom_col(width = 0.55, show.legend = FALSE) +
        ggplot2::geom_hline(
          yintercept = 0,
          color = "grey40"
        ) +
        ggplot2::coord_flip() +
        ggplot2::scale_y_continuous(
          labels = function(x) paste0(x, " %")
        ) +
        ggplot2::labs(
          x = NULL,
          y = "Variation des nuitées"
        ) +
        ggplot2::theme_minimal(base_size = 12) +
        ggplot2::theme(
          panel.grid.minor = ggplot2::element_blank()
        )
      
      plotly::ggplotly(p, tooltip = "text") %>%
        plotly::config(displayModeBar = FALSE)
    })
    
  })
}
