# Projet 1, GLM: Modèle de Regression Poisson
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
Data_brute <- read_csv("C:/Users/ADMIN/OneDrive/Bureau/Projets GLM/data.csv")

view(Data_brute)
str(Data_brute)
describe(Data_brute)

colSums(is.na(Data_brute))


# ------------------------------------------------------------
# 1. Suppression des colonnes non pertinentes
# ------------------------------------------------------------
# On garde les variables potentiellement utiles pour expliquer ceb (nombre d'enfants)
# On supprime : ...1 (index), yearborn, monthfm, yearfm, agefbrth, children (redondant avec ceb),
# heduc (trop de NA), idlnchld (idéal subjectif), frsthalf (peu pertinent),
# urb_educ (interaction que l'on pourra recréer), educ0 (redondant avec educ)

cols_to_remove <- c("...1", "yearborn", "monthfm", "yearfm", "agefbrth", 
                    "children", "heduc", "idlnchld", "frsthalf", "urb_educ", "educ0")
Data_clean <- Data_brute[, !(names(Data_brute) %in% cols_to_remove)]

# Vérif
colnames(Data_clean)

# ------------------------------------------------------------
# 2. Gestion des valeurs manquantes
# ------------------------------------------------------------
# a) Variables avec peu de NA : electric (3), radio (2), tv (2), bicycle (3),
#    knowmeth (7), usemeth (71), agefm (2282) -> beaucoup, mais important
#    agefm : âge au premier mariage. Pour les femmes jamais mariées (evermarr=0), NA est logique.
#    On va créer une indicatrice "married" à partir de evermarr (0/1) et remplacer NA de agefm par 0.
#    Pour les autres variables (electric, radio, tv, bicycle, knowmeth, usemeth), on supprime les lignes avec NA
#    car peu nombreuses.

# Supprimer les lignes avec NA sur electric, radio, tv, bicycle, knowmeth
vars_with_few_na <- c("electric", "radio", "tv", "bicycle", "knowmeth")
Data_clean <- Data_clean[complete.cases(Data_clean[, vars_with_few_na]), ]

# Pour usemeth : 71 NA. On supprime également ces lignes (on reste cohérent)
Data_clean <- Data_clean[!is.na(Data_clean$usemeth), ]

# b) Pour agefm : remplacer NA par 0 (jamais mariées) et créer une variable âge au mariage effectif
Data_clean$agefm[is.na(Data_clean$agefm)] <- 0

# c) Vérifier qu'il n'y a plus de NA dans les variables restantes (sauf éventuellement ?)
colSums(is.na(Data_clean))

# ------------------------------------------------------------
# 3. Création de variables supplémentaires utiles
# ------------------------------------------------------------
# Carré de l'âge (déjà présent mais on recalcule pour être sûr)
Data_clean$age2 <- Data_clean$age^2

# Interaction éducation * urbain (si besoin)
# On gardera urban et educ séparés dans un premier temps

# Pour la régression de Poisson, on peut aussi standardiser certaines variables, mais pas obligatoire.

# ------------------------------------------------------------
# 4. Division en échantillons d'apprentissage (80%) et test (20%)
# ------------------------------------------------------------
set.seed(123)  # pour reproductibilité
n <- nrow(Data_clean)
indices_train <- sample(1:n, size = floor(0.8 * n))
train_data <- Data_clean[indices_train, ]
test_data <- Data_clean[-indices_train, ]

# Vérifier les dimensions
dim(train_data)
dim(test_data)

# Afficher les premières lignes du jeu d'entraînement
head(train_data)


# Modèle de Poisson avec toutes les variables pertinentes
model_poisson <- glm(ceb ~ age + agesq + educ + evermarr + urban + 
                       electric + radio + tv + bicycle + knowmeth + usemeth + 
                       spirit + protest + catholic + mnthborn,
                     family = poisson(link = "log"), 
                     data = train_data)

# Résultats
summary(model_poisson)

# Paramètre de surdispersion (phi)
phi <- deviance(model_poisson) / df.residual(model_poisson)
phi

# Test de surdispersion (package AER)
install.packages("AER")
library(AER)
dispersiontest(model_poisson, trafo = 1)



# Étape 1 : Sélection automatique (stepwise) basée sur l'AIC
model_step <- step(model_poisson, direction = "both", trace = FALSE)
summary(model_step)

# Coefficients et odds ratios
coef_step <- coef(model_step)
exp_coef <- exp(coef_step)
exp_coef

# Intervalles de confiance des odds ratios
conf_int <- exp(confint(model_step))
conf_int

# Étape 2 : Prédictions sur l'échantillon test
test_data$pred_ceb <- predict(model_step, newdata = test_data, type = "response")

# Métriques de validation
# RMSE
rmse <- sqrt(mean((test_data$ceb - test_data$pred_ceb)^2))
rmse

# Corrélation entre prédictions et observations
cor_obs_pred <- cor(test_data$ceb, test_data$pred_ceb)
cor_obs_pred

# Courbe ROC (classification binaire : avoir au moins 1 enfant)
library(pROC)
roc_curve <- roc(test_data$ceb > 0, test_data$pred_ceb)
auc(roc_curve)
plot(roc_curve, main = "Courbe ROC - prédiction d'au moins 1 enfant",
     col = "blue", lwd = 2, print.auc = TRUE)



# 1. Test d'adéquation globale (déviance résiduelle)
# H0 : le modèle est bien spécifié
p_value_adequation <- pchisq(deviance(model_step), df.residual(model_step), lower.tail = FALSE)
p_value_adequation   # Si > 0.05, le modèle est adéquat

# 2. Paramètre de surdispersion
phi_step <- deviance(model_step) / df.residual(model_step)
phi_step   # proche de 1 -> pas de surdispersion

# 3. Analyse des résidus
res_pearson <- residuals(model_step, type = "pearson")
res_deviance <- residuals(model_step, type = "deviance")
pred <- fitted(model_step)

# Graphique résidus de Pearson vs valeurs prédites
plot(pred, res_pearson, 
     main = "Résidus de Pearson (modèle final)",
     xlab = "Valeurs prédites", ylab = "Résidus de Pearson")
abline(h = 0, col = "red", lty = 2)

# Q-Q plot des résidus de Pearson
qqnorm(res_pearson, main = "Q-Q plot (résidus de Pearson)")
qqline(res_pearson, col = "red")

# Histogramme des résidus déviants
hist(res_deviance, breaks = 30, 
     main = "Histogramme des résidus déviants",
     xlab = "Résidus déviants", probability = TRUE)
curve(dnorm(x, mean = mean(res_deviance), sd = sd(res_deviance)), 
      add = TRUE, col = "blue", lwd = 2)

# 4. Distance de Cook (points influents)
cook <- cooks.distance(model_step)
plot(cook, type = "h", main = "Distance de Cook", ylab = "Cook's distance")
abline(h = 4/length(cook), col = "red")

# 5. Prédictions sur l'échantillon test
test_data$pred_ceb <- predict(model_step, newdata = test_data, type = "response")

# Métriques de validation
rmse <- sqrt(mean((test_data$ceb - test_data$pred_ceb)^2))
rmse
cor_obs_pred <- cor(test_data$ceb, test_data$pred_ceb)
cor_obs_pred

# 6. Courbe ROC (classification : au moins 1 enfant)
library(pROC)
roc_curve <- roc(test_data$ceb > 0, test_data$pred_ceb)
auc(roc_curve)
plot(roc_curve, main = "Courbe ROC (modèle final)",
     col = "blue", lwd = 2, print.auc = TRUE)

# Après avoir estimé votre modèle (par exemple model_step)
# Pseudo-R² de McFadden = 1 - (log-vraisemblance du modèle) / (log-vraisemblance du modèle nul)
ll_model <- logLik(model_step)
ll_null <- logLik(glm(ceb ~ 1, family = poisson, data = train_data))
pseudo_r2 <- 1 - as.numeric(ll_model) / as.numeric(ll_null)
pseudo_r2
