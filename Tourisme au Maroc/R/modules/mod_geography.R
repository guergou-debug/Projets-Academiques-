
# ============================================================
# MODULE : GEOGRAPHIE TOURISTIQUE
# Projet : MOROCCO-STAY
# Source : OpenStreetMap
# ============================================================

mod_geography_ui <- function(id) {
  
  ns <- shiny::NS(id)
  
  shiny::tagList(
    
    shiny::fluidRow(
      shiny::column(
        width = 12,
        shiny::div(
          class = "section-intro",
          shiny::h3("Géographie touristique"),
          shiny::p(
            "Exploration spatiale des hébergements recensés dans OpenStreetMap ",
            "à Marrakech, Casablanca, Agadir et Tanger."
          )
        )
      )
    ),
    
    # Filtres
    shiny::fluidRow(
      shiny::column(
        width = 6,
        shiny::selectInput(
          ns("city"),
          "Ville",
          choices = "Toutes les villes",
          selected = "Toutes les villes"
        )
      ),
      shiny::column(
        width = 6,
        shiny::selectInput(
          ns("type"),
          "Type d'hébergement",
          choices = "Tous les types",
          selected = "Tous les types"
        )
      )
    ),
    
    # KPI
    shiny::fluidRow(
      shiny::column(3, shiny::uiOutput(ns("kpi_objects"))),
      shiny::column(3, shiny::uiOutput(ns("kpi_cities"))),
      shiny::column(3, shiny::uiOutput(ns("kpi_named"))),
      shiny::column(3, shiny::uiOutput(ns("kpi_types")))
    ),
    
    shiny::hr(),
    
    shiny::h4("1. Répartition spatiale des hébergements"),
    
    shiny::p(
      "Chaque point représente un objet géographique recensé dans OpenStreetMap. ",
      "Les couleurs distinguent les catégories d'hébergement. ",
      "Clique sur un point pour consulter ses informations."
    ),
    
    shiny::div(
      style = "width:100%; height:650px; display:block;",
      leaflet::leafletOutput(
        ns("osm_map"),
        height = "650px",
        width = "100%"
      )
    ),
    
    shiny::hr(),
    
    shiny::h4("2. Structure de la couverture OSM"),
    
    shiny::fluidRow(
      shiny::column(
        6,
        shiny::h5("Objets recensés par ville"),
        plotly::plotlyOutput(ns("city_chart"), height = "350px")
      ),
      shiny::column(
        6,
        shiny::h5("Objets recensés par type"),
        plotly::plotlyOutput(ns("type_chart"), height = "350px")
      )
    ),
    
    shiny::hr(),
    
    shiny::h4("3. Inventaire des objets géographiques"),
    
    DT::DTOutput(ns("osm_table")),
    
    shiny::br(),
    
    shiny::div(
      class = "method-note",
      shiny::strong("Limites de la source : "),
      "les données OpenStreetMap sont contributives et leur couverture varie ",
      "selon les territoires. Les objets recensés ne correspondent pas nécessairement ",
      "à des établissements actifs ou distincts. Les informations manquantes, ",
      "notamment les étoiles, chambres et lits, ne sont pas imputées. ",
      "Cette base ne permet pas de mesurer l'offre totale d'hébergement au Maroc."
    )
  )
}


# ============================================================
# SERVEUR
# ============================================================

mod_geography_server <- function(id, data) {
  
  shiny::moduleServer(id, function(input, output, session) {
    
    # --------------------------------------------------------
    # 1. Préparation et contrôle des données OSM
    # --------------------------------------------------------
    
    osm_data <- shiny::reactive({
      
      d <- data$osm
      
      required_cols <- c(
        "city", "name", "tourism_type",
        "latitude", "longitude"
      )
      
      missing_cols <- setdiff(required_cols, names(d))
      
      if (length(missing_cols) > 0) {
        stop(
          paste(
            "Colonnes absentes de la table OSM :",
            paste(missing_cols, collapse = ", ")
          )
        )
      }
      
      d <- d |>
        dplyr::mutate(
          city = as.character(city),
          name = as.character(name),
          tourism_type = as.character(tourism_type),
          latitude = suppressWarnings(as.numeric(latitude)),
          longitude = suppressWarnings(as.numeric(longitude))
        ) |>
        dplyr::filter(
          !is.na(latitude),
          !is.na(longitude),
          dplyr::between(latitude, 20, 37),
          dplyr::between(longitude, -18, 0)
        ) |>
        dplyr::mutate(
          tourism_type_display = dplyr::if_else(
            is.na(tourism_type) | trimws(tourism_type) == "",
            "Type non renseigné",
            tourism_type
          ),
          city = dplyr::if_else(
            is.na(city) | trimws(city) == "",
            "Ville non renseignée",
            city
          )
        )
      
      d
      
    })
    
    
    # --------------------------------------------------------
    # 2. Mise à jour des filtres
    # --------------------------------------------------------
    
    shiny::observe({
      
      d <- osm_data()
      
      cities <- sort(unique(d$city))
      types <- sort(unique(d$tourism_type_display))
      
      shiny::updateSelectInput(
        session,
        "city",
        choices = c("Toutes les villes", cities),
        selected = "Toutes les villes"
      )
      
      shiny::updateSelectInput(
        session,
        "type",
        choices = c("Tous les types", types),
        selected = "Tous les types"
      )
      
    })
    
    
    # --------------------------------------------------------
    # 3. Application des filtres
    # --------------------------------------------------------
    
    osm_filtered <- shiny::reactive({
      
      d <- osm_data()
      
      if (
        !is.null(input$city) &&
        input$city != "Toutes les villes"
      ) {
        d <- d |>
          dplyr::filter(city == input$city)
      }
      
      if (
        !is.null(input$type) &&
        input$type != "Tous les types"
      ) {
        d <- d |>
          dplyr::filter(tourism_type_display == input$type)
      }
      
      d
      
    })
    
    
    # --------------------------------------------------------
    # 4. KPI
    # --------------------------------------------------------
    
    output$kpi_objects <- shiny::renderUI({
      
      n <- nrow(osm_filtered())
      
      shiny::div(
        class = "kpi-card",
        shiny::div(class = "kpi-label", "Objets recensés"),
        shiny::div(class = "kpi-value", format_number(n)),
        shiny::div(class = "kpi-subtitle", "Après application des filtres")
      )
      
    })
    
    
    output$kpi_cities <- shiny::renderUI({
      
      d <- osm_filtered()
      n <- dplyr::n_distinct(d$city)
      
      shiny::div(
        class = "kpi-card",
        shiny::div(class = "kpi-label", "Villes couvertes"),
        shiny::div(class = "kpi-value", n),
        shiny::div(class = "kpi-subtitle", "Dans la sélection")
      )
      
    })
    
    
    output$kpi_named <- shiny::renderUI({
      
      d <- osm_filtered()
      
      n <- if (nrow(d) > 0) {
        mean(!is.na(d$name) & trimws(d$name) != "") * 100
      } else {
        NA_real_
      }
      
      shiny::div(
        class = "kpi-card",
        shiny::div(class = "kpi-label", "Objets nommés"),
        shiny::div(
          class = "kpi-value",
          ifelse(is.na(n), "—", paste0(round(n, 1), " %"))
        ),
        shiny::div(class = "kpi-subtitle", "Part avec un nom renseigné")
      )
      
    })
    
    
    output$kpi_types <- shiny::renderUI({
      
      d <- osm_filtered()
      n <- dplyr::n_distinct(d$tourism_type_display)
      
      shiny::div(
        class = "kpi-card",
        shiny::div(class = "kpi-label", "Types représentés"),
        shiny::div(class = "kpi-value", n),
        shiny::div(class = "kpi-subtitle", "Catégories OSM distinctes")
      )
      
    })
    
    
    output$osm_map <- leaflet::renderLeaflet({
      
      d <- osm_filtered()
      
      validate(
        shiny::need(
          nrow(d) > 0,
          "Aucun point disponible"
        )
      )
      
      leaflet::leaflet(d) |>
        leaflet::addProviderTiles(
          leaflet::providers$OpenStreetMap
        ) |>
        leaflet::addCircleMarkers(
          lng = ~longitude,
          lat = ~latitude,
          radius = 5,
          color = "#087E8B",
          fillOpacity = 0.8,
          popup = ~paste0(
            "<b>", name, "</b><br>",
            city, "<br>",
            tourism_type
          )
        ) |>
        leaflet::fitBounds(
          lng1 = min(d$longitude),
          lat1 = min(d$latitude),
          lng2 = max(d$longitude),
          lat2 = max(d$latitude)
        )
      
    })
    # --------------------------------------------------------
    # 7. Nombre d'objets par ville
    # --------------------------------------------------------
    
    output$city_chart <- plotly::renderPlotly({
      
      d <- osm_filtered() |>
        dplyr::count(city, name = "objects") |>
        dplyr::arrange(objects)
      
      validate(
        shiny::need(nrow(d) > 0, "Aucune donnée disponible.")
      )
      
      p <- ggplot2::ggplot(
        d,
        ggplot2::aes(
          x = stats::reorder(city, objects),
          y = objects,
          text = paste0(
            city,
            "<br>Objets OSM : ",
            objects
          )
        )
      ) +
        ggplot2::geom_col(
          fill = "#087E8B",
          width = 0.7
        ) +
        ggplot2::coord_flip() +
        ggplot2::labs(
          x = NULL,
          y = "Nombre d'objets"
        ) +
        ggplot2::theme_minimal(base_size = 11)
      
      plotly::ggplotly(p, tooltip = "text")
      
    })
    
    
    # --------------------------------------------------------
    # 8. Nombre d'objets par type
    # --------------------------------------------------------
    
    output$type_chart <- plotly::renderPlotly({
      
      d <- osm_filtered() |>
        dplyr::count(
          tourism_type_display,
          name = "objects"
        ) |>
        dplyr::arrange(objects)
      
      validate(
        shiny::need(nrow(d) > 0, "Aucune donnée disponible.")
      )
      
      p <- ggplot2::ggplot(
        d,
        ggplot2::aes(
          x = stats::reorder(tourism_type_display, objects),
          y = objects,
          text = paste0(
            tourism_type_display,
            "<br>Objets OSM : ",
            objects
          )
        )
      ) +
        ggplot2::geom_col(
          fill = "#23415C",
          width = 0.7
        ) +
        ggplot2::coord_flip() +
        ggplot2::labs(
          x = NULL,
          y = "Nombre d'objets"
        ) +
        ggplot2::theme_minimal(base_size = 11)
      
      plotly::ggplotly(p, tooltip = "text")
      
    })
    
    
    # --------------------------------------------------------
    # 9. Tableau des objets OSM
    # --------------------------------------------------------
    
    output$osm_table <- DT::renderDT({
      
      d <- osm_filtered()
      
      display_cols <- intersect(
        c(
          "city",
          "name",
          "tourism_type",
          "stars",
          "rooms",
          "latitude",
          "longitude",
          "postcode",
          "street",
          "website",
          "operator"
        ),
        names(d)
      )
      
      labels <- c(
        city = "Ville",
        name = "Nom",
        tourism_type = "Type",
        stars = "Étoiles",
        rooms = "Chambres",
        latitude = "Latitude",
        longitude = "Longitude",
        postcode = "Code postal",
        street = "Rue",
        website = "Site web",
        operator = "Opérateur"
      )
      
      table_data <- d |>
        dplyr::select(dplyr::all_of(display_cols)) |>
        dplyr::rename_with(
          ~ unname(labels[.x])
        )
      
      DT::datatable(
        table_data,
        rownames = FALSE,
        extensions = "Buttons",
        options = list(
          dom = "Bfrtip",
          buttons = c("copy", "csv", "excel"),
          pageLength = 10,
          scrollX = TRUE
        )
      )
      
    })
    
  })
}
