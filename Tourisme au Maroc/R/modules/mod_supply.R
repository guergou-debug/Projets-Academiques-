
# ============================================================
# MOROCCO-STAY — MODULE OFFRE D'HEBERGEMENT
# Fichier : R/modules/mod_supply.R
# ============================================================

mod_supply_ui <- function(id) {
  
  ns <- shiny::NS(id)
  
  shiny::tagList(
    
    shiny::fluidRow(
      shiny::column(
        12,
        shiny::div(
          class = "intro-panel",
          shiny::h3("Offre d'hébergement"),
          shiny::p(
            "Analyse de la capacité classée, de sa structure ",
            "par catégorie et de sa répartition territoriale."
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
          ns("category"),
          "Catégorie d'hébergement",
          choices = "Toutes les catégories",
          selected = "Toutes les catégories"
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
        3,
        shiny::uiOutput(ns("kpi_category_capacity"))
      ),
      shiny::column(
        3,
        shiny::uiOutput(ns("kpi_destination_capacity"))
      ),
      shiny::column(
        3,
        shiny::uiOutput(ns("kpi_categories"))
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
          bslib::card_header("Évolution de la capacité par catégorie"),
          plotly::plotlyOutput(ns("category_trend"), height = "380px")
        )
      )
    ),
    
    shiny::fluidRow(
      shiny::column(
        6,
        bslib::card(
          bslib::card_header("Structure de la capacité par catégorie"),
          plotly::plotlyOutput(ns("category_structure"), height = "350px")
        )
      ),
      shiny::column(
        6,
        bslib::card(
          bslib::card_header("Capacité classée par destination"),
          plotly::plotlyOutput(ns("destination_ranking"), height = "350px")
        )
      )
    ),
    
    shiny::fluidRow(
      shiny::column(
        12,
        bslib::card(
          bslib::card_header("Trajectoires de croissance de la capacité — 2012 à 2019"),
          plotly::plotlyOutput(ns("capacity_growth"), height = "350px")
        )
      )
    ),
    
    shiny::fluidRow(
      shiny::column(
        12,
        bslib::card(
          bslib::card_header("Tableau de la capacité par catégorie"),
          DT::DTOutput(ns("category_table"))
        )
      )
    ),
    
    shiny::fluidRow(
      shiny::column(
        12,
        shiny::div(
          class = "method-note",
          shiny::strong("Note méthodologique : "),
          "La capacité est exprimée en lits. Elle ne représente ",
          "ni le nombre d'établissements, ni le nombre de chambres, ",
          "ni le taux d'occupation. Les données par catégorie et ",
          "par destination sont présentées séparément, car leurs ",
          "périmètres ne sont pas nécessairement identiques. ",
          "Le CAGR est calculé sur 2012–2019, hors année 2020."
        )
      )
    )
  )
}


mod_supply_server <- function(id, data) {
  
  shiny::moduleServer(id, function(input, output, session) {
    
    # --------------------------------------------------------
    # 1. Préparation des choix
    # --------------------------------------------------------
    
    categories <- sort(unique(
      data$capacity_category$dimension_label
    ))
    
    destinations <- sort(unique(
      data$capacity_destination$dimension_label
    ))
    
    shiny::observe({
      
      shiny::updateSelectInput(
        session,
        "category",
        choices = c("Toutes les catégories", categories),
        selected = "Toutes les catégories"
      )
      
      shiny::updateSelectInput(
        session,
        "destination",
        choices = c("Toutes les destinations", destinations),
        selected = "Toutes les destinations"
      )
      
    })
    
    
    selected_year <- shiny::reactive({
      as.integer(input$year)
    })
    
    
    # --------------------------------------------------------
    # 2. Fonctions KPI
    # --------------------------------------------------------
    
    make_kpi <- function(label, value, subtitle) {
      
      shiny::div(
        class = "kpi-card",
        shiny::div(class = "kpi-label", label),
        shiny::div(class = "kpi-value", value),
        shiny::div(class = "kpi-subtitle", subtitle)
      )
    }
    
    
    # --------------------------------------------------------
    # 3. KPI
    # --------------------------------------------------------
    
    output$kpi_category_capacity <- shiny::renderUI({
      
      total <- data$capacity_category %>%
        filter(year == selected_year()) %>%
        summarise(total = sum(value, na.rm = TRUE)) %>%
        pull(total)
      
      make_kpi(
        "Capacité par catégorie",
        format_number(total),
        paste("Lits —", selected_year())
      )
    })
    
    
    output$kpi_destination_capacity <- shiny::renderUI({
      
      total <- data$capacity_destination %>%
        filter(year == selected_year()) %>%
        summarise(total = sum(value, na.rm = TRUE)) %>%
        pull(total)
      
      make_kpi(
        "Capacité par destination",
        format_number(total),
        paste("Lits —", selected_year())
      )
    })
    
    
    output$kpi_categories <- shiny::renderUI({
      
      n <- data$capacity_category %>%
        filter(year == selected_year()) %>%
        summarise(n = n_distinct(dimension_label)) %>%
        pull(n)
      
      make_kpi(
        "Catégories",
        as.character(n),
        "Modalités observées"
      )
    })
    
    
    output$kpi_destinations <- shiny::renderUI({
      
      n <- data$capacity_destination %>%
        filter(year == selected_year()) %>%
        summarise(n = n_distinct(dimension_label)) %>%
        pull(n)
      
      make_kpi(
        "Destinations",
        as.character(n),
        "Territoires observés"
      )
    })
    
    
    # --------------------------------------------------------
    # 4. Evolution de la capacité par catégorie
    # --------------------------------------------------------
    
    output$category_trend <- plotly::renderPlotly({
      
      d <- data$capacity_category
      
      if (input$category != "Toutes les catégories") {
        d <- d %>%
          filter(dimension_label == input$category)
      }
      
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
            "<br>Capacité : ", format_number(value), " lits"
          )
        )
      ) +
        ggplot2::geom_line(linewidth = 1.05) +
        ggplot2::geom_point(size = 2) +
        ggplot2::scale_x_continuous(
          breaks = 2012:2020
        ) +
        ggplot2::scale_y_continuous(
          labels = scales::label_number(big.mark = " ")
        ) +
        ggplot2::labs(
          x = NULL,
          y = "Capacité en lits",
          color = "Catégorie"
        ) +
        ggplot2::theme_minimal(base_size = 11) +
        ggplot2::theme(
          legend.position = "bottom",
          panel.grid.minor = ggplot2::element_blank()
        )
      
      plotly::ggplotly(p, tooltip = "text") %>%
        plotly::config(displayModeBar = FALSE)
    })
    
    
    # --------------------------------------------------------
    # 5. Structure de la capacité par catégorie
    # --------------------------------------------------------
    
    output$category_structure <- plotly::renderPlotly({
      
      d <- data$capacity_category %>%
        filter(year == selected_year()) %>%
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
            "<br>Capacité : ", format_number(value), " lits",
            "<br>Part : ",
            format_percent(value / sum(value))
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
          x = "Nombre de lits",
          y = NULL
        ) +
        ggplot2::theme_minimal(base_size = 10)
      
      plotly::ggplotly(p, tooltip = "text") %>%
        plotly::config(displayModeBar = FALSE)
    })
    
    
    # --------------------------------------------------------
    # 6. Capacité par destination
    # --------------------------------------------------------
    
    output$destination_ranking <- plotly::renderPlotly({
      
      d <- data$capacity_destination %>%
        filter(year == selected_year())
      
      if (input$destination != "Toutes les destinations") {
        d <- d %>%
          filter(dimension_label == input$destination)
      }
      
      d <- d %>%
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
            "<br>Capacité : ", format_number(value), " lits"
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
          x = "Nombre de lits",
          y = NULL
        ) +
        ggplot2::theme_minimal(base_size = 10)
      
      plotly::ggplotly(p, tooltip = "text") %>%
        plotly::config(displayModeBar = FALSE)
    })
    
    
    # --------------------------------------------------------
    # 7. Croissance de la capacité par destination
    # --------------------------------------------------------
    
    output$capacity_growth <- plotly::renderPlotly({
      
      d <- data$cagr %>%
        filter(!is.na(cagr_capacity)) %>%
        arrange(cagr_capacity) %>%
        mutate(
          destination = factor(
            destination,
            levels = destination
          )
        )
      
      p <- ggplot2::ggplot(
        d,
        ggplot2::aes(
          x = 100 * cagr_capacity,
          y = destination,
          text = paste0(
            destination,
            "<br>CAGR de la capacité : ",
            format_percent(cagr_capacity),
            "<br>Capacité 2012 : ",
            format_number(capacity_beds_2012),
            "<br>Capacité 2019 : ",
            format_number(capacity_beds_2019)
          )
        )
      ) +
        ggplot2::geom_col(
          fill = "#087E8B",
          width = 0.7
        ) +
        ggplot2::scale_x_continuous(
          labels = function(x) paste0(x, " %")
        ) +
        ggplot2::labs(
          x = "Croissance annuelle composée",
          y = NULL
        ) +
        ggplot2::theme_minimal(base_size = 11)
      
      plotly::ggplotly(p, tooltip = "text") %>%
        plotly::config(displayModeBar = FALSE)
    })
    
    
    # --------------------------------------------------------
    # 8. Tableau détaillé par catégorie
    # --------------------------------------------------------
    
    output$category_table <- DT::renderDT({
      
      d <- data$capacity_category %>%
        filter(year == selected_year()) %>%
        transmute(
          Catégorie = dimension_label,
          Année = year,
          `Capacité (lits)` = value,
          `Part dans la table (%)` =
            round(100 * value / sum(value), 2)
        ) %>%
        arrange(desc(`Capacité (lits)`))
      
      DT::datatable(
        d,
        rownames = FALSE,
        extensions = "Buttons",
        options = list(
          dom = "Bfrtip",
          buttons = c("copy", "csv", "excel"),
          pageLength = 10,
          scrollX = TRUE
        )
      ) %>%
        DT::formatRound(
          columns = "Capacité (lits)",
          digits = 0,
          mark = " "
        )
    })
    
  })
}
