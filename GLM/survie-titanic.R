# Projet 1, GLM: Modèle de Regression Logistuque
#installation des packages non installés 
install.packages("skimr")
## Chargement des modules nécessaires 
library("tidyverse")
library("ggplot2")
library("readr")
library("readxl")
library("skimr")
library("psych")

## chargement des données 
Data <- read_excel("C:/Users/ADMIN/OneDrive/Bureau/Projets GLM/Titanic_dataset.xls")

view(Data)

describe(Data)

summary(Data)

glimpse(Data)

# Suppression des colonnes non pertinentes pour la modélisation
# On garde : pclass, survived, sex, age, sibsp, parch, fare, embarked
colonnes_a_garder <- c("pclass", "survived", "sex", "age", "sibsp", "parch", "fare", "embarked")
Data_clean <- Data[, colonnes_a_garder]

# Vérification du nouveau jeu de données
glimpse(Data_clean)
summary(Data_clean)

# Charger la librairie nécessaire pour la stratification
library(caret)

# Fixer une graine aléatoire pour la reproductibilité
set.seed(123)

# Création de l'index de partition stratifiée
# createDataPartition assure que la proportion de "survived" est conservée
index_train <- createDataPartition(Data_clean$survived, p = 0.8, list = FALSE)

# Création des échantillons Train et Test
train_data <- Data_clean[index_train, ]
test_data  <- Data_clean[-index_train, ]

# Vérification des dimensions
cat("Dimensions de l'échantillon d'apprentissage :", dim(train_data), "\n")
cat("Dimensions de l'échantillon de validation    :", dim(test_data), "\n\n")

# Vérification de la stratification : proportions de survie
cat("Proportion de survivants dans les données complètes :", 
    round(mean(Data_clean$survived) * 100, 2), "%\n")
cat("Proportion de survivants dans l'échantillon Train  :", 
    round(mean(train_data$survived) * 100, 2), "%\n")
cat("Proportion de survivants dans l'échantillon Test   :", 
    round(mean(test_data$survived) * 100, 2), "%\n")


# Structure des données d'apprentissage
str(train_data)

# Résumé statistique
summary(train_data)

# Visualisation rapide des valeurs manquantes
cat("\n--- Valeurs manquantes dans Train ---\n")
colSums(is.na(train_data))


# 1. Traitement de embarked (mode)
mode_embarked <- names(sort(table(train_data$embarked), decreasing = TRUE))[1]
train_data$embarked[is.na(train_data$embarked)] <- mode_embarked
cat("Mode de embarked dans Train :", mode_embarked, "\n")

# 2. Traitement de fare (médiane)
mediane_fare <- median(train_data$fare, na.rm = TRUE)
train_data$fare[is.na(train_data$fare)] <- mediane_fare
cat("Médiane de fare dans Train :", mediane_fare, "\n")

# 3. Imputation de l'âge par médiane conditionnelle (classe × sexe)
# Calculer les médianes d'âge pour chaque combinaison pclass × sex
library(dplyr)

age_medians <- train_data %>%
  group_by(pclass, sex) %>%
  summarise(median_age = median(age, na.rm = TRUE), .groups = 'drop')

cat("\n--- Médianes d'âge par Classe et Sexe ---\n")
print(age_medians)

# Fonction pour imputer l'âge manquant avec la médiane correspondante
imputer_age <- function(row) {
  if (is.na(row['age'])) {
    median_val <- age_medians %>%
      filter(pclass == as.numeric(row['pclass']), sex == row['sex']) %>%
      pull(median_age)
    return(median_val)
  } else {
    return(as.numeric(row['age']))
  }
}

# Appliquer l'imputation
train_data$age <- apply(train_data[, c('pclass', 'sex', 'age')], 1, imputer_age)

# Vérification qu'il n'y a plus de NA
cat("\n--- NA après traitement dans Train ---\n")
print(colSums(is.na(train_data)))

# Conversion des variables catégorielles en facteurs
train_data$pclass <- as.factor(train_data$pclass)
train_data$sex <- as.factor(train_data$sex)
train_data$embarked <- as.factor(train_data$embarked)
train_data$survived <- as.factor(train_data$survived)

cat("\n--- Structure finale de train_data ---\n")
str(train_data)

# Visualisation rapide de la distribution des âges
hist(train_data$age, breaks = 30, col = "lightblue", 
     main = "Distribution des âges dans Train", 
     xlab = "Âge (années)", ylab = "Fréquence")
abline(v = median(train_data$age), col = "red", lwd = 2)
legend("topright", legend = paste("Médiane =", round(median(train_data$age), 1)), 
       col = "red", lwd = 2)

# Modèle de régression logistique complet
modele_complet <- glm(survived ~ pclass + sex + age + sibsp + parch + fare + embarked, 
                      data = train_data, 
                      family = binomial)

# Résumé du modèle
summary(modele_complet)

# Calcul des odds ratios
exp(coef(modele_complet))


# Modèle réduit (sans parch et fare)
modele_reduit <- glm(survived ~ pclass + sex + age + sibsp + embarked, 
                     data = train_data, 
                     family = binomial)

# Résumé du modèle réduit
summary(modele_reduit)

# Comparaison des deux modèles avec ANOVA
anova(modele_reduit, modele_complet, test = "Chisq")


# Test de surdispersion pour le modèle complet
phi_complet <- deviance(modele_complet) / df.residual(modele_complet)
cat("Paramètre de dispersion (modèle complet) :", round(phi_complet, 4), "\n")

# Test de surdispersion pour le modèle réduit
phi_reduit <- deviance(modele_reduit) / df.residual(modele_reduit)
cat("Paramètre de dispersion (modèle réduit)   :", round(phi_reduit, 4), "\n")


# Modèle de départ (toutes les variables)
modele_step <- glm(survived ~ pclass + sex + age + sibsp + parch + fare + embarked, 
                   data = train_data, 
                   family = binomial)

# Sélection pas à pas dans les deux directions
modele_stepwise <- step(modele_step, direction = "both", trace = TRUE)

# Résumé du modèle final
summary(modele_stepwise)

# AIC du modèle final
cat("\nAIC du modèle stepwise :", AIC(modele_stepwise), "\n")



# Sélection basée sur le BIC
modele_bic <- step(modele_step, direction = "both", k = log(nrow(train_data)), trace = TRUE)

# Résumé du modèle final BIC
summary(modele_bic)

# Comparaison AIC et BIC
cat("\n--- Comparaison des critères ---\n")
cat("AIC du modèle stepwise :", AIC(modele_stepwise), "\n")
cat("BIC du modèle stepwise :", BIC(modele_stepwise), "\n")
cat("AIC du modèle BIC     :", AIC(modele_bic), "\n")
cat("BIC du modèle BIC     :", BIC(modele_bic), "\n")



# Installer et charger la librairie nécessaire pour Hosmer-Lemeshow
library(ResourceSelection)

# Test de Hosmer-Lemeshow
# Convertir survived en numérique pour le test
hoslem_test <- hoslem.test(as.numeric(as.character(train_data$survived)), 
                           fitted(modele_stepwise), g = 10)
print(hoslem_test)

# Pseudo-R² de McFadden
null_deviance <- modele_stepwise$null.deviance
resid_deviance <- modele_stepwise$deviance
mcfadden_R2 <- 1 - (resid_deviance / null_deviance)
cat("\n--- Pseudo R² de McFadden ---\n")
cat("R² McFadden =", round(mcfadden_R2, 4), "\n")

# Pseudo-R² de Nagelkerke (via librairie fmsb)
install.packages("fmsb")
library(fmsb)
nagelkerke_R2 <- NagelkerkeR2(modele_stepwise)
cat("\n--- Pseudo R² de Nagelkerke ---\n")
print(nagelkerke_R2)



# Calcul des résidus
residus_pearson <- residuals(modele_stepwise, type = "pearson")
residus_deviance <- residuals(modele_stepwise, type = "deviance")
cook_dist <- cooks.distance(modele_stepwise)

# Création d'un dataframe pour l'analyse des résidus
diagnostics <- data.frame(
  obs = 1:nrow(train_data),
  pearson = residus_pearson,
  deviance = residus_deviance,
  cook = cook_dist,
  survived = train_data$survived,
  fitted = fitted(modele_stepwise)
)

# Affichage des observations avec résidus extrêmes
cat("--- Résidus de Pearson extrêmes (|res| > 3) ---\n")
print(diagnostics[abs(diagnostics$pearson) > 3, ])

cat("\n--- Résidus de Pearson modérément grands (|res| > 2) ---\n")
print(diagnostics[abs(diagnostics$pearson) > 2, ])

cat("\n--- Observations influentes (Cook > 4/n) ---\n")
seuil_cook <- 4 / nrow(train_data)
cat("Seuil de Cook =", round(seuil_cook, 6), "\n")
print(diagnostics[diagnostics$cook > seuil_cook, ])

# Résumé statistique des résidus
cat("\n--- Résumé des résidus de Pearson ---\n")
print(summary(diagnostics$pearson))

cat("\n--- Résumé des résidus de déviance ---\n")
print(summary(diagnostics$deviance))




# Solution 1 : Agrandir la fenêtre graphique manuellement
# Cliquez sur "Zoom" dans la fenêtre Plots de RStudio

# Solution 2 : Sauvegarder les graphiques directement en fichier PNG
png("diagnostics_residus.png", width = 800, height = 800)
par(mfrow = c(2, 2))

# 1. Résidus de Pearson vs valeurs prédites
plot(diagnostics$fitted, diagnostics$pearson,
     xlab = "Probabilités prédites", ylab = "Résidus de Pearson",
     main = "Résidus de Pearson vs Prédites")
abline(h = 0, col = "red", lty = 2)
abline(h = c(-2, 2), col = "blue", lty = 2)
abline(h = c(-3, 3), col = "red", lty = 1)
lines(lowess(diagnostics$fitted, diagnostics$pearson), col = "green", lwd = 2)

# 2. Résidus de déviance vs valeurs prédites
plot(diagnostics$fitted, diagnostics$deviance,
     xlab = "Probabilités prédites", ylab = "Résidus de déviance",
     main = "Résidus de déviance vs Prédites")
abline(h = 0, col = "red", lty = 2)
lines(lowess(diagnostics$fitted, diagnostics$deviance), col = "green", lwd = 2)

# 3. Distance de Cook
plot(diagnostics$obs, diagnostics$cook, type = "h",
     xlab = "Observation", ylab = "Distance de Cook",
     main = "Distances de Cook")
abline(h = seuil_cook, col = "red", lty = 2)
influentes <- which(diagnostics$cook > seuil_cook)
if(length(influentes) > 0) {
  text(influentes, diagnostics$cook[influentes], 
       labels = influentes, pos = 3, cex = 0.7, col = "red")
}

# 4. QQ-plot des résidus de déviance
qqnorm(diagnostics$deviance, main = "QQ-plot des résidus de déviance")
qqline(diagnostics$deviance, col = "red")

dev.off()
cat("Graphiques sauvegardés dans 'diagnostics_residus.png'\n")

# Histogramme séparé
png("histogramme_residus.png", width = 600, height = 500)
hist(diagnostics$pearson, breaks = 30, col = "lightblue", 
     main = "Distribution des résidus de Pearson",
     xlab = "Résidus de Pearson", probability = TRUE)
lines(density(diagnostics$pearson), col = "red", lwd = 2)
curve(dnorm(x, mean = mean(diagnostics$pearson), sd = sd(diagnostics$pearson)), 
      add = TRUE, col = "blue", lwd = 2, lty = 2)
legend("topright", legend = c("Densité observée", "Normale théorique"),
       col = c("red", "blue"), lwd = 2, lty = c(1, 2))
dev.off()
cat("Histogramme sauvegardé dans 'histogramme_residus.png'\n")




# Rappel des paramètres du Train (à réutiliser)
cat("--- Paramètres du Train à appliquer au Test ---\n")
cat("Mode de embarked :", mode_embarked, "\n")
cat("Médiane de fare   :", mediane_fare, "\n")

# 1. Imputation de embarked sur test_data
test_data$embarked[is.na(test_data$embarked)] <- mode_embarked

# 2. Imputation de fare sur test_data
test_data$fare[is.na(test_data$fare)] <- mediane_fare

# 3. Imputation de l'âge sur test_data
test_data$age <- apply(test_data[, c('pclass', 'sex', 'age')], 1, imputer_age)

# 4. Conversion en facteurs
test_data$pclass <- as.factor(test_data$pclass)
test_data$sex <- as.factor(test_data$sex)
test_data$embarked <- as.factor(test_data$embarked)
test_data$survived <- as.factor(test_data$survived)

# Vérification
cat("\n--- NA dans test_data après imputation ---\n")
print(colSums(is.na(test_data)))




# Prédictions sur le Test (probabilités)
pred_probs <- predict(modele_stepwise, newdata = test_data, type = "response")

# Conversion en classes prédites (seuil = 0.5)
pred_classes <- ifelse(pred_probs > 0.5, 1, 0)
pred_classes <- as.factor(pred_classes)

# Ajout au test_data
test_data$pred_survived <- pred_classes
test_data$pred_prob <- pred_probs

library(caret)

# Matrice de confusion
conf_matrix <- confusionMatrix(pred_classes, test_data$survived, positive = "1")
print(conf_matrix)

# Extraction des métriques principales
cat("\n--- Métriques de performance ---\n")
cat("Accuracy (Précision globale) :", round(conf_matrix$overall['Accuracy'] * 100, 2), "%\n")
cat("Sensibilité (Recall)          :", round(conf_matrix$byClass['Sensitivity'] * 100, 2), "%\n")
cat("Spécificité                   :", round(conf_matrix$byClass['Specificity'] * 100, 2), "%\n")
cat("Précision (Precision)         :", round(conf_matrix$byClass['Precision'] * 100, 2), "%\n")
cat("F1-Score                      :", round(conf_matrix$byClass['F1'], 4), "\n")








library(pROC)

# Calcul de la courbe ROC
roc_curve <- roc(test_data$survived, pred_probs, levels = c("0", "1"))

# Affichage de l'AUC
cat("\n--- Courbe ROC ---\n")
cat("AUC (Area Under Curve) :", round(auc(roc_curve), 4), "\n")

# Intervalles de confiance de l'AUC
ci_auc <- ci.auc(roc_curve)
cat("IC 95% de l'AUC : [", round(ci_auc[1], 4), ",", round(ci_auc[3], 4), "]\n")

# Tracé de la courbe ROC (version corrigée)
png("courbe_roc.png", width = 600, height = 600)
plot.roc(roc_curve, 
         main = "Courbe ROC - Modèle de Régression Logistique",
         col = "blue", 
         lwd = 3, 
         print.auc = TRUE, 
         print.auc.x = 0.5, 
         print.auc.y = 0.3,
         print.auc.cex = 1.2)
dev.off()
cat("Courbe ROC sauvegardée dans 'courbe_roc.png'\n")

# Affichage direct dans RStudio
plot.roc(roc_curve, 
         main = "Courbe ROC - Modèle de Régression Logistique",
         col = "blue", 
         lwd = 3, 
         print.auc = TRUE, 
         print.auc.x = 0.5, 
         print.auc.y = 0.3,
         print.auc.cex = 1.2)




# Prédictions du modèle BIC sur le Test
pred_probs_bic <- predict(modele_bic, newdata = test_data, type = "response")
pred_classes_bic <- ifelse(pred_probs_bic > 0.5, 1, 0)
pred_classes_bic <- as.factor(pred_classes_bic)

# Ajout au test_data
test_data$pred_survived_bic <- pred_classes_bic
test_data$pred_prob_bic <- pred_probs_bic




# Matrice de confusion - Modèle AIC (Stepwise)
conf_matrix_aic <- confusionMatrix(test_data$pred_survived, test_data$survived, positive = "1")

# Matrice de confusion - Modèle BIC
conf_matrix_bic <- confusionMatrix(pred_classes_bic, test_data$survived, positive = "1")

# Comparaison côte à côte
cat("\n========== COMPARAISON DES MODÈLES ==========\n\n")

cat("--- MODÈLE AIC (avec embarked) ---\n")
cat("Accuracy :", round(conf_matrix_aic$overall['Accuracy'] * 100, 2), "%\n")
cat("Sensibilité :", round(conf_matrix_aic$byClass['Sensitivity'] * 100, 2), "%\n")
cat("Spécificité :", round(conf_matrix_aic$byClass['Specificity'] * 100, 2), "%\n")
cat("Précision :", round(conf_matrix_aic$byClass['Precision'] * 100, 2), "%\n")
cat("F1-Score :", round(conf_matrix_aic$byClass['F1'], 4), "\n")

cat("\n--- MODÈLE BIC (sans embarked) ---\n")
cat("Accuracy :", round(conf_matrix_bic$overall['Accuracy'] * 100, 2), "%\n")
cat("Sensibilité :", round(conf_matrix_bic$byClass['Sensitivity'] * 100, 2), "%\n")
cat("Spécificité :", round(conf_matrix_bic$byClass['Specificity'] * 100, 2), "%\n")
cat("Précision :", round(conf_matrix_bic$byClass['Precision'] * 100, 2), "%\n")
cat("F1-Score :", round(conf_matrix_bic$byClass['F1'], 4), "\n")

# Tableau comparatif
cat("\n--- TABLEAU COMPARATIF ---\n")
comparaison <- data.frame(
  Métrique = c("Accuracy", "Sensibilité", "Spécificité", "Précision", "F1-Score"),
  AIC = c(
    round(conf_matrix_aic$overall['Accuracy'] * 100, 2),
    round(conf_matrix_aic$byClass['Sensitivity'] * 100, 2),
    round(conf_matrix_aic$byClass['Specificity'] * 100, 2),
    round(conf_matrix_aic$byClass['Precision'] * 100, 2),
    round(conf_matrix_aic$byClass['F1'], 4)
  ),
  BIC = c(
    round(conf_matrix_bic$overall['Accuracy'] * 100, 2),
    round(conf_matrix_bic$byClass['Sensitivity'] * 100, 2),
    round(conf_matrix_bic$byClass['Specificity'] * 100, 2),
    round(conf_matrix_bic$byClass['Precision'] * 100, 2),
    round(conf_matrix_bic$byClass['F1'], 4)
  )
)
print(comparaison)







# Calcul des courbes ROC
roc_aic <- roc(test_data$survived, test_data$pred_prob, levels = c("0", "1"))
roc_bic <- roc(test_data$survived, pred_probs_bic, levels = c("0", "1"))

# Comparaison des AUC
cat("\n--- COMPARAISON DES AUC ---\n")
cat("AUC - Modèle AIC :", round(auc(roc_aic), 4), "\n")
cat("AUC - Modèle BIC :", round(auc(roc_bic), 4), "\n")

# Test de DeLong pour comparer les deux courbes ROC
test_roc <- roc.test(roc_aic, roc_bic, method = "delong")
cat("\n--- Test de DeLong (comparaison des AUC) ---\n")
cat("p-value :", round(test_roc$p.value, 4), "\n")
if(test_roc$p.value < 0.05) {
  cat("Conclusion : Différence significative entre les deux AUC\n")
} else {
  cat("Conclusion : Pas de différence significative entre les deux AUC\n")
}

# Tracé comparatif des courbes ROC
png("courbes_roc_comparees.png", width = 700, height = 600)
plot.roc(roc_aic, 
         main = "Comparaison des Courbes ROC - Modèles AIC vs BIC",
         col = "blue", 
         lwd = 3,
         print.auc = TRUE,
         print.auc.x = 0.5,
         print.auc.y = 0.4,
         print.auc.cex = 1.1)
lines.roc(roc_bic, col = "red", lwd = 3)
legend("bottomright", 
       legend = c(paste("AIC (AUC =", round(auc(roc_aic), 4), ")"),
                  paste("BIC (AUC =", round(auc(roc_bic), 4), ")")),
       col = c("blue", "red"), 
       lwd = 3, 
       bty = "n")
dev.off()
cat("\nCourbes ROC comparées sauvegardées dans 'courbes_roc_comparees.png'\n")

# Affichage direct
plot.roc(roc_aic, 
         main = "Comparaison des Courbes ROC - Modèles AIC vs BIC",
         col = "blue", 
         lwd = 3,
         print.auc = TRUE,
         print.auc.x = 0.5,
         print.auc.y = 0.4,
         print.auc.cex = 1.1)
lines.roc(roc_bic, col = "red", lwd = 3)
legend("bottomright", 
       legend = c(paste("AIC (AUC =", round(auc(roc_aic), 4), ")"),
                  paste("BIC (AUC =", round(auc(roc_bic), 4), ")")),
       col = c("blue", "red"), 
       lwd = 3, 
       bty = "n")



# Calcul des odds ratios
exp(coef(modele_step))









# ============================================================
# AFFICHAGE DES COEFFICIENTS DES MODÈLES AIC ET BIC
# ============================================================

# ------------------------------------------------------------
# 1. Coefficients du modèle AIC (Stepwise)
# ------------------------------------------------------------
cat("========== MODÈLE AIC (STEPWISE) ==========\n")
cat("Formule : survived ~ pclass + sex + age + sibsp + embarked\n\n")

summary(modele_stepwise)

cat("\n--- Odds ratios du modèle AIC ---\n")
exp(coef(modele_stepwise))

cat("\n--- Intervalles de confiance des odds ratios (95%) ---\n")
exp(confint(modele_stepwise))

# ------------------------------------------------------------
# 2. Coefficients du modèle BIC
# ------------------------------------------------------------
cat("\n\n========== MODÈLE BIC ==========\n")
cat("Formule : survived ~ pclass + sex + age + sibsp\n\n")

summary(modele_bic)

cat("\n--- Odds ratios du modèle BIC ---\n")
exp(coef(modele_bic))

cat("\n--- Intervalles de confiance des odds ratios (95%) ---\n")
exp(confint(modele_bic))

# ------------------------------------------------------------
# 3. Comparaison AIC / BIC
# ------------------------------------------------------------
cat("\n\n========== COMPARAISON AIC / BIC ==========\n")
cat("AIC du modèle AIC :", AIC(modele_stepwise), "\n")
cat("BIC du modèle AIC :", BIC(modele_stepwise), "\n")
cat("AIC du modèle BIC :", AIC(modele_bic), "\n")
cat("BIC du modèle BIC :", BIC(modele_bic), "\n")
