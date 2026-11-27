
# ============================================================
# MODULE 5 : ANALYSE DU CHOC COVID-19
# Projet : MOROCCO-STAY
# Période de comparaison : 2019-2020
# ============================================================


# ------------------------------------------------------------
# A. INTERFACE UTILISATEUR
# ------------------------------------------------------------

mod_covid_ui <- function(id) {
  
  ns <- shiny::NS(id)
  
  shiny::tagList(
    
    # En-tête
    shiny::div(
      class = "mb-4",
      shiny::h2("Impact de la pandémie de Covid-19"),
      shiny::p(
        "Analyse de la rupture de l'activité touristique au Maroc ",
        "entre 2019 et 2020 : demande, destinations et marchés émetteurs.",
        class = "text-muted"
      )
    ),
    
    # Filtres
    bslib::card(
      bslib::card_header("Paramètres d'analyse"),
      bslib::card_body(
        shiny::fluidRow(
          shiny::column(
            width = 6,
            shiny::selectInput(
              ns("destination_filter"),
              "Destination",
              choices = c("Toutes les destinations"),
              selected = "Toutes les destinations"
            )
          ),
          shiny::column(
            width = 6,
            shiny::selectInput(
              ns("market_filter"),
              "Marché international",
              choices = c("Tous les marchés"),
              selected = "Tous les marchés"
            )
          )
        )
      )
    ),
    
    shiny::br(),
    
    # --------------------------------------------------------
    # KPI
    # --------------------------------------------------------
    
    shiny::h4("1. Synthèse de l'impact"),
    
    shiny::fluidRow(
      
      shiny::column(
        width = 3,
        bslib::value_box(
          title = "Nuitées en 2020",
          value = shiny::textOutput(ns("kpi_nights_2020")),
          showcase = shiny::icon("bed"),
          theme = "primary"
        )
      ),
      
      shiny::column(
        width = 3,
        bslib::value_box(
          title = "Variation des nuitées",
          value = shiny::textOutput(ns("kpi_nights_change")),
          showcase = shiny::icon("chart-line"),
          theme = "danger"
        )
      ),
      
      shiny::column(
        width = 3,
        bslib::value_box(
          title = "Variation de la capacité",
          value = shiny::textOutput(ns("kpi_capacity_change")),
          showcase = shiny::icon("hotel"),
          theme = "secondary"
        )
      ),
      
      shiny::column(
        width = 3,
        bslib::value_box(
          title = "Pression sur la capacité en 2020",
          value = shiny::textOutput(ns("kpi_pressure_2020")),
          showcase = shiny::icon("gauge"),
          theme = "info"
        )
      )
    ),
    
    shiny::br(),
    
    # --------------------------------------------------------
    # DEMANDE TOURISTIQUE
    # --------------------------------------------------------
    
    shiny::h4("2. Effondrement de la demande touristique"),
    
    shiny::fluidRow(
      
      shiny::column(
        width = 6,
        bslib::card(
          bslib::card_header("Nuitées par destination : 2019 vs 2020"),
          bslib::card_body(
            plotly::plotlyOutput(
              ns("destination_nights_plot"),
              height = "400px"
            )
          )
        )
      ),
      
      shiny::column(
        width = 6,
        bslib::card(
          bslib::card_header("Évolution de la demande : résidents et non-résidents"),
          bslib::card_body(
            plotly::plotlyOutput(
              ns("market_comparison_plot"),
              height = "400px"
            )
          )
        )
      )
    ),
    
    shiny::br(),
    
    # --------------------------------------------------------
    # DESTINATIONS
    # --------------------------------------------------------
    
    shiny::h4("3. Vulnérabilité des destinations"),
    
    bslib::card(
      bslib::card_header("Classement des destinations selon la baisse des nuitées"),
      bslib::card_body(
        plotly::plotlyOutput(
          ns("destination_impact_plot"),
          height = "450px"
        )
      )
    ),
    
    shiny::br(),
    
    bslib::card(
      bslib::card_header("Évolution de la capacité et de la pression touristique"),
      bslib::card_body(
        plotly::plotlyOutput(
          ns("capacity_pressure_plot"),
          height = "400px"
        )
      )
    ),
    
    shiny::br(),
    
    # --------------------------------------------------------
    # MARCHÉS INTERNATIONAUX
    # --------------------------------------------------------
    
    shiny::h4("4. Vulnérabilité des marchés internationaux"),
    
    bslib::card(
      bslib::card_header("Variation des nuitées par marché émetteur"),
      bslib::card_body(
        plotly::plotlyOutput(
          ns("international_market_plot"),
          height = "450px"
        )
      )
    ),
    
    shiny::br(),
    
    # --------------------------------------------------------
    # TABLEAUX
    # --------------------------------------------------------
    
    shiny::h4("5. Données détaillées"),
    
    bslib::card(
      bslib::card_header("Impact par destination"),
      bslib::card_body(
        DT::DTOutput(ns("destination_table"))
      )
    ),
    
    shiny::br(),
    
    bslib::card(
      bslib::card_header("Impact par marché international"),
      bslib::card_body(
        DT::DTOutput(ns("international_table"))
      )
    ),
    
    shiny::br(),
    
    # --------------------------------------------------------
    # METHODOLOGIE
    # --------------------------------------------------------
    
    bslib::card(
      bslib::card_header("Note méthodologique"),
      bslib::card_body(
        shiny::tags$ul(
          shiny::tags$li(
            "La variation en pourcentage mesure l'évolution entre 2019 et 2020."
          ),
          shiny::tags$li(
            "La pression sur la capacité est un proxy calculé à partir des nuitées et des lits disponibles."
          ),
          shiny::tags$li(
            "Ce proxy n'est pas un taux officiel d'occupation des établissements."
          ),
          shiny::tags$li(
            "Les résultats décrivent une rupture temporelle et ne constituent pas une estimation causale de l'effet de la pandémie."
          ),
          shiny::tags$li(
            "Les marchés internationaux détaillés ne couvrent pas nécessairement l'ensemble de la demande internationale."
          )
        )
      )
    )
  )
}


# ------------------------------------------------------------
# B. SERVEUR
# ------------------------------------------------------------

mod_covid_server <- function(id, data) {
  
  shiny::moduleServer(id, function(input, output, session) {
    
    # --------------------------------------------------------
    # 1. Récupération et sécurisation des données
    # --------------------------------------------------------
    
    covid_destination <- data$covid_destination
    covid_markets <- data$covid_markets
    covid_aggregate <- data$covid_aggregate
    covid_international_markets <- data$covid_international_markets
    
    if (is.null(covid_destination)) {
      stop("La table covid_destination est absente de morocco_data.")
    }
    
    if (is.null(covid_markets)) {
      stop("La table covid_markets est absente de morocco_data.")
    }
    
    if (is.null(covid_aggregate)) {
      stop("La table covid_aggregate est absente de morocco_data.")
    }
    
    if (is.null(covid_international_markets)) {
      stop("La table covid_international_markets est absente de morocco_data.")
    }
    
    # Conversion sécurisée des colonnes numériques
    to_numeric <- function(x) {
      suppressWarnings(as.numeric(as.character(x)))
    }
    
    covid_destination <- as.data.frame(covid_destination)
    covid_markets <- as.data.frame(covid_markets)
    covid_aggregate <- as.data.frame(covid_aggregate)
    covid_international_markets <- as.data.frame(covid_international_markets)
    
    numeric_destination <- intersect(
      c(
        "destination_nights_2019",
        "destination_nights_2020",
        "capacity_beds_2019",
        "capacity_beds_2020",
        "nights_change",
        "nights_change_pct",
        "capacity_change_pct"
      ),
      names(covid_destination)
    )
    
    for (v in numeric_destination) {
      covid_destination[[v]] <- to_numeric(covid_destination[[v]])
    }
    
    numeric_markets <- intersect(
      c(
        "nights_2019",
        "nights_2020",
        "change_absolute",
        "change_pct"
      ),
      names(covid_markets)
    )
    
    for (v in numeric_markets) {
      covid_markets[[v]] <- to_numeric(covid_markets[[v]])
    }
    
    numeric_international <- intersect(
      c(
        "nights_2019",
        "nights_2020",
        "change_absolute",
        "change_pct"
      ),
      names(covid_international_markets)
    )
    
    for (v in numeric_international) {
      covid_international_markets[[v]] <-
        to_numeric(covid_international_markets[[v]])
    }
    
    numeric_aggregate <- intersect(
      c(
        "nights_2019",
        "nights_2020",
        "beds_2019",
        "beds_2020",
        "nights_change_pct",
        "capacity_change_pct",
        "pressure_2019",
        "pressure_2020"
      ),
      names(covid_aggregate)
    )
    
    for (v in numeric_aggregate) {
      covid_aggregate[[v]] <- to_numeric(covid_aggregate[[v]])
    }
    
    
    # --------------------------------------------------------
    # 2. Vérification des colonnes attendues
    # --------------------------------------------------------
    
    required_destination <- c(
      "destination",
      "destination_nights_2019",
      "destination_nights_2020",
      "capacity_beds_2019",
      "capacity_beds_2020",
      "nights_change_pct",
      "capacity_change_pct"
    )
    
    missing_destination <- setdiff(
      required_destination,
      names(covid_destination)
    )
    
    if (length(missing_destination) > 0) {
      stop(
        paste(
          "Colonnes manquantes dans covid_destination :",
          paste(missing_destination, collapse = ", ")
        )
      )
    }
    
    required_market <- c(
      "dimension_label",
      "nights_2019",
      "nights_2020",
      "change_pct"
    )
    
    missing_market <- setdiff(
      required_market,
      names(covid_markets)
    )
    
    if (length(missing_market) > 0) {
      stop(
        paste(
          "Colonnes manquantes dans covid_markets :",
          paste(missing_market, collapse = ", ")
        )
      )
    }
    
    required_international <- c(
      "dimension_label",
      "nights_2019",
      "nights_2020",
      "change_pct"
    )
    
    missing_international <- setdiff(
      required_international,
      names(covid_international_markets)
    )
    
    if (length(missing_international) > 0) {
      stop(
        paste(
          "Colonnes manquantes dans covid_international_markets :",
          paste(missing_international, collapse = ", ")
        )
      )
    }
    
    
    # --------------------------------------------------------
    # 3. Filtres
    # --------------------------------------------------------
    
    shiny::observe({
      
      destinations <- sort(unique(
        stats::na.omit(covid_destination$destination)
      ))
      
      markets <- sort(unique(
        stats::na.omit(covid_international_markets$dimension_label)
      ))
      
      shiny::updateSelectInput(
        session,
        "destination_filter",
        choices = c("Toutes les destinations", destinations),
        selected = "Toutes les destinations"
      )
      
      shiny::updateSelectInput(
        session,
        "market_filter",
        choices = c("Tous les marchés", markets),
        selected = "Tous les marchés"
      )
    })
    
    
    destination_filtered <- shiny::reactive({
      
      d <- covid_destination
      
      if (!is.null(input$destination_filter) &&
          input$destination_filter != "Toutes les destinations") {
        
        d <- d |>
          dplyr::filter(destination == input$destination_filter)
      }
      
      d
    })
    
    
    international_filtered <- shiny::reactive({
      
      d <- covid_international_markets
      
      if (!is.null(input$market_filter) &&
          input$market_filter != "Tous les marchés") {
        
        d <- d |>
          dplyr::filter(dimension_label == input$market_filter)
      }
      
      d
    })
    
    
    # --------------------------------------------------------
    # 4. Fonctions de formatage
    # --------------------------------------------------------
    
    format_number <- function(x) {
      
      if (length(x) == 0 || is.na(x)) {
        return("N/D")
      }
      
      format(
        round(x),
        big.mark = " ",
        scientific = FALSE,
        trim = TRUE
      )
    }
    
    format_pct <- function(x) {
      
      if (length(x) == 0 || is.na(x)) {
        return("N/D")
      }
      
      paste0(
        format(round(x, 1), decimal.mark = ",", nsmall = 1),
        " %"
      )
    }
    
    
    # --------------------------------------------------------
    # 5. Calcul des indicateurs clés
    # --------------------------------------------------------
    
    total_nights_2019 <- sum(
      covid_destination$destination_nights_2019,
      na.rm = TRUE
    )
    
    total_nights_2020 <- sum(
      covid_destination$destination_nights_2020,
      na.rm = TRUE
    )
    
    total_beds_2019 <- sum(
      covid_destination$capacity_beds_2019,
      na.rm = TRUE
    )
    
    total_beds_2020 <- sum(
      covid_destination$capacity_beds_2020,
      na.rm = TRUE
    )
    
    total_nights_change <- if (total_nights_2019 > 0) {
      100 * (total_nights_2020 / total_nights_2019 - 1)
    } else {
      NA_real_
    }
    
    total_capacity_change <- if (total_beds_2019 > 0) {
      100 * (total_beds_2020 / total_beds_2019 - 1)
    } else {
      NA_real_
    }
    
    total_pressure_2020 <- if (total_beds_2020 > 0) {
      100 * total_nights_2020 / (total_beds_2020 * 365)
    } else {
      NA_real_
    }
    
    
    output$kpi_nights_2020 <- shiny::renderText({
      format_number(total_nights_2020)
    })
    
    output$kpi_nights_change <- shiny::renderText({
      format_pct(total_nights_change)
    })
    
    output$kpi_capacity_change <- shiny::renderText({
      format_pct(total_capacity_change)
    })
    
    output$kpi_pressure_2020 <- shiny::renderText({
      format_pct(total_pressure_2020)
    })
    
    
    # --------------------------------------------------------
    # 6. Graphique : nuitées 2019-2020 par destination
    # --------------------------------------------------------
    
    output$destination_nights_plot <- plotly::renderPlotly({
      
      d <- destination_filtered()
      
      shiny::validate(
        shiny::need(nrow(d) > 0, "Aucune destination disponible.")
      )
      
      plotly::plot_ly(
        data = d,
        x = ~destination,
        y = ~destination_nights_2019,
        type = "bar",
        name = "2019",
        marker = list(color = "#23415C"),
        hovertemplate = paste(
          "%{x}",
          "<br>Nuitées 2019 : %{y:,.0f}",
          "<extra></extra>"
        )
      ) |>
        plotly::add_trace(
          y = ~destination_nights_2020,
          name = "2020",
          marker = list(color = "#D95D5D"),
          hovertemplate = paste(
            "%{x}",
            "<br>Nuitées 2020 : %{y:,.0f}",
            "<extra></extra>"
          )
        ) |>
        plotly::layout(
          barmode = "group",
          xaxis = list(title = ""),
          yaxis = list(title = "Nombre de nuitées"),
          legend = list(orientation = "h", x = 0.3, y = 1.15),
          margin = list(b = 100)
        ) |>
        plotly::config(displayModeBar = FALSE)
    })
    
    
    # --------------------------------------------------------
    # 7. Graphique : résidents et non-résidents
    # --------------------------------------------------------
    
    output$market_comparison_plot <- plotly::renderPlotly({
      
      d <- covid_markets
      
      plotly::plot_ly(
        data = d,
        x = ~dimension_label,
        y = ~nights_2019,
        type = "bar",
        name = "2019",
        marker = list(color = "#23415C")
      ) |>
        plotly::add_trace(
          y = ~nights_2020,
          name = "2020",
          marker = list(color = "#D95D5D")
        ) |>
        plotly::layout(
          barmode = "group",
          xaxis = list(title = ""),
          yaxis = list(title = "Nombre de nuitées"),
          legend = list(orientation = "h", x = 0.3, y = 1.15)
        ) |>
        plotly::config(displayModeBar = FALSE)
    })
    
    
    # --------------------------------------------------------
    # 8. Graphique : classement des destinations
    # --------------------------------------------------------
    
    output$destination_impact_plot <- plotly::renderPlotly({
      
      d <- destination_filtered() |>
        dplyr::filter(!is.na(nights_change_pct)) |>
        dplyr::arrange(nights_change_pct)
      
      shiny::validate(
        shiny::need(nrow(d) > 0, "Aucune donnée disponible.")
      )
      
      plotly::plot_ly(
        data = d,
        x = ~nights_change_pct,
        y = ~reorder(destination, nights_change_pct),
        type = "bar",
        orientation = "h",
        marker = list(color = "#D95D5D"),
        hovertemplate = paste(
          "%{y}",
          "<br>Variation : %{x:.1f} %",
          "<extra></extra>"
        )
      ) |>
        plotly::layout(
          xaxis = list(title = "Variation des nuitées (%)"),
          yaxis = list(title = ""),
          margin = list(l = 120)
        ) |>
        plotly::config(displayModeBar = FALSE)
    })
    
    
    # --------------------------------------------------------
    # 9. Graphique : capacité et pression
    # --------------------------------------------------------
    
    output$capacity_pressure_plot <- plotly::renderPlotly({
      
      d <- destination_filtered()
      
      d$pressure_2019 <- 100 * d$destination_nights_2019 /
        (d$capacity_beds_2019 * 365)
      
      d$pressure_2020 <- 100 * d$destination_nights_2020 /
        (d$capacity_beds_2020 * 365)
      
      d$pressure_2019[!is.finite(d$pressure_2019)] <- NA_real_
      d$pressure_2020[!is.finite(d$pressure_2020)] <- NA_real_
      
      plotly::plot_ly(
        data = d,
        x = ~destination,
        y = ~pressure_2019,
        type = "bar",
        name = "Pression 2019",
        marker = list(color = "#087E8B")
      ) |>
        plotly::add_trace(
          y = ~pressure_2020,
          name = "Pression 2020",
          marker = list(color = "#D9A441")
        ) |>
        plotly::layout(
          barmode = "group",
          xaxis = list(title = "", tickangle = -45),
          yaxis = list(title = "Proxy de pression (%)"),
          legend = list(orientation = "h", x = 0.3, y = 1.15),
          margin = list(b = 110)
        ) |>
        plotly::config(displayModeBar = FALSE)
    })
    
    
    # --------------------------------------------------------
    # 10. Graphique : marchés internationaux
    # --------------------------------------------------------
    
    output$international_market_plot <- plotly::renderPlotly({
      
      d <- international_filtered() |>
        dplyr::filter(!is.na(change_pct)) |>
        dplyr::arrange(change_pct)
      
      shiny::validate(
        shiny::need(nrow(d) > 0, "Aucun marché disponible.")
      )
      
      plotly::plot_ly(
        data = d,
        x = ~change_pct,
        y = ~reorder(dimension_label, change_pct),
        type = "bar",
        orientation = "h",
        marker = list(color = "#D95D5D"),
        hovertemplate = paste(
          "%{y}",
          "<br>Variation : %{x:.1f} %",
          "<extra></extra>"
        )
      ) |>
        plotly::layout(
          xaxis = list(title = "Variation des nuitées (%)"),
          yaxis = list(title = ""),
          margin = list(l = 140)
        ) |>
        plotly::config(displayModeBar = FALSE)
    })
    
    
    # --------------------------------------------------------
    # 11. Tableau : destinations
    # --------------------------------------------------------
    
    output$destination_table <- DT::renderDT({
      
      d <- destination_filtered() |>
        dplyr::select(
          destination,
          destination_nights_2019,
          destination_nights_2020,
          nights_change_pct,
          capacity_beds_2019,
          capacity_beds_2020,
          capacity_change_pct
        )
      
      DT::datatable(
        d,
        rownames = FALSE,
        colnames = c(
          "Destination",
          "Nuitées 2019",
          "Nuitées 2020",
          "Variation nuitées (%)",
          "Lits 2019",
          "Lits 2020",
          "Variation capacité (%)"
        ),
        extensions = "Buttons",
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          dom = "Bfrtip",
          buttons = c("copy", "csv", "excel")
        )
      ) |>
        DT::formatRound(
          columns = c(
            "destination_nights_2019",
            "destination_nights_2020",
            "capacity_beds_2019",
            "capacity_beds_2020"
          ),
          digits = 0,
          mark = " "
        ) |>
        DT::formatRound(
          columns = c("nights_change_pct", "capacity_change_pct"),
          digits = 1
        )
      
    }, server = TRUE)
    
    
    # --------------------------------------------------------
    # 12. Tableau : marchés internationaux
    # --------------------------------------------------------
    
    output$international_table <- DT::renderDT({
      
      d <- international_filtered() |>
        dplyr::select(
          dimension_label,
          nights_2019,
          nights_2020,
          change_absolute,
          change_pct
        )
      
      DT::datatable(
        d,
        rownames = FALSE,
        colnames = c(
          "Marché émetteur",
          "Nuitées 2019",
          "Nuitées 2020",
          "Variation absolue",
          "Variation (%)"
        ),
        extensions = "Buttons",
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          dom = "Bfrtip",
          buttons = c("copy", "csv", "excel")
        )
      ) |>
        DT::formatRound(
          columns = c(
            "nights_2019",
            "nights_2020",
            "change_absolute"
          ),
          digits = 0,
          mark = " "
        ) |>
        DT::formatRound(
          columns = "change_pct",
          digits = 1
        )
      
    }, server = TRUE)
    
  })
}
