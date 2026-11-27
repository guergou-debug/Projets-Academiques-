
# ============================================================
# MODULE 7 : METHODOLOGIE ET SOURCES
# Projet : MOROCCO-STAY
# ============================================================

mod_methodology_ui <- function(id) {
  
  ns <- shiny::NS(id)
  
  shiny::tagList(
    
    # --------------------------------------------------------
    # INTRODUCTION
    # --------------------------------------------------------
    
    shiny::div(
      class = "intro-panel",
      
      shiny::h3("Méthodologie et sources"),
      
      shiny::p(
        "Cadre analytique, données, indicateurs et limites ",
        "de l'étude du marché de l'hébergement touristique au Maroc."
      )
    ),
    
    shiny::br(),
    
    # --------------------------------------------------------
    # NAVIGATION PAR ETAPES
    # --------------------------------------------------------
    
    bslib::navset_card_tab(
      
      id = ns("methodology_tabs"),
      
      # ======================================================
      # ETAPE 1 : PERIMETRE
      # ======================================================
      
      bslib::nav_panel(
        
        title = "01 · Périmètre",
        
        shiny::h4("Objectifs de l'étude"),
        
        shiny::p(
          "MOROCCO-STAY propose une analyse économique et ",
          "territoriale du marché de l'hébergement touristique ",
          "au Maroc."
        ),
        
        shiny::hr(),
        
        shiny::h5("Axes d'analyse"),
        
        shiny::fluidRow(
          
          shiny::column(
            6,
            bslib::card(
              bslib::card_body(
                shiny::h5("Demande touristique"),
                shiny::p(
                  "Évolution des nuitées, répartition ",
                  "géographique et marchés émetteurs."
                )
              )
            )
          ),
          
          shiny::column(
            6,
            bslib::card(
              bslib::card_body(
                shiny::h5("Offre d'hébergement"),
                shiny::p(
                  "Capacité en lits et structure ",
                  "par catégorie d'établissement."
                )
              )
            )
          ),
          
          shiny::column(
            6,
            bslib::card(
              bslib::card_body(
                shiny::h5("Positionnement territorial"),
                shiny::p(
                  "Comparaison du poids de la demande ",
                  "et de celui de la capacité."
                )
              )
            )
          ),
          
          shiny::column(
            6,
            bslib::card(
              bslib::card_body(
                shiny::h5("Résilience et géographie"),
                shiny::p(
                  "Analyse du choc Covid-19 et ",
                  "distribution spatiale des hébergements."
                )
              )
            )
          )
        ),
        
        shiny::hr(),
        
        shiny::fluidRow(
          
          shiny::column(
            6,
            shiny::strong("Période principale"),
            shiny::p("2012–2020, selon les séries disponibles.")
          ),
          
          shiny::column(
            6,
            shiny::strong("Champ territorial"),
            shiny::p(
              "Destinations couvertes par les statistiques exploitées."
            )
          )
        )
      ),
      
      # ======================================================
      # ETAPE 2 : DONNEES
      # ======================================================
      
      bslib::nav_panel(
        
        title = "02 · Données",
        
        shiny::h4("Sources et bases de données"),
        
        shiny::p(
          "Les analyses reposent sur plusieurs bases ",
          "statistiques préparées et harmonisées pour le projet."
        ),
        
        shiny::fluidRow(
          
          shiny::column(
            6,
            bslib::card(
              bslib::card_body(
                shiny::h5("Données touristiques"),
                shiny::tags$ul(
                  shiny::tags$li("Nuitées par destination"),
                  shiny::tags$li("Capacité en lits par destination"),
                  shiny::tags$li("Capacité par catégorie"),
                  shiny::tags$li("Nuitées par marché touristique"),
                  shiny::tags$li("Arrivées par nationalité")
                )
              )
            )
          ),
          
          shiny::column(
            6,
            bslib::card(
              bslib::card_body(
                shiny::h5("Données complémentaires"),
                shiny::tags$ul(
                  shiny::tags$li("Arrivées par point d'entrée"),
                  shiny::tags$li("Objets géographiques OpenStreetMap"),
                  shiny::tags$li("Indicateurs économiques dérivés"),
                  shiny::tags$li("Tables de comparaison Covid-19")
                )
              )
            )
          )
        ),
        
        shiny::hr(),
        
        shiny::h5("Chaîne de préparation des données"),
        
        shiny::tags$ol(
          shiny::tags$li("Importation et contrôle des fichiers."),
          shiny::tags$li("Vérification des dimensions et des variables."),
          shiny::tags$li("Harmonisation des années et des libellés."),
          shiny::tags$li("Contrôle des valeurs manquantes."),
          shiny::tags$li("Construction des tables analytiques.")
        ),
        
        bslib::card(
          bslib::card_body(
            shiny::strong("Précaution"),
            shiny::p(
              "Une valeur manquante n'est pas assimilée à zéro. ",
              "L'absence d'observation ne signifie pas ",
              "l'absence d'activité touristique."
            )
          )
        )
      ),
      
      # ======================================================
      # ETAPE 3 : DEMANDE ET OFFRE
      # ======================================================
      
      bslib::nav_panel(
        
        title = "03 · Analyses",
        
        shiny::h4("Analyse de la demande"),
        
        shiny::p(
          "La demande est principalement appréhendée ",
          "à travers les nuitées touristiques."
        ),
        
        bslib::card(
          bslib::card_body(
            
            shiny::h5("Taux de croissance annuel"),
            
            shiny::p(
              "Mesure l'évolution relative d'un indicateur ",
              "entre deux années consécutives."
            ),
            
            shiny::withMathJax(
              shiny::div(
                class = "method-formula",
                "$$g_t = \\left(\\frac{X_t}{X_{t-1}}-1\\right)\\times 100$$"
              )
            )
          )
        ),
        
        bslib::card(
          bslib::card_body(
            
            shiny::h5("Taux de croissance annuel moyen (CAGR)"),
            
            shiny::p(
              "Mesure le rythme annuel moyen de croissance ",
              "entre deux dates."
            ),
            
            shiny::withMathJax(
              shiny::div(
                class = "method-formula",
                "$$CAGR = \\left[\\left(\\frac{X_T}{X_0}\\right)^{1/T}-1\\right]\\times 100$$"
              )
            )
          )
        ),
        
        shiny::hr(),
        
        shiny::h4("Analyse de l'offre"),
        
        shiny::p(
          "L'offre est étudiée à partir de la capacité ",
          "d'hébergement exprimée en nombre de lits."
        ),
        
        shiny::tags$ul(
          shiny::tags$li("Évolution annuelle de la capacité."),
          shiny::tags$li("Répartition des lits par catégorie."),
          shiny::tags$li("Comparaison entre destinations."),
          shiny::tags$li("Évolution de la structure de l'offre.")
        ),
        
        bslib::card(
          bslib::card_body(
            shiny::strong("Distinction fondamentale"),
            shiny::p(
              "La capacité en lits ne doit pas être confondue ",
              "avec le nombre de chambres, d'établissements ",
              "ou de nuitées."
            )
          )
        )
      ),
      
      # ======================================================
      # ETAPE 4 : POSITIONNEMENT
      # ======================================================
      
      bslib::nav_panel(
        
        title = "04 · Indicateurs",
        
        shiny::h4("Indicateurs de positionnement concurrentiel"),
        
        shiny::p(
          "Plusieurs indicateurs permettent de comparer ",
          "la structure de la demande et celle de l'offre."
        ),
        
        bslib::card(
          bslib::card_body(
            
            shiny::h5("Parts de marché"),
            
            shiny::p(
              "Mesurent le poids relatif d'une destination ",
              "dans le total observé."
            ),
            
            shiny::withMathJax(
              shiny::div(
                class = "method-formula",
                "$$Part_i = \\frac{X_i}{\\sum_j X_j}\\times 100$$"
              )
            )
          )
        ),
        
        bslib::card(
          bslib::card_body(
            
            shiny::h5("Indice de pression sur la capacité"),
            
            shiny::p(
              "Rapporte les nuitées à la capacité théorique ",
              "annuelle en lits."
            ),
            
            shiny::withMathJax(
              shiny::div(
                class = "method-formula",
                "$$P_i = \\frac{N_i}{L_i\\times365}\\times100$$"
              )
            ),
            
            shiny::p(
              "Il s'agit d'un proxy de pression et non ",
              "d'un taux officiel d'occupation."
            )
          )
        ),
        
        bslib::card(
          bslib::card_body(
            
            shiny::h5("Location Quotient (LQ)"),
            
            shiny::p(
              "Compare la part de la demande d'une destination ",
              "à sa part dans la capacité."
            ),
            
            shiny::withMathJax(
              shiny::div(
                class = "method-formula",
                "$$LQ_i = \\frac{Part\\ de\\ la\\ demande_i}{Part\\ de\\ la\\ capacité_i}$$"
              )
            ),
            
            shiny::tags$ul(
              shiny::tags$li("LQ supérieur à 1 : demande relativement plus importante."),
              shiny::tags$li("LQ égal à 1 : parts relatives similaires."),
              shiny::tags$li("LQ inférieur à 1 : capacité relativement plus importante.")
            )
          )
        ),
        
        bslib::card(
          bslib::card_body(
            
            shiny::h5("Indice de concentration HHI"),
            
            shiny::p(
              "Mesure le degré de concentration d'une distribution."
            ),
            
            shiny::withMathJax(
              shiny::div(
                class = "method-formula",
                "$$HHI = \\sum_{i=1}^{n}s_i^2$$"
              )
            ),
            
            shiny::p(
              "Les parts sont exprimées en proportions. ",
              "Un indice élevé traduit une concentration plus importante."
            )
          )
        ),
        
        bslib::card(
          bslib::card_body(
            
            shiny::h5("Classification des destinations"),
            
            shiny::p(
              "Le croisement de la croissance de la demande ",
              "et du positionnement relatif permet de distinguer :"
            ),
            
            shiny::tags$ul(
              shiny::tags$li("Leaders dynamiques"),
              shiny::tags$li("Marchés émergents"),
              shiny::tags$li("Marchés spécialisés"),
              shiny::tags$li("Destinations en retrait relatif")
            ),
            
            shiny::p(
              class = "text-muted",
              "Cette classification dépend de l'échantillon ",
              "et des seuils retenus."
            )
          )
        )
      ),
      
      # ======================================================
      # ETAPE 5 : COVID ET GEOGRAPHIE
      # ======================================================
      
      bslib::nav_panel(
        
        title = "05 · Analyses spécifiques",
        
        shiny::h4("Analyse du choc Covid-19"),
        
        shiny::p(
          "La comparaison porte sur les niveaux observés ",
          "en 2019 et en 2020."
        ),
        
        bslib::card(
          bslib::card_body(
            
            shiny::h5("Variation absolue"),
            
            shiny::withMathJax(
              shiny::div(
                class = "method-formula",
                "$$\\Delta X = X_{2020}-X_{2019}$$"
              )
            ),
            
            shiny::h5("Variation relative"),
            
            shiny::withMathJax(
              shiny::div(
                class = "method-formula",
                "$$Variation(\\%) = \\frac{X_{2020}-X_{2019}}{X_{2019}}\\times100$$"
              )
            )
          )
        ),
        
        bslib::card(
          bslib::card_body(
            shiny::strong("Limite d'interprétation"),
            shiny::p(
              "Cette comparaison décrit une rupture temporelle. ",
              "Elle ne permet pas, à elle seule, d'identifier ",
              "un effet causal exclusivement attribuable ",
              "à la pandémie."
            )
          )
        ),
        
        shiny::hr(),
        
        shiny::h4("Analyse géographique"),
        
        shiny::p(
          "OpenStreetMap est utilisé pour explorer la distribution ",
          "spatiale des objets associés à l'hébergement touristique."
        ),
        
        shiny::fluidRow(
          
          shiny::column(
            6,
            bslib::card(
              bslib::card_body(
                shiny::h5("Marrakech"),
                shiny::p("1 068 objets recensés.")
              )
            )
          ),
          
          shiny::column(
            6,
            bslib::card(
              bslib::card_body(
                shiny::h5("Casablanca"),
                shiny::p("201 objets recensés.")
              )
            )
          ),
          
          shiny::column(
            6,
            bslib::card(
              bslib::card_body(
                shiny::h5("Agadir"),
                shiny::p("244 objets recensés.")
              )
            )
          ),
          
          shiny::column(
            6,
            bslib::card(
              bslib::card_body(
                shiny::h5("Tanger"),
                shiny::p("133 objets recensés.")
              )
            )
          )
        ),
        
        bslib::card(
          bslib::card_body(
            shiny::strong("Limite de couverture"),
            shiny::p(
              "Les données dépendent des contributions ",
              "et mises à jour d'OpenStreetMap. Elles ne ",
              "constituent pas un recensement exhaustif ",
              "des hébergements actifs."
            )
          )
        )
      ),
      
      # ======================================================
      # ETAPE 6 : LIMITES
      # ======================================================
      
      bslib::nav_panel(
        
        title = "06 · Limites",
        
        shiny::h4("Limites méthodologiques"),
        
        bslib::card(
          bslib::card_body(
            
            shiny::tags$ul(
              
              shiny::tags$li(
                shiny::strong("Disponibilité statistique : "),
                "les séries ne couvrent pas nécessairement ",
                "toutes les destinations et toutes les années."
              ),
              
              shiny::tags$li(
                shiny::strong("Périmètres variables : "),
                "les analyses peuvent reposer sur des ",
                "échantillons différents."
              ),
              
              shiny::tags$li(
                shiny::strong("Valeurs manquantes : "),
                "elles ne sont pas automatiquement ",
                "remplacées par des zéros."
              ),
              
              shiny::tags$li(
                shiny::strong("Capacité théorique : "),
                "le produit lits × 365 ne tient pas compte ",
                "des fermetures ou de la disponibilité réelle."
              ),
              
              shiny::tags$li(
                shiny::strong("OpenStreetMap : "),
                "la couverture et la précision des attributs ",
                "peuvent varier entre les villes."
              ),
              
              shiny::tags$li(
                shiny::strong("Covid-19 : "),
                "les comparaisons temporelles ne constituent ",
                "pas une identification causale."
              )
            )
          )
        ),
        
        shiny::hr(),
        
        shiny::h4("Principes d'interprétation"),
        
        shiny::fluidRow(
          
          shiny::column(
            6,
            bslib::card(
              bslib::card_body(
                shiny::h5("Homogénéité"),
                shiny::p(
                  "Comparer des périmètres temporels ",
                  "et géographiques comparables."
                )
              )
            )
          ),
          
          shiny::column(
            6,
            bslib::card(
              bslib::card_body(
                shiny::h5("Transparence"),
                shiny::p(
                  "Distinguer les données observées ",
                  "des indicateurs calculés."
                )
              )
            )
          ),
          
          shiny::column(
            6,
            bslib::card(
              bslib::card_body(
                shiny::h5("Prudence"),
                shiny::p(
                  "Ne pas assimiler corrélation ",
                  "et causalité."
                )
              )
            )
          ),
          
          shiny::column(
            6,
            bslib::card(
              bslib::card_body(
                shiny::h5("Interprétation"),
                shiny::p(
                  "Lire chaque indicateur à la lumière ",
                  "de ses hypothèses et limites."
                )
              )
            )
          )
        ),
        
        shiny::hr(),
        
        bslib::card(
          bslib::card_body(
            
            shiny::h4("Une approche intégrée d'aide à la décision"),
            
            shiny::p(
              "MOROCCO-STAY combine analyse statistique, ",
              "indicateurs économiques et exploration ",
              "géographique pour proposer une lecture ",
              "structurée du marché de l'hébergement touristique."
            )
          )
        )
      )
    )
  )
}

# ============================================================
# FIN DU MODULE 7
# ============================================================
