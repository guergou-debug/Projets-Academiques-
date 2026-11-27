
# ============================================================
# MODULE : CONCURRENCE TERRITORIALE
# Projet : MOROCCO-STAY
# ============================================================

mod_competition_ui <- function(id) {
  
  ns <- shiny::NS(id)
  
  shiny::tagList(
    
    shiny::fluidRow(
      shiny::column(
        width = 12,
        shiny::div(
          class = "section-intro",
          shiny::h3("Concurrence territoriale"),
          shiny::p(
            "Analyse comparative du poids des destinations, de leur spécialisation ",
            "relative et de leur dynamique de croissance."
          )
        )
      )
    ),
    
    shiny::fluidRow(
      shiny::column(
        width = 3,
        shiny::selectInput(
          inputId = ns("year"),
          label = "Année d'analyse",
          choices = 2012:2020,
          selected = 2019
        )
      )
    ),
    
    shiny::fluidRow(
      shiny::column(
        width = 3,
        shiny::uiOutput(ns("kpi_demand_share"))
      ),
      shiny::column(
        width = 3,
        shiny::uiOutput(ns("kpi_leader"))
      ),
      shiny::column(
        width = 3,
        shiny::uiOutput(ns("kpi_lq"))
      ),
      shiny::column(
        width = 3,
        shiny::uiOutput(ns("kpi_hhi"))
      )
    ),
    
    shiny::hr(),
    
    shiny::h4("1. Structure concurrentielle des destinations"),
    
    shiny::fluidRow(
      shiny::column(
        width = 6,
        shiny::h5("Parts de marché : demande et capacité"),
        plotly::plotlyOutput(ns("market_shares"), height = "390px")
      ),
      shiny::column(
        width = 6,
        shiny::h5("Spécialisation relative des destinations"),
        plotly::plotlyOutput(ns("lq_chart"), height = "390px")
      )
    ),
    
    shiny::hr(),
    
    shiny::h4("2. Concentration du marché"),
    
    shiny::fluidRow(
      shiny::column(
        width = 12,
        plotly::plotlyOutput(ns("hhi_chart"), height = "350px")
      )
    ),
    
    shiny::div(
      class = "method-note",
      shiny::strong("Note de lecture : "),
      "le HHI de la demande porte sur 12 destinations, tandis que celui de l'offre ",
      "porte sur 13 destinations. Les deux séries décrivent des périmètres distincts ",
      "et doivent être interprétées séparément."
    ),
    
    shiny::hr(),
    
    shiny::h4("3. Positionnement stratégique des destinations"),
    
    shiny::p(
      "Le graphique croise la croissance annuelle moyenne des nuitées entre 2012 et 2019 ",
      "avec le niveau de spécialisation relative observé en 2019."
    ),
    
    shiny::fluidRow(
      shiny::column(
        width = 12,
        plotly::plotlyOutput(ns("positioning_chart"), height = "500px")
      )
    ),
    
    shiny::hr(),
    
    shiny::h4("4. Tableau comparatif des destinations"),
    
    DT::DTOutput(ns("competition_table")),
    
    shiny::br(),
    
    shiny::div(
      class = "method-note",
      shiny::strong("Précautions méthodologiques : "),
      "un LQ supérieur à 1 signifie que la part de la demande d'une destination ",
      "est supérieure à sa part dans la capacité en lits. Il ne constitue ni une ",
      "mesure de rentabilité ni un taux d'occupation. Le positionnement est relatif ",
      "aux destinations observées et au seuil médian de croissance de l'échantillon."
    )
  )
}


# ============================================================
# SERVEUR
# ============================================================

mod_competition_server <- function(id, data) {
  
  shiny::moduleServer(id, function(input, output, session) {
    
    # --------------------------------------------------------
    # 1. Données de concurrence pour l'année sélectionnée
    # --------------------------------------------------------
    
    competition_year <- shiny::reactive({
      
      data$market_indicators |>
        dplyr::filter(
          year == as.integer(input$year),
          !is.na(destination_nights),
          !is.na(demand_share_corrected),
          !is.na(supply_share_corrected)
        ) |>
        dplyr::select(
          destination,
          destination_nights,
          capacity_beds,
          demand_share_corrected,
          supply_share_corrected,
          location_quotient_corrected
        ) |>
        dplyr::arrange(dplyr::desc(demand_share_corrected))
      
    })
    
    
    # --------------------------------------------------------
    # 2. Données de positionnement : CAGR + LQ 2019
    # --------------------------------------------------------
    
    positioning_data <- shiny::reactive({
      
      lq_2019 <- data$market_indicators |>
        dplyr::filter(
          year == 2019,
          !is.na(destination_nights),
          !is.na(location_quotient_corrected)
        ) |>
        dplyr::select(
          destination,
          location_quotient_corrected
        )
      
      result <- data$cagr |>
        dplyr::select(
          destination,
          cagr_nights,
          cagr_capacity
        ) |>
        dplyr::inner_join(
          lq_2019,
          by = "destination"
        ) |>
        dplyr::filter(
          !is.na(cagr_nights),
          !is.na(location_quotient_corrected)
        )
      
      median_growth <- stats::median(
        result$cagr_nights,
        na.rm = TRUE
      )
      
      result |>
        dplyr::mutate(
          growth_group = dplyr::case_when(
            cagr_nights >= median_growth &
              location_quotient_corrected >= 1 ~
              "Leaders dynamiques",
            
            cagr_nights >= median_growth &
              location_quotient_corrected < 1 ~
              "Marchés émergents",
            
            cagr_nights < median_growth &
              location_quotient_corrected >= 1 ~
              "Spécialisés à croissance modérée",
            
            TRUE ~ "Marchés en retrait relatif"
          )
        )
      
    })
    
    
    # --------------------------------------------------------
    # 3. KPI
    # --------------------------------------------------------
    
    output$kpi_demand_share <- shiny::renderUI({
      
      d <- competition_year()
      
      value <- if (nrow(d) > 0) {
        sum(d$demand_share_corrected, na.rm = TRUE) * 100
      } else {
        NA_real_
      }
      
      shiny::div(
        class = "kpi-card",
        shiny::div(class = "kpi-label", "Demande couverte"),
        shiny::div(
          class = "kpi-value",
          ifelse(is.na(value), "—", paste0(round(value, 1), " %"))
        ),
        shiny::div(class = "kpi-subtitle", "Périmètre comparable")
      )
    })
    
    
    output$kpi_leader <- shiny::renderUI({
      
      d <- competition_year()
      
      leader <- if (nrow(d) > 0) {
        d$destination[which.max(d$demand_share_corrected)]
      } else {
        "—"
      }
      
      shiny::div(
        class = "kpi-card",
        shiny::div(class = "kpi-label", "Destination dominante"),
        shiny::div(class = "kpi-value", leader),
        shiny::div(class = "kpi-subtitle", "Part de demande la plus élevée")
      )
    })
    
    
    output$kpi_lq <- shiny::renderUI({
      
      d <- competition_year()
      
      valid <- d |>
        dplyr::filter(!is.na(location_quotient_corrected))
      
      value <- if (nrow(valid) > 0) {
        max(valid$location_quotient_corrected, na.rm = TRUE)
      } else {
        NA_real_
      }
      
      shiny::div(
        class = "kpi-card",
        shiny::div(class = "kpi-label", "LQ maximal"),
        shiny::div(
          class = "kpi-value",
          ifelse(is.na(value), "—", round(value, 2))
        ),
        shiny::div(class = "kpi-subtitle", "Demande relativement à l'offre")
      )
    })
    
    
    output$kpi_hhi <- shiny::renderUI({
      
      hhi_row <- data$hhi |>
        dplyr::filter(year == as.integer(input$year))
      
      value <- if (nrow(hhi_row) > 0) {
        hhi_row$hhi_demand[1]
      } else {
        NA_real_
      }
      
      shiny::div(
        class = "kpi-card",
        shiny::div(class = "kpi-label", "HHI de la demande"),
        shiny::div(
          class = "kpi-value",
          ifelse(is.na(value), "—", round(value, 3))
        ),
        shiny::div(class = "kpi-subtitle", "12 destinations")
      )
    })
    
    
    # --------------------------------------------------------
    # 4. Parts de marché
    # --------------------------------------------------------
    
    output$market_shares <- plotly::renderPlotly({
      
      d <- competition_year()
      
      validate(
        shiny::need(nrow(d) > 0, "Aucune donnée disponible pour cette année.")
      )
      
      plot_data <- d |>
        dplyr::select(
          destination,
          Demande = demand_share_corrected,
          Offre = supply_share_corrected
        ) |>
        tidyr::pivot_longer(
          cols = c("Demande", "Offre"),
          names_to = "dimension",
          values_to = "share"
        )
      
      p <- ggplot2::ggplot(
        plot_data,
        ggplot2::aes(
          x = stats::reorder(destination, share),
          y = share * 100,
          fill = dimension,
          text = paste0(
            destination,
            "<br>", dimension, " : ",
            round(share * 100, 2), " %"
          )
        )
      ) +
        ggplot2::geom_col(
          position = "dodge",
          width = 0.75
        ) +
        ggplot2::coord_flip() +
        ggplot2::scale_fill_manual(
          values = c(
            "Demande" = "#087E8B",
            "Offre" = "#23415C"
          )
        ) +
        ggplot2::labs(
          x = NULL,
          y = "Part (%)",
          fill = NULL
        ) +
        ggplot2::theme_minimal(base_size = 11) +
        ggplot2::theme(
          legend.position = "bottom",
          panel.grid.minor = ggplot2::element_blank()
        )
      
      plotly::ggplotly(
        p,
        tooltip = "text"
      ) |>
        plotly::layout(
          margin = list(l = 130, r = 20, b = 50, t = 20)
        )
    })
    
    
    # --------------------------------------------------------
    # 5. Location Quotient
    # --------------------------------------------------------
    
    output$lq_chart <- plotly::renderPlotly({
      
      d <- competition_year() |>
        dplyr::filter(!is.na(location_quotient_corrected)) |>
        dplyr::mutate(
          specialization = ifelse(
            location_quotient_corrected >= 1,
            "LQ supérieur ou égal à 1",
            "LQ inférieur à 1"
          )
        )
      
      validate(
        shiny::need(nrow(d) > 0, "Aucune donnée LQ disponible.")
      )
      
      p <- ggplot2::ggplot(
        d,
        ggplot2::aes(
          x = stats::reorder(destination, location_quotient_corrected),
          y = location_quotient_corrected,
          fill = specialization,
          text = paste0(
            destination,
            "<br>LQ : ",
            round(location_quotient_corrected, 2)
          )
        )
      ) +
        ggplot2::geom_col(width = 0.7) +
        ggplot2::geom_hline(
          yintercept = 1,
          linetype = "dashed",
          color = "#D97706"
        ) +
        ggplot2::coord_flip() +
        ggplot2::scale_fill_manual(
          values = c(
            "LQ supérieur ou égal à 1" = "#087E8B",
            "LQ inférieur à 1" = "#A7B4C2"
          )
        ) +
        ggplot2::labs(
          x = NULL,
          y = "Location Quotient",
          fill = NULL
        ) +
        ggplot2::theme_minimal(base_size = 11) +
        ggplot2::theme(
          legend.position = "bottom",
          panel.grid.minor = ggplot2::element_blank()
        )
      
      plotly::ggplotly(
        p,
        tooltip = "text"
      ) |>
        plotly::layout(
          margin = list(l = 130, r = 20, b = 50, t = 20)
        )
    })
    
    
    # --------------------------------------------------------
    # 6. Evolution de la concentration HHI
    # --------------------------------------------------------
    
    output$hhi_chart <- plotly::renderPlotly({
      
      d <- data$hhi |>
        dplyr::select(
          year,
          Demande = hhi_demand,
          Offre = hhi_supply
        ) |>
        tidyr::pivot_longer(
          cols = c("Demande", "Offre"),
          names_to = "dimension",
          values_to = "hhi"
        )
      
      p <- ggplot2::ggplot(
        d,
        ggplot2::aes(
          x = year,
          y = hhi,
          color = dimension,
          group = dimension,
          text = paste0(
            "Année : ", year,
            "<br>", dimension,
            "<br>HHI : ", round(hhi, 3)
          )
        )
      ) +
        ggplot2::geom_line(linewidth = 1.1) +
        ggplot2::geom_point(size = 2.5) +
        ggplot2::scale_color_manual(
          values = c(
            "Demande" = "#087E8B",
            "Offre" = "#23415C"
          )
        ) +
        ggplot2::scale_x_continuous(
          breaks = 2012:2020
        ) +
        ggplot2::labs(
          x = "Année",
          y = "Indice HHI",
          color = NULL
        ) +
        ggplot2::theme_minimal(base_size = 11) +
        ggplot2::theme(
          legend.position = "bottom",
          panel.grid.minor = ggplot2::element_blank()
        )
      
      plotly::ggplotly(
        p,
        tooltip = "text"
      )
    })
    
    
    # --------------------------------------------------------
    # 7. Matrice de positionnement territorial
    # --------------------------------------------------------
    
    output$positioning_chart <- plotly::renderPlotly({
      
      d <- positioning_data()
      
      validate(
        shiny::need(nrow(d) > 0, "Données de positionnement indisponibles.")
      )
      
      p <- ggplot2::ggplot(
        d,
        ggplot2::aes(
          x = cagr_nights * 100,
          y = location_quotient_corrected,
          color = growth_group,
          text = paste0(
            "<b>", destination, "</b>",
            "<br>CAGR nuitées : ",
            round(cagr_nights * 100, 2), " %",
            "<br>LQ 2019 : ",
            round(location_quotient_corrected, 2),
            "<br>Classe : ", growth_group
          )
        )
      ) +
        ggplot2::geom_hline(
          yintercept = 1,
          linetype = "dashed",
          color = "grey50"
        ) +
        ggplot2::geom_vline(
          xintercept = stats::median(d$cagr_nights, na.rm = TRUE) * 100,
          linetype = "dashed",
          color = "grey50"
        ) +
        ggplot2::geom_point(
          size = 4,
          alpha = 0.9
        ) +
        ggplot2::geom_text(
          ggplot2::aes(label = destination),
          nudge_y = 0.035,
          size = 3,
          show.legend = FALSE,
          check_overlap = TRUE
        ) +
        ggplot2::scale_color_manual(
          values = c(
            "Leaders dynamiques" = "#087E8B",
            "Marchés émergents" = "#3B82F6",
            "Spécialisés à croissance modérée" = "#D97706",
            "Marchés en retrait relatif" = "#8B95A5"
          )
        ) +
        ggplot2::labs(
          x = "CAGR des nuitées 2012–2019 (%)",
          y = "Location Quotient en 2019",
          color = "Positionnement"
        ) +
        ggplot2::theme_minimal(base_size = 11) +
        ggplot2::theme(
          legend.position = "bottom",
          panel.grid.minor = ggplot2::element_blank()
        )
      
      plotly::ggplotly(
        p,
        tooltip = "text"
      ) |>
        plotly::layout(
          margin = list(l = 60, r = 30, b = 70, t = 20)
        )
    })
    
    
    # --------------------------------------------------------
    # 8. Tableau comparatif
    # --------------------------------------------------------
    
    output$competition_table <- DT::renderDT({
      
      d <- competition_year()
      
      table_data <- d |>
        dplyr::mutate(
          `Nuitées` = format_number(destination_nights),
          `Capacité (lits)` = format_number(capacity_beds),
          `Part demande` = format_percent(demand_share_corrected),
          `Part offre` = format_percent(supply_share_corrected),
          `LQ` = round(location_quotient_corrected, 2)
        ) |>
        dplyr::select(
          Destination = destination,
          Nuitées,
          `Capacité (lits)`,
          `Part demande`,
          `Part offre`,
          LQ
        )
      
      DT::datatable(
        table_data,
        rownames = FALSE,
        extensions = "Buttons",
        options = list(
          dom = "Bfrtip",
          buttons = c("copy", "csv", "excel"),
          pageLength = 12,
          scrollX = TRUE
        )
      )
      
    })
    
  })
}
