
# ============================================================
# MOROCCO-STAY — MODULE DEMANDE TOURISTIQUE
# Fichier : R/modules/mod_demand.R
# ============================================================

mod_demand_ui <- function(id) {
  
  ns <- shiny::NS(id)
  
  shiny::tagList(
    
    shiny::fluidRow(
      shiny::column(
        12,
        shiny::div(
          class = "intro-panel",
          shiny::h3("Demande touristique"),
          shiny::p(
            "Analyse des nuitées, des marchés émetteurs ",
            "et des arrivées aux frontières."
          )
        )
      )
    ),
    
    shiny::fluidRow(
      shiny::column(
        4,
        shiny::selectInput(
          ns("year"),
          "Année d'observation",
          choices = 2012:2020,
          selected = 2019
        )
      ),
      shiny::column(
        4,
        shiny::selectInput(
          ns("destination"),
          "Destination",
          choices = "Toutes les destinations",
          selected = "Toutes les destinations"
        )
      )
    ),
    
    shiny::fluidRow(
      shiny::column(
        6,
        bslib::card(
          bslib::card_header("Nuitées par destination"),
          plotly::plotlyOutput(ns("destination_ranking"), height = "360px")
        )
      ),
      shiny::column(
        6,
        bslib::card(
          bslib::card_header("Évolution des nuitées par destination"),
          plotly::plotlyOutput(ns("destination_trend"), height = "360px")
        )
      )
    ),
    
    shiny::fluidRow(
      shiny::column(
        6,
        bslib::card(
          bslib::card_header("Demande domestique et internationale"),
          plotly::plotlyOutput(ns("aggregate_trend"), height = "340px")
        )
      ),
      shiny::column(
        6,
        bslib::card(
          bslib::card_header("Principaux marchés internationaux — 2019"),
          plotly::plotlyOutput(ns("international_ranking"), height = "340px")
        )
      )
    ),
    
    shiny::fluidRow(
      shiny::column(
        6,
        bslib::card(
          bslib::card_header("Arrivées : agrégats de nationalité"),
          plotly::plotlyOutput(ns("nationality_trend"), height = "320px")
        )
      ),
      shiny::column(
        6,
        bslib::card(
          bslib::card_header("Arrivées par mode de transport"),
          plotly::plotlyOutput(ns("entry_mode"), height = "320px")
        )
      )
    ),
    
    shiny::fluidRow(
      shiny::column(
        12,
        bslib::card(
          bslib::card_header("Données détaillées des marchés internationaux — 2019"),
          DT::DTOutput(ns("international_table"))
        )
      )
    ),
    
    shiny::fluidRow(
      shiny::column(
        12,
        shiny::div(
          class = "method-note",
          shiny::strong("Précautions d'interprétation : "),
          "Les agrégats Résidents et Non résidents ne doivent pas ",
          "être additionnés aux marchés géographiques détaillés. ",
          "Les arrivées aux frontières ne sont pas équivalentes ",
          "aux nuitées hôtelières. Les marchés internationaux détaillés ",
          "ne couvrent qu'une partie du total des non-résidents."
        )
      )
    )
  )
}


mod_demand_server <- function(id, data) {
  
  shiny::moduleServer(id, function(input, output, session) {
    
    # --------------------------------------------------------
    # 1. Initialisation des destinations
    # --------------------------------------------------------
    
    destinations <- sort(unique(
      data$panel_destination$destination
    ))
    
    shiny::observe({
      shiny::updateSelectInput(
        session,
        "destination",
        choices = c(
          "Toutes les destinations",
          destinations
        ),
        selected = "Toutes les destinations"
      )
    })
    
    selected_year <- shiny::reactive({
      as.integer(input$year)
    })
    
    selected_destination <- shiny::reactive({
      input$destination
    })
    
    
    # --------------------------------------------------------
    # 2. Classement des destinations
    # --------------------------------------------------------
    
    output$destination_ranking <- plotly::renderPlotly({
      
      d <- data$panel_destination %>%
        filter(
          year == selected_year(),
          !is.na(destination_nights)
        ) %>%
        arrange(destination_nights) %>%
        mutate(
          destination = factor(
            destination,
            levels = destination
          )
        )
      
      p <- ggplot2::ggplot(
        d,
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
          x = "Nuitées",
          y = NULL
        ) +
        ggplot2::theme_minimal(base_size = 11)
      
      plotly::ggplotly(p, tooltip = "text") %>%
        plotly::config(displayModeBar = FALSE)
    })
    
    
    # --------------------------------------------------------
    # 3. Evolution des nuitées
    # --------------------------------------------------------
    
    output$destination_trend <- plotly::renderPlotly({
      
      d <- data$panel_destination %>%
        filter(!is.na(destination_nights))
      
      if (selected_destination() != "Toutes les destinations") {
        d <- d %>%
          filter(destination == selected_destination())
      }
      
      if (selected_destination() == "Toutes les destinations") {
        
        d <- d %>%
          group_by(year) %>%
          summarise(
            nights = sum(destination_nights, na.rm = TRUE),
            .groups = "drop"
          )
        
        p <- ggplot2::ggplot(
          d,
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
            color = "#087E8B",
            linewidth = 1.2
          ) +
          ggplot2::geom_point(
            color = "#087E8B",
            size = 2.5
          ) +
          ggplot2::labs(
            x = NULL,
            y = "Nuitées"
          )
        
      } else {
        
        p <- ggplot2::ggplot(
          d,
          ggplot2::aes(
            x = year,
            y = destination_nights,
            text = paste0(
              destination,
              "<br>Année : ", year,
              "<br>Nuitées : ",
              format_number(destination_nights)
            )
          )
        ) +
          ggplot2::geom_line(
            color = "#087E8B",
            linewidth = 1.2
          ) +
          ggplot2::geom_point(
            color = "#087E8B",
            size = 2.5
          ) +
          ggplot2::labs(
            x = NULL,
            y = "Nuitées"
          )
      }
      
      p <- p +
        ggplot2::scale_x_continuous(
          breaks = 2012:2020
        ) +
        ggplot2::theme_minimal(base_size = 11)
      
      plotly::ggplotly(p, tooltip = "text") %>%
        plotly::config(displayModeBar = FALSE)
    })
    
    
    # --------------------------------------------------------
    # 4. Demande résidente et non résidente
    # --------------------------------------------------------
    
    output$aggregate_trend <- plotly::renderPlotly({
      
      d <- data$market_aggregates %>%
        filter(
          dimension_label %in% c(
            "Résidents",
            "Non résidents"
          )
        )
      
      p <- ggplot2::ggplot(
        d,
        ggplot2::aes(
          x = year,
          y = value,
          color = dimension_label,
          group = dimension_label,
          text = paste0(
            dimension_label,
            "<br>Année : ", year,
            "<br>Nuitées : ", format_number(value)
          )
        )
      ) +
        ggplot2::geom_line(linewidth = 1.1) +
        ggplot2::geom_point(size = 2) +
        ggplot2::scale_color_manual(
          values = c(
            "Résidents" = "#087E8B",
            "Non résidents" = "#23415C"
          )
        ) +
        ggplot2::scale_y_continuous(
          labels = scales::label_number(big.mark = " ")
        ) +
        ggplot2::scale_x_continuous(
          breaks = 2012:2020
        ) +
        ggplot2::labs(
          x = NULL,
          y = "Nuitées",
          color = NULL
        ) +
        ggplot2::theme_minimal(base_size = 11)
      
      plotly::ggplotly(p, tooltip = "text") %>%
        plotly::config(displayModeBar = FALSE)
    })
    
    
    # --------------------------------------------------------
    # 5. Marchés internationaux détaillés
    # --------------------------------------------------------
    
    output$international_ranking <- plotly::renderPlotly({
      
      d <- data$international_markets %>%
        filter(year == 2019) %>%
        arrange(value) %>%
        mutate(
          dimension_label = factor(
            dimension_label,
            levels = dimension_label
          )
        )
      
      p <- ggplot2::ggplot(
        d,
        ggplot2::aes(
          x = value,
          y = dimension_label,
          text = paste0(
            dimension_label,
            "<br>Nuitées : ", format_number(value),
            "<br>Part des marchés détaillés : ",
            format_percent(share_detailed)
          )
        )
      ) +
        ggplot2::geom_col(
          fill = "#23415C",
          width = 0.7
        ) +
        ggplot2::scale_x_continuous(
          labels = scales::label_number(big.mark = " ")
        ) +
        ggplot2::labs(
          x = "Nuitées en 2019",
          y = NULL
        ) +
        ggplot2::theme_minimal(base_size = 11)
      
      plotly::ggplotly(p, tooltip = "text") %>%
        plotly::config(displayModeBar = FALSE)
    })
    
    
    # --------------------------------------------------------
    # 6. Arrivées par agrégats de nationalité
    # --------------------------------------------------------
    
    output$nationality_trend <- plotly::renderPlotly({
      
      d <- data$arrivals_nationality %>%
        filter(
          dimension_label %in% c(
            "Touristes Etrangers",
            "MRE"
          )
        )
      
      p <- ggplot2::ggplot(
        d,
        ggplot2::aes(
          x = year,
          y = value,
          color = dimension_label,
          group = dimension_label,
          text = paste0(
            dimension_label,
            "<br>Année : ", year,
            "<br>Arrivées : ", format_number(value)
          )
        )
      ) +
        ggplot2::geom_line(linewidth = 1.1) +
        ggplot2::geom_point(size = 2) +
        ggplot2::scale_y_continuous(
          labels = scales::label_number(big.mark = " ")
        ) +
        ggplot2::scale_x_continuous(
          breaks = 2012:2020
        ) +
        ggplot2::labs(
          x = NULL,
          y = "Arrivées",
          color = NULL
        ) +
        ggplot2::theme_minimal(base_size = 11)
      
      plotly::ggplotly(p, tooltip = "text") %>%
        plotly::config(displayModeBar = FALSE)
    })
    
    
    # --------------------------------------------------------
    # 7. Arrivées par mode de transport
    # --------------------------------------------------------
    
    output$entry_mode <- plotly::renderPlotly({
      
      d <- data$arrivals_entry_point %>%
        filter(
          dimension_label %in% c(
            "T.AIR",
            "T.MER",
            "T.TERRE"
          )
        )
      
      p <- ggplot2::ggplot(
        d,
        ggplot2::aes(
          x = year,
          y = value,
          color = dimension_label,
          group = dimension_label,
          text = paste0(
            "Mode : ", dimension_label,
            "<br>Année : ", year,
            "<br>Arrivées : ", format_number(value)
          )
        )
      ) +
        ggplot2::geom_line(linewidth = 1.1) +
        ggplot2::geom_point(size = 2) +
        ggplot2::scale_y_continuous(
          labels = scales::label_number(big.mark = " ")
        ) +
        ggplot2::scale_x_continuous(
          breaks = 2012:2020
        ) +
        ggplot2::labs(
          x = NULL,
          y = "Arrivées",
          color = "Mode"
        ) +
        ggplot2::theme_minimal(base_size = 11)
      
      plotly::ggplotly(p, tooltip = "text") %>%
        plotly::config(displayModeBar = FALSE)
    })
    
    
    # --------------------------------------------------------
    # 8. Tableau des marchés internationaux
    # --------------------------------------------------------
    
    output$international_table <- DT::renderDT({
      
      d <- data$international_markets %>%
        filter(year == 2019) %>%
        transmute(
          Marché = dimension_label,
          Année = year,
          Nuitées = value,
          `Part des marchés détaillés (%)` =
            round(100 * share_detailed, 2)
        ) %>%
        arrange(desc(Nuitées))
      
      DT::datatable(
        d,
        rownames = FALSE,
        extensions = "Buttons",
        options = list(
          dom = "Bfrtip",
          buttons = c("copy", "csv", "excel"),
          pageLength = 11,
          scrollX = TRUE
        )
      ) %>%
        DT::formatRound(
          columns = c("Nuitées"),
          digits = 0,
          mark = " "
        )
    })
    
  })
}
