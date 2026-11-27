
# ============================================================
# MOROCCO-STAY — APPLICATION SHINY
# Fichier : app.R
# ============================================================

library(shiny)
library(bslib)
library(tidyverse)
library(plotly)
library(DT)
library(scales)
library(janitor)

# 1. Chargement des fonctions et modules ----------------------

source("R/01_data_loading.R", local = TRUE)
source("R/02_helpers.R", local = TRUE)
source("R/modules/mod_overview.R", local = TRUE)
source("R/modules/mod_demand.R", local = TRUE)
source("R/modules/mod_supply.R", local = TRUE)
source("R/modules/mod_competition.R", local = TRUE)
source("R/modules/mod_geography.R", local = TRUE)
source("R/modules/mod_covid.R", local = TRUE)
source("R/modules/mod_explorer.R", local = TRUE)
source("R/modules/mod_methodology.R", local = TRUE)
# 2. Importation des données ----------------------------------

morocco_data <- load_morocco_data("data/processed")

# 3. Thème graphique ------------------------------------------

app_theme <- bs_theme(
  version = 5,
  bootswatch = "flatly",
  primary = "#23415C",
  secondary = "#087E8B",
  success = "#168C83",
  #base_font = font_google("Source Sans 3"),
  #heading_font = font_google("Source Sans 3")
)

# 4. Interface ------------------------------------------------

ui <- page_navbar(
  
  title = div(
    span("MOROCCO", style = "font-weight:800;"),
    span("-STAY", style = "font-weight:300;"),
    span(
      " | TOURISM INTELLIGENCE",
      style = paste(
        "font-size:10px;",
        "letter-spacing:1.5px;",
        "margin-left:12px;",
        "opacity:0.75;"
      )
    )
  ),
  
  theme = app_theme,
  
  header = tagList(
    tags$style(HTML("
      body {
        background-color: #F4F7FA;
      }

      .navbar {
        box-shadow: 0 2px 8px rgba(0,0,0,0.08);
      }

      .intro-panel {
        background: #23415C;
        color: white;
        padding: 25px 30px;
        border-radius: 12px;
        margin: 15px 0 22px 0;
      }

      .intro-panel h3 {
        font-weight: 700;
        margin-top: 0;
      }

      .intro-panel p {
        opacity: 0.88;
        margin-bottom: 0;
      }

      .kpi-card {
        background: white;
        border-radius: 12px;
        padding: 20px;
        min-height: 125px;
        margin-bottom: 20px;
        border: 1px solid #E5EBF0;
        box-shadow: 0 2px 8px rgba(30,50,70,0.04);
      }

      .kpi-label {
        color: #687887;
        font-size: 12px;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.6px;
      }

      .kpi-value {
        color: #23415C;
        font-size: 25px;
        font-weight: 800;
        margin-top: 10px;
      }

      .kpi-subtitle {
        color: #8795A1;
        font-size: 11px;
        margin-top: 5px;
      }

      .method-note {
        background: #EAF1F5;
        border-left: 4px solid #087E8B;
        border-radius: 6px;
        padding: 15px 18px;
        color: #405363;
        font-size: 12px;
        margin: 15px 0 25px 0;
      }

      .card {
        border: 1px solid #E5EBF0;
        border-radius: 12px;
        box-shadow: 0 2px 8px rgba(30,50,70,0.035);
        margin-bottom: 20px;
      }

      .card-header {
        font-weight: 700;
        color: #23415C;
        background: white;
      }

      .placeholder-page {
        background: white;
        border-radius: 12px;
        padding: 35px;
        margin-top: 25px;
        border: 1px solid #E5EBF0;
      }
    "))
  ),
  
  nav_panel(
    "Vue d'ensemble",
    mod_overview_ui("overview")
  ),
  
  nav_panel(
    "Demande touristique",
    mod_demand_ui("demand")
  ),
  
  nav_panel(
    "Offre d'hébergement",
    mod_supply_ui("supply")
  ),
  
  nav_panel(
    "Concurrence territoriale",
    mod_competition_ui("competition")
  ),
  
  nav_panel(
    "Géographie touristique",
    mod_geography_ui("geography")
  ),
  
  nav_panel(
    "Covid-19",
    mod_covid_ui("covid")
  ),
  
  nav_panel(
    "Explorateur",
    mod_explorer_ui("explorer")
  ),
  
  nav_panel(
    "Méthodologie",
    mod_methodology_ui("methodology")
  )
)
# 5. Serveur ---------------------------------------------------

server <- function(input, output, session) {
  
  mod_overview_server(
    "overview",
    data = morocco_data
  )
  
  mod_demand_server(
    "demand",
    data = morocco_data
  )
  
  mod_supply_server(
    "supply",
    data = morocco_data
  )
  
  mod_competition_server(
    "competition",
    data = morocco_data
  )
  
  
  mod_geography_server(
    "geography",
    data = morocco_data
  )
  
  mod_covid_server(
    "covid",
    data = morocco_data
  )
  
  mod_explorer_server(
    "explorer",
    data = morocco_data
  )
  
  
  
  
}

# 6. Lancement ------------------------------------------------

shinyApp(
  ui = ui,
  server = server
)




