
# ============================================================
# MODULE 6 : EXPLORATEUR DE DONNEES
# Projet : MOROCCO-STAY
# Version : Diagnostic fonctionnel
# ============================================================


# ------------------------------------------------------------
# A. INTERFACE UTILISATEUR
# ------------------------------------------------------------

mod_explorer_ui <- function(id) {
  
  ns <- shiny::NS(id)
  
  shiny::tagList(
    
    shiny::h2("Explorateur de données"),
    
    shiny::p(
      "Consultez, filtrez, analysez et exportez les différentes ",
      "bases de données du projet MOROCCO-STAY.",
      class = "text-muted"
    ),
    
    shiny::br(),
    
    # 1. Sélection de la base
    bslib::card(
      bslib::card_header("1. Sélection de la base"),
      bslib::card_body(
        shiny::selectInput(
          ns("table_selected"),
          "Choisir une table",
          choices = NULL,
          width = "100%"
        )
      )
    ),
    
    shiny::br(),
    
    # 2. Indicateurs clés
    shiny::fluidRow(
      
      shiny::column(
        4,
        bslib::value_box(
          title = "Observations",
          value = shiny::textOutput(ns("n_rows")),
          showcase = shiny::icon("list")
        )
      ),
      
      shiny::column(
        4,
        bslib::value_box(
          title = "Variables",
          value = shiny::textOutput(ns("n_cols")),
          showcase = shiny::icon("columns")
        )
      ),
      
      shiny::column(
        4,
        bslib::value_box(
          title = "Valeurs manquantes",
          value = shiny::textOutput(ns("missing_pct")),
          showcase = shiny::icon("circle-exclamation")
        )
      )
    ),
    
    shiny::br(),
    
    # 3. Structure de la base
    bslib::card(
      bslib::card_header("2. Structure de la base"),
      bslib::card_body(
        shiny::uiOutput(ns("table_description")),
        DT::DTOutput(ns("structure_table"))
      )
    ),
    
    shiny::br(),
    
    # 4. Recherche et filtrage
    bslib::card(
      bslib::card_header("3. Recherche et filtrage"),
      bslib::card_body(
        
        shiny::fluidRow(
          
          shiny::column(
            6,
            shiny::selectInput(
              ns("filter_variable"),
              "Variable à filtrer",
              choices = "Aucun filtre"
            )
          ),
          
          shiny::column(
            6,
            shiny::textInput(
              ns("filter_value"),
              "Valeur ou modalité recherchée",
              placeholder = "Saisir une valeur..."
            )
          )
        ),
        
        shiny::sliderInput(
          ns("numeric_filter"),
          "Intervalle de valeurs numériques",
          min = 0,
          max = 1,
          value = c(0, 1)
        ),
        
        shiny::fluidRow(
          
          shiny::column(
            8,
            shiny::textInput(
              ns("search_text"),
              "Recherche globale dans les observations",
              placeholder = "Rechercher dans toutes les colonnes..."
            )
          ),
          
          shiny::column(
            4,
            shiny::br(),
            shiny::actionButton(
              ns("reset_filters"),
              "Réinitialiser",
              icon = shiny::icon("rotate-left"),
              class = "btn-outline-secondary"
            )
          )
        )
      )
    ),
    
    shiny::br(),
    
    # 5. Tableau des observations
    bslib::card(
      bslib::card_header("4. Tableau des observations"),
      bslib::card_body(
        shiny::textOutput(ns("filtered_count")),
        DT::DTOutput(ns("data_table"))
      )
    ),
    
    shiny::br(),
    
    # 6. Statistiques descriptives
    bslib::card(
      bslib::card_header("5. Statistiques descriptives"),
      bslib::card_body(
        
        shiny::selectInput(
          ns("stat_variable"),
          "Variable numérique",
          choices = NULL
        ),
        
        shiny::uiOutput(ns("numeric_summary")),
        
        plotly::plotlyOutput(
          ns("distribution_plot"),
          height = "350px"
        )
      )
    ),
    
    shiny::br(),
    
    # 7. Exportation
    bslib::card(
      bslib::card_header("6. Exportation"),
      bslib::card_body(
        shiny::p(
          "Téléchargez les observations après application des filtres."
        ),
        
        shiny::downloadButton(
          ns("download_csv"),
          "Télécharger les données CSV",
          icon = shiny::icon("download"),
          class = "btn-primary"
        )
      )
    )
  )
}


# ------------------------------------------------------------
# B. SERVEUR
# ------------------------------------------------------------

mod_explorer_server <- function(id, data) {
  
  shiny::moduleServer(id, function(input, output, session) {
    
    # --------------------------------------------------------
    # 1. Identification des tables disponibles
    # --------------------------------------------------------
    
    available_tables <- names(data)[
      vapply(
        data,
        function(x) {
          is.data.frame(x) || tibble::is_tibble(x)
        },
        logical(1)
      )
    ]
    
    if (length(available_tables) == 0) {
      stop("Aucune table exploitable dans morocco_data.")
    }
    
    
    # --------------------------------------------------------
    # 2. Initialisation du sélecteur
    # --------------------------------------------------------
    
    shiny::observe({
      
      shiny::updateSelectInput(
        session,
        "table_selected",
        choices = available_tables,
        selected = available_tables[1]
      )
      
    }, priority = 100)
    
    
    # --------------------------------------------------------
    # 3. Récupération de la table sélectionnée
    # --------------------------------------------------------
    
    selected_data <- shiny::reactive({
      
      shiny::req(input$table_selected)
      
      shiny::req(
        input$table_selected %in% available_tables
      )
      
      as.data.frame(
        data[[input$table_selected]]
      )
      
    })
    
    
    # --------------------------------------------------------
    # 4. Indicateurs clés
    # --------------------------------------------------------
    
    output$n_rows <- shiny::renderText({
      
      format(
        nrow(selected_data()),
        big.mark = " "
      )
      
    })
    
    output$n_cols <- shiny::renderText({
      
      ncol(selected_data())
      
    })
    
    output$missing_pct <- shiny::renderText({
      
      d <- selected_data()
      
      total <- length(d)
      
      if (total == 0) {
        return("0 %")
      }
      
      paste0(
        round(
          mean(is.na(d)) * 100,
          1
        ),
        " %"
      )
      
    })
    
    
    # --------------------------------------------------------
    # 5. Description de la table
    # --------------------------------------------------------
    
    output$table_description <- shiny::renderUI({
      
      d <- selected_data()
      
      shiny::tagList(
        
        shiny::p(
          shiny::strong("Table : "),
          input$table_selected
        ),
        
        shiny::p(
          shiny::strong("Dimensions : "),
          format(nrow(d), big.mark = " "),
          " lignes × ",
          ncol(d),
          " colonnes"
        ),
        
        shiny::p(
          shiny::strong("Taille mémoire : "),
          format(
            utils::object.size(d),
            units = "auto"
          )
        )
        
      )
      
    })
    
    
    # --------------------------------------------------------
    # 6. Structure des variables
    # --------------------------------------------------------
    
    output$structure_table <- DT::renderDT({
      
      d <- selected_data()
      
      structure <- data.frame(
        
        Variable = names(d),
        
        Type = vapply(
          d,
          function(x) {
            paste(class(x), collapse = ", ")
          },
          character(1)
        ),
        
        Manquants = vapply(
          d,
          function(x) {
            as.integer(sum(is.na(x)))
          },
          integer(1)
        ),
        
        Taux_manquant_pct = vapply(
          d,
          function(x) {
            round(mean(is.na(x)) * 100, 1)
          },
          numeric(1)
        ),
        
        check.names = FALSE
      )
      
      DT::datatable(
        structure,
        rownames = FALSE,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          searching = TRUE
        )
      )
      
    })
    
    
    # --------------------------------------------------------
    # 7. Tableau principal des observations
    # --------------------------------------------------------
    
    output$filtered_count <- shiny::renderText({
      
      paste(
        format(
          nrow(selected_data()),
          big.mark = " "
        ),
        "observations disponibles"
      )
      
    })
    
    
    output$data_table <- DT::renderDT({
      
      d <- selected_data()
      
      DT::datatable(
        d,
        rownames = FALSE,
        options = list(
          pageLength = 15,
          scrollX = TRUE,
          autoWidth = TRUE
        )
      )
      
    })
    
    
    # --------------------------------------------------------
    # 8. Préparation des variables numériques
    # --------------------------------------------------------
    
    numeric_variables <- shiny::reactive({
      
      d <- selected_data()
      
      names(d)[
        vapply(d, is.numeric, logical(1))
      ]
      
    })
    
    
    # --------------------------------------------------------
    # 9. Mise à jour du sélecteur statistique
    # --------------------------------------------------------
    
    shiny::observe({
      
      vars <- numeric_variables()
      
      shiny::updateSelectInput(
        session,
        "stat_variable",
        choices = vars,
        selected = if (length(vars) > 0) {
          vars[1]
        } else {
          character(0)
        }
      )
      
    })
    
    
    # --------------------------------------------------------
    # 10. Statistiques descriptives
    # --------------------------------------------------------
    
    numeric_values <- shiny::reactive({
      
      d <- selected_data()
      
      variable <- input$stat_variable
      
      if (
        is.null(variable) ||
        !variable %in% names(d) ||
        !is.numeric(d[[variable]])
      ) {
        return(numeric(0))
      }
      
      x <- d[[variable]]
      
      x[is.finite(x)]
      
    })
    
    
    output$numeric_summary <- shiny::renderUI({
      
      x <- numeric_values()
      
      if (length(x) == 0) {
        
        return(
          shiny::p(
            "Aucune observation numérique disponible.",
            class = "text-muted"
          )
        )
        
      }
      
      shiny::fluidRow(
        
        shiny::column(
          3,
          shiny::wellPanel(
            "Moyenne",
            shiny::h4(round(mean(x), 2))
          )
        ),
        
        shiny::column(
          3,
          shiny::wellPanel(
            "Médiane",
            shiny::h4(round(stats::median(x), 2))
          )
        ),
        
        shiny::column(
          3,
          shiny::wellPanel(
            "Minimum",
            shiny::h4(round(min(x), 2))
          )
        ),
        
        shiny::column(
          3,
          shiny::wellPanel(
            "Maximum",
            shiny::h4(round(max(x), 2))
          )
        )
        
      )
      
    })
    
    
    # --------------------------------------------------------
    # 11. Distribution graphique
    # --------------------------------------------------------
    
    output$distribution_plot <- plotly::renderPlotly({
      
      x <- numeric_values()
      
      shiny::validate(
        shiny::need(
          length(x) > 0,
          "Sélectionnez une variable numérique exploitable."
        )
      )
      
      plotly::plot_ly(
        x = x,
        type = "histogram",
        nbinsx = 30,
        marker = list(
          color = "#087E8B"
        )
      ) |>
        
        plotly::layout(
          xaxis = list(
            title = input$stat_variable
          ),
          yaxis = list(
            title = "Effectif"
          ),
          bargap = 0.08
        ) |>
        
        plotly::config(
          displayModeBar = FALSE
        )
      
    })
    
    
    # --------------------------------------------------------
    # 12. Export CSV
    # --------------------------------------------------------
    
    output$download_csv <- shiny::downloadHandler(
      
      filename = function() {
        
        paste0(
          input$table_selected,
          "_export_",
          Sys.Date(),
          ".csv"
        )
        
      },
      
      content = function(file) {
        
        readr::write_excel_csv(
          selected_data(),
          file,
          na = ""
        )
        
      }
      
    )
    
  })
}

# ============================================================
# FIN DU MODULE 6
# ============================================================
