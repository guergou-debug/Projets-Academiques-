
# 2. Vérification des packages nécessaires -------------------

packages <- c(
  "shiny",
  "bslib",
  "plotly",
  "DT",
  "shinyWidgets",
  "tidyverse",
  "janitor",
  "scales",
  "thematic"
)

installed <- rownames(installed.packages())
missing_packages <- setdiff(packages, installed)

cat("\n--- PACKAGES MANQUANTS ---\n")
print(missing_packages)

if (length(missing_packages) > 0) {
  warning(
    "Installe localement les packages manquants : ",
    paste(missing_packages, collapse = ", ")
  )
} else {
  cat("\nTous les packages principaux sont disponibles.\n")
}
