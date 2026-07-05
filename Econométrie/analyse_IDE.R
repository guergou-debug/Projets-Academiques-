# ============================================================
# ANALYSE DES DÉTERMINANTS DES IDE AU MAROC (1996-2023)
# MÉTHODE : MOINDRES CARRÉS ORDINAIRES SUR VARIABLES STATIONNAIRES
# ============================================================

# 1. Packages
library(readxl)
library(dplyr)
library(tidyr)
library(zoo)
library(tseries)
library(lmtest)
library(ARDL)

# -----------------------------------------------------------------
# 2. Importation et préparation des données brutes
# -----------------------------------------------------------------
data <- read_excel("C:/Users/ADMIN/OneDrive/Bureau/Econometrie/Base IDE Maroc .xlsx", sheet = "Feuil1")
data <- data %>%
  rename(
    year      = année,
    IDE       = `IDE(% PIB)`,
    PIB_real  = `PIB réel Mlocal`,
    OUV       = OUV,
    KH        = KH,
    INFR      = INFR,
    COUT      = COUT,
    CRED      = `CRED(%PIB)`,
    INF_IPC   = `INF_Consumer(%)`,
    T_EXCH    = T_EXCH,
    STAB      = STAB,
    CORR      = Control_Corr
  ) %>%
  filter(year >= 1996, year <= 2023) %>%
  arrange(year)

# Interpolation des valeurs manquantes (KH, STAB, CORR)
data <- data %>%
  mutate(across(c(KH, STAB, CORR), ~ na.approx(.x, rule = 2, na.rm = FALSE)))



# -----------------------------------------------------------------
# 3. Transformation des variables
# -----------------------------------------------------------------

data <- data %>%
  mutate(
    lIDE      = log(IDE + 0.001),   # éviter log(0)
    lPIB      = log(PIB_real),
    lOUV      = log(OUV),
    lKH       = log(KH),
    lINFR     = log(INFR),
    lCOUT     = log(COUT),
    lCRED     = log(CRED + 0.001),
    lT_EXCH   = log(T_EXCH)
  )



# -----------------------------------------------------------------
# 4. Conversion en série temporelle
# -----------------------------------------------------------------

ts_data <- ts(data[, -1], start = 1996, frequency = 1)


# -----------------------------------------------------------------
# 5. Test ADF
# -----------------------------------------------------------------

library(tseries)

adf.test(data$lIDE)
adf.test(data$lPIB)
adf.test(data$lOUV)
adf.test(data$lCRED)
adf.test(data$INF_IPC)

adf.test(diff(data$lIDE))
adf.test(diff(data$lPIB))
adf.test(diff(data$lOUV))
adf.test(diff(data$lCRED))
adf.test(diff(data$INF_IPC))


# ============================================================
# SUITE : TESTS DE STATIONNARITÉ COMPLETS + ARDL FINAL
# ============================================================

library(urca)
library(tseries)
library(ARDL)
library(lmtest)

# -----------------------------------------------------------------
# 1. Liste des variables à tester (toutes, sauf gouvernance)
# -----------------------------------------------------------------
vars <- c("lIDE", "lPIB", "lOUV", "lKH", "lINFR", "lCOUT", "lCRED", "INF_IPC", "lT_EXCH")

# -----------------------------------------------------------------
# 2. Tests ADF et KPSS pour chaque variable
#    On construit un tableau récapitulatif
# -----------------------------------------------------------------
stationnarite <- data.frame()

for (v in vars) {
  # ADF
  adf_niv <- tryCatch(adf.test(data[[v]], k = 2)$p.value, error = function(e) NA)
  adf_dif <- tryCatch(adf.test(diff(data[[v]]), k = 2)$p.value, error = function(e) NA)
  
  # KPSS
  kpss_niv <- tryCatch(ur.kpss(data[[v]], type = "mu", lags = "short")@teststat[1], error = function(e) NA)
  kpss_dif <- tryCatch(ur.kpss(diff(data[[v]]), type = "mu", lags = "short")@teststat[1], error = function(e) NA)
  
  # Ordre d'intégration (logique maison)
  ordre <- NA
  if (!is.na(kpss_niv) & !is.na(kpss_dif)) {
    # Critère simplifié : si KPSS niveau < 0.463 (valeur critique 5 %) => I(0)
    # Sinon si KPSS diff < 0.463 => I(1), sinon I(2) probable
    if (kpss_niv < 0.463) {
      ordre <- "I(0)"
    } else if (kpss_dif < 0.463) {
      ordre <- "I(1)"
    } else {
      ordre <- "I(2) ou plus"
    }
  }
  
  stationnarite <- rbind(stationnarite, data.frame(
    Variable = v,
    ADF_niv   = round(adf_niv, 3),
    ADF_dif   = round(adf_dif, 3),
    KPSS_niv  = round(kpss_niv, 3),
    KPSS_dif  = round(kpss_dif, 3),
    Ordre     = ordre,
    stringsAsFactors = FALSE
  ))
}

cat("\n========== TABLEAU DE STATIONNARITÉ ==========\n")
print(stationnarite)

# -----------------------------------------------------------------
# 3. Sélection des variables acceptables (I(0) ou I(1) seulement)
# -----------------------------------------------------------------
acceptables <- stationnarite$Variable[stationnarite$Ordre %in% c("I(0)", "I(1)")]
exclues    <- stationnarite$Variable[stationnarite$Ordre == "I(2) ou plus"]

if(length(exclues) > 0) {
  cat("\nVariables exclues (I(2) ou plus) :", paste(exclues, collapse = ", "), "\n")
} else {
  cat("\nToutes les variables sont acceptables.\n")
}

# -----------------------------------------------------------------
# 4. Construction de la formule ARDL avec les variables acceptables
#    (on garde lIDE comme dépendante bien sûr)
# -----------------------------------------------------------------
regresseurs <- setdiff(acceptables, "lIDE")
formule_ardl <- as.formula(paste("lIDE ~", paste(regresseurs, collapse = " + ")))
cat("\nFormule utilisée :\n")
print(formule_ardl)

# -----------------------------------------------------------------
# 5. Estimation ARDL automatique (retards max 1 pour tous)
# -----------------------------------------------------------------
modele_ardl <- auto_ardl(formule_ardl, data = ts_data,
                         max_order = c(1, rep(1, length(regresseurs))),
                         selection = "AIC")
best_model <- modele_ardl$best_model
summary(best_model)

# -----------------------------------------------------------------
# 6. Bounds test
# -----------------------------------------------------------------
cat("\n========== BOUNDS TEST ==========\n")
btest <- bounds_f_test(best_model, case = 3)
print(btest)

# -----------------------------------------------------------------
# 7. Coefficients de long terme (avec p-values exactes)
# -----------------------------------------------------------------
coef_uecm <- coef(best_model)
vcov_uecm <- vcov(best_model)
ect_name <- "L(lIDE, 1)"
ect_coef <- coef_uecm[ect_name]

delta_ratio <- function(num, den, vcov, idx_num, idx_den) {
  ratio <- num / den
  gradient <- c(1/den, -num/(den^2))
  var_ratio <- t(gradient) %*% vcov[c(idx_num, idx_den), c(idx_num, idx_den)] %*% gradient
  se_ratio <- sqrt(var_ratio)
  t_stat <- ratio / se_ratio
  p_value <- 2 * pt(-abs(t_stat), df = best_model$df.residual)
  c(ratio = ratio, se = se_ratio, t = t_stat, p = p_value)
}

idx_niv <- grep("L\\(.*, 1\\)", names(coef_uecm))
idx_ect <- which(names(coef_uecm) == ect_name)

long_term_tab <- data.frame()
for (i in setdiff(idx_niv, idx_ect)) {
  var_name <- gsub("L\\(|, 1\\)", "", names(coef_uecm)[i])
  res <- delta_ratio(coef_uecm[i], -coef_uecm[idx_ect], vcov_uecm, i, idx_ect)
  long_term_tab <- rbind(long_term_tab,
                         data.frame(Variable = var_name,
                                    Coefficient = res[1],
                                    Std.Err = res[2],
                                    t.value = res[3],
                                    p.value = res[4]))
}
rownames(long_term_tab) <- NULL
cat("\n========== RELATION DE LONG TERME ==========\n")
print(long_term_tab)

# -----------------------------------------------------------------
# 8. Diagnostics finaux
# -----------------------------------------------------------------
res <- residuals(best_model)

cat("\n--- Breusch-Godfrey (autocorrélation) ---\n")
print(bgtest(best_model, order = 2))

cat("\n--- Breusch-Pagan (hétéroscédasticité) ---\n")
print(bptest(best_model))

cat("\n--- Jarque-Bera (normalité) ---\n")
print(jarque.bera.test(res))

plot(res, type = "l", main = "Résidus du modèle ARDL final")
abline(h = 0, lty = 2)



# Matrice de corrélation des régresseurs (en log ou niveau)
regs <- data[, c("lPIB", "lOUV", "lKH", "lINFR", "lCOUT", "lCRED", "INF_IPC", "lT_EXCH")]
cor(regs)

# VIF (sur une régression auxiliaire de lIDE en MCO, simples niveaux)
library(car)
modele_vif <- lm(lIDE ~ lPIB + lOUV + lKH + lINFR + lCOUT + lCRED + INF_IPC + lT_EXCH, data = data)
vif(modele_vif)


mA <- auto_ardl(lIDE ~ lPIB + lOUV, data = ts_data,
                max_order = c(2,2,2), selection = "AIC")
cat("\n========== Modèle A : lPIB + lOUV ==========\n")
summary(mA$best_model)
cat("AIC :", AIC(mA$best_model), "\n")
cat("--- Bounds test ---\n")
print(bounds_f_test(mA$best_model, case = 3))



mB <- auto_ardl(lIDE ~ lPIB + lKH, data = ts_data,
                max_order = c(2,2,2), selection = "AIC")
cat("\n========== Modèle B : lPIB + lKH ==========\n")
summary(mB$best_model)
cat("AIC :", AIC(mB$best_model), "\n")
cat("--- Bounds test ---\n")
print(bounds_f_test(mB$best_model, case = 3))


mC <- auto_ardl(lIDE ~ lPIB + lCOUT, data = ts_data,
                max_order = c(2,2,2), selection = "AIC")
cat("\n========== Modèle C : lPIB + lCOUT ==========\n")
summary(mC$best_model)
cat("AIC :", AIC(mC$best_model), "\n")
cat("--- Bounds test ---\n")
print(bounds_f_test(mC$best_model, case = 3))



mD <- auto_ardl(lIDE ~ lPIB + lT_EXCH, data = ts_data,
                max_order = c(2,2,2), selection = "AIC")
cat("\n========== Modèle D : lPIB + lT_EXCH ==========\n")
summary(mD$best_model)
cat("AIC :", AIC(mD$best_model), "\n")
cat("--- Bounds test ---\n")
print(bounds_f_test(mD$best_model, case = 3))





mE <- auto_ardl(lIDE ~ lOUV + lKH, data = ts_data,
                max_order = c(2,2,2), selection = "AIC")
cat("\n========== Modèle E : lOUV + lKH ==========\n")
summary(mE$best_model)
cat("AIC :", AIC(mE$best_model), "\n")
cat("--- Bounds test ---\n")
print(bounds_f_test(mE$best_model, case = 3))






mF <- auto_ardl(lIDE ~ lPIB + lOUV + lKH, data = ts_data,
                max_order = c(2,2,2,2), selection = "AIC")
cat("\n========== Modèle F : lPIB + lOUV + lKH ==========\n")
summary(mF$best_model)
cat("AIC :", AIC(mF$best_model), "\n")
cat("--- Bounds test ---\n")
print(bounds_f_test(mF$best_model, case = 3))



mG <- auto_ardl(lIDE ~ lPIB + lOUV + lCOUT, data = ts_data,
                max_order = c(2,2,2,2), selection = "AIC")
cat("\n========== Modèle G : lPIB + lOUV + lCOUT ==========\n")
summary(mG$best_model)
cat("AIC :", AIC(mG$best_model), "\n")
cat("--- Bounds test ---\n")
print(bounds_f_test(mG$best_model, case = 3))






mH <- auto_ardl(lIDE ~ lPIB + lOUV + lT_EXCH, data = ts_data,
                max_order = c(2,2,2,2), selection = "AIC")
cat("\n========== Modèle H : lPIB + lOUV + lT_EXCH ==========\n")
summary(mH$best_model)
cat("AIC :", AIC(mH$best_model), "\n")
cat("--- Bounds test ---\n")
print(bounds_f_test(mH$best_model, case = 3))















best_model <- mC$best_model

coef_uecm <- coef(best_model)
vcov_uecm <- vcov(best_model)

# Coefficient ECT
ect_name <- "L(lIDE, 1)"
ect_val <- coef_uecm[ect_name]

# Fonction delta pour calculer l'écart-type du ratio β = - (coef_niv / ect)
delta_ratio <- function(num, den, vcov, idx_num, idx_den) {
  ratio <- num / den
  gradient <- c(1/den, -num/(den^2))
  var_ratio <- t(gradient) %*% vcov[c(idx_num, idx_den), c(idx_num, idx_den)] %*% gradient
  se_ratio <- sqrt(var_ratio)
  t_stat <- ratio / se_ratio
  p_value <- 2 * pt(-abs(t_stat), df = best_model$df.residual)
  c(ratio = ratio, se = se_ratio, t = t_stat, p = p_value)
}

# Indices des coefficients de niveau (retardés d'une période)
idx_niv <- grep("L\\(.*, 1\\)", names(coef_uecm))
idx_ect <- which(names(coef_uecm) == ect_name)

long_term_tab <- data.frame()

for (i in setdiff(idx_niv, idx_ect)) {
  var_name <- gsub("L\\(|, 1\\)", "", names(coef_uecm)[i])
  res <- delta_ratio(coef_uecm[i], -coef_uecm[idx_ect], vcov_uecm, i, idx_ect)
  long_term_tab <- rbind(long_term_tab,
                         data.frame(Variable = var_name,
                                    Coefficient = res[1],
                                    Std.Err = res[2],
                                    t.value = res[3],
                                    p.value = res[4]))
}
rownames(long_term_tab) <- NULL

cat("\n========== RELATION DE LONG TERME ==========\n")
print(long_term_tab)


res <- residuals(best_model)

cat("\n--- Breusch-Godfrey (autocorrélation) ---\n")
print(bgtest(best_model, order = 2))

cat("\n--- Breusch-Pagan (hétéroscédasticité) ---\n")
print(bptest(best_model))

cat("\n--- Jarque-Bera (normalité) ---\n")
print(jarque.bera.test(res))

# Graphique des résidus
plot(res, type = "l", main = "Résidus du modèle C (lPIB + lCOUT)")
abline(h = 0, lty = 2)






# Extraire la relation de long terme avec coint_eq
long_run <- coint_eq(best_model, case = 3)

# Afficher le résumé (tableau des coefficients)
cat("\n========== RELATION DE LONG TERME (via coint_eq) ==========\n")
print(summary(long_run))











# Modèle M1 : lIDE ~ lPIB + lOUV, ARDL(1,0,0)
M1 <- ardl(lIDE ~ lPIB + lOUV, data = ts_data, order = c(1,0,0))
summary(M1)

# Coefficients de long terme
# ARDL(1,0,0) : lIDE_t = α + β1*lIDE_{t-1} + γ1*lPIB_t + γ2*lOUV_t + ε_t
# Long terme : lIDE* = (γ1/(1-β1)) * lPIB + (γ2/(1-β1)) * lOUV + constante
co <- coef(M1)
beta1 <- co["lIDE.L1"]            # coefficient de lIDE retardé
gamma1 <- co["lPIB"]               # contemporain lPIB
gamma2 <- co["lOUV"]               # contemporain lOUV

LR_lPIB <- gamma1 / (1 - beta1)
LR_lOUV <- gamma2 / (1 - beta1)

cat("Coefficient long terme lPIB :", round(LR_lPIB, 4), "\n")
cat("Coefficient long terme lOUV :", round(LR_lOUV, 4), "\n")

# Bounds test
bounds_f_test(M1, case = 3)



M2 <- ardl(lIDE ~ lPIB + lCOUT, data = ts_data, order = c(1,0,0))
summary(M2)

co <- coef(M2)
beta1 <- co["lIDE.L1"]
gamma1 <- co["lPIB"]
gamma2 <- co["lCOUT"]

LR_lPIB <- gamma1 / (1 - beta1)
LR_lCOUT <- gamma2 / (1 - beta1)

cat("Coefficient long terme lPIB :", round(LR_lPIB, 4), "\n")
cat("Coefficient long terme lCOUT :", round(LR_lCOUT, 4), "\n")

bounds_f_test(M2, case = 3)


M3 <- ardl(lIDE ~ lPIB + lT_EXCH, data = ts_data, order = c(1,0,0))
summary(M3)

co <- coef(M3)
beta1 <- co["lIDE.L1"]
gamma1 <- co["lPIB"]
gamma2 <- co["lT_EXCH"]

LR_lPIB <- gamma1 / (1 - beta1)
LR_lT_EXCH <- gamma2 / (1 - beta1)

cat("Coefficient long terme lPIB :", round(LR_lPIB, 4), "\n")
cat("Coefficient long terme lT_EXCH :", round(LR_lT_EXCH, 4), "\n")

bounds_f_test(M3, case = 3)









# Modèle déjà estimé : M2
best <- M2
co <- coef(best)
vc <- vcov(best)

# Récupération du coefficient du retard de lIDE
ect_name <- "L(lIDE, 1)"
beta1 <- co[ect_name]

# Coefficients contemporains
gamma_PIB  <- co["lPIB"]
gamma_COUT <- co["lCOUT"]

# Long terme : γ / (1 - β1)
LR_PIB  <- gamma_PIB / (1 - beta1)
LR_COUT <- gamma_COUT / (1 - beta1)

cat("Coefficient de long terme lPIB :", round(LR_PIB, 4), "\n")
cat("Coefficient de long terme lCOUT :", round(LR_COUT, 4), "\n")















# ============================================================
# MODÈLE COMPLET ARDL(1,0,0,0,0,0,0,0,0,0,0)
# 1 retard pour lIDE, 0 retard pour tous les régresseurs
# ============================================================

library(ARDL)

# Estimation du modèle complet
modele_complet <- ardl(
  lIDE ~ lPIB + lOUV + lKH + lINFR + lCOUT + lCRED + INF_IPC + lT_EXCH + STAB + CORR,
  data = ts_data,
  order = c(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)  # 1 retard pour lIDE, 0 pour chaque régresseur
)

# Résumé du modèle
summary(modele_complet)

# Bounds test
cat("\n========== BOUNDS TEST (modèle complet) ==========\n")
print(bounds_f_test(modele_complet, case = 3))

# Coefficients de long terme (calcul manuel)
co <- coef(modele_complet)
vc <- vcov(modele_complet)
ect_name <- "L(lIDE, 1)"

delta_long <- function(num_name, den_name, co, vc, df_resid) {
  num <- co[num_name]
  den <- 1 - co[den_name]
  ratio <- num / den
  grad <- c(1/den, num / den^2)
  idx_num <- which(names(co) == num_name)
  idx_den <- which(names(co) == den_name)
  cov_sub <- vc[c(idx_num, idx_den), c(idx_num, idx_den)]
  se <- sqrt(t(grad) %*% cov_sub %*% grad)
  t_val <- ratio / se
  p_val <- 2 * pt(-abs(t_val), df = df_resid)
  c(Coef = ratio, SE = se, t = t_val, p = p_val)
}

# Variables explicatives (toutes sauf l'intercept et l'ECT)
reg_names <- setdiff(names(co), c("(Intercept)", ect_name))

long_table <- data.frame()
for (nom in reg_names) {
  res <- delta_long(nom, ect_name, co, vc, modele_complet$df.residual)
  long_table <- rbind(long_table, data.frame(
    Variable = nom,
    Coefficient = res[1],
    Std.Error = res[2],
    t.value = res[3],
    p.value = res[4]
  ))
}
rownames(long_table) <- NULL

cat("\n========== RELATION DE LONG TERME (modèle complet) ==========\n")
print(long_table)

# Diagnostics
res <- residuals(modele_complet)

cat("\n--- Breusch-Godfrey (autocorrélation, ordre 2) ---\n")
print(bgtest(modele_complet, order = 2))

cat("\n--- Breusch-Pagan (hétéroscédasticité) ---\n")
print(bptest(modele_complet))

cat("\n--- Jarque-Bera (normalité) ---\n")
print(jarque.bera.test(res))









# Fonction delta pour un ratio γ / (1 - β1)
delta_long <- function(num_name, den_name, co, vc, df) {
  num <- co[num_name]
  den <- 1 - co[den_name]   # ici den = 1 - β1
  ratio <- num / den
  
  # Gradient : d(ratio)/d(num) = 1/den, d(ratio)/d(β1) = num / (den^2)
  grad <- c(1/den, num / (den^2))
  # Indices dans la matrice de variance-covariance
  idx_num <- which(names(co) == num_name)
  idx_den <- which(names(co) == den_name)
  cov_sub <- vc[c(idx_num, idx_den), c(idx_num, idx_den)]
  var_ratio <- t(grad) %*% cov_sub %*% grad
  se <- sqrt(var_ratio)
  t_val <- ratio / se
  p_val <- 2 * pt(-abs(t_val), df = df)
  c(Coef = ratio, SE = se, t = t_val, p = p_val)
}

# Calcul pour lPIB et lCOUT
res_PIB  <- delta_long("lPIB", ect_name, co, vc, best$df.residual)
res_COUT <- delta_long("lCOUT", ect_name, co, vc, best$df.residual)

# Tableau récapitulatif
long_table <- data.frame(
  Variable = c("lPIB", "lCOUT"),
  Coefficient = c(res_PIB[1], res_COUT[1]),
  Std.Error  = c(res_PIB[2], res_COUT[2]),
  t.value    = c(res_PIB[3], res_COUT[3]),
  p.value    = c(res_PIB[4], res_COUT[4])
)
rownames(long_table) <- NULL
cat("\n========== RELATION DE LONG TERME ==========\n")
print(long_table)



res <- residuals(best)

cat("\n--- Breusch-Godfrey (autocorrélation) ---\n")
print(bgtest(best, order = 2))

cat("\n--- Breusch-Pagan (hétéroscédasticité) ---\n")
print(bptest(best))

cat("\n--- Jarque-Bera (normalité) ---\n")
print(jarque.bera.test(res))

plot(res, type = "l", main = "Résidus du modèle M2 (lPIB + lCOUT)")
abline(h = 0, lty = 2)




# ============================================================
# Standardisation de STAB et CORR + ré-estimation du modèle complet
# ============================================================

library(dplyr)

# 1. Standardiser STAB et CORR (moyenne 0, écart-type 1)
data <- data %>%
  mutate(
    STAB_std = scale(STAB)[,1],
    CORR_std = scale(CORR)[,1]
  )

# 2. Mettre à jour l'objet ts_data avec les nouvelles variables
ts_data <- ts(data %>% select(-year), start = 1996, frequency = 1)

# 3. Ré-estimer le modèle complet ARDL(1,0,...,0) avec STAB_std et CORR_std
library(ARDL)

modele_complet1 <- ardl(
  lIDE ~ lPIB + lOUV + lKH + lINFR + lCOUT + lCRED + INF_IPC + lT_EXCH + STAB_std + CORR_std,
  data = ts_data,
  order = c(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
)




modele_00 <- 
  lm(lIDE ~ lPIB + lOUV + lKH + lINFR + lCOUT + lCRED + INF_IPC + lT_EXCH + STAB_std + CORR_std,data = data)


summary(modele_00)
