# MEGC Maroc 2023 : politique commerciale et ZLECAf

Modèle d'Équilibre Général Calculable (MEGC) statique du Maroc, calibré sur une Matrice de Comptabilité Sociale (MCS) 2023, pour comparer trois scénarios de politique tarifaire : protectionnisme, libéralisation totale et libéralisation régionale (Zone de Libre-Échange Continentale Africaine).

**Auteurs :** Anass BENHAMED et Abdoul-Samah GUERGOU GAGARA
**Encadrement :** Pr. Nouzha ZAOUJAL
**Cadre :** INSEA (Rabat), filière ESBD, module Modélisation Économique, année universitaire 2026 / 2027

---

## Question de recherche

Quels sont les effets macroéconomiques, sectoriels et sur le bien-être d'une libéralisation tarifaire régionale (ZLECAf), comparés à un repli protectionniste et à une ouverture mondiale totale ?

## Contenu du dossier

```
MEGC/
├── MCS_ZLECAF.gms            Calibration et validation du modèle de référence
├── MEGC_SIMULATIONS.gms      Calibration + 3 scénarios x 4 jeux d'élasticités
├── MCS_PCOM.xlsx             MCS 2023 (données d'entrée)
├── rapport_megc.tex          Rapport complet (LaTeX)
├── presentation_megc.tex     Présentation Beamer
├── INSEA_logo.png            Logo (facultatif, pour la page de titre)
└── README.md
```

Fichiers produits à l'exécution : `CALIB_REF.gdx`, `RESULTATS_SIM.gdx`, `RESULTATS_SIM.xlsx` et les fichiers `.lst`.

## Données

| Source | Usage |
|---|---|
| HCP, Tableau des Ressources et Emplois 2023 | Base de la MCS |
| HCP, Comptes nationaux 2023 à 2025 | Agrégats macroéconomiques |
| Office des Changes | Commerce extérieur par produit et par partenaire (ZLECAf, hors ZLECAf) |
| Trésorerie Générale du Royaume (TGR) | Droits de douane |
| Fichier VAL_PAR (Pr. Zaoujal) | Valeurs de certaines élasticités |
| GTAP | Consultation des paramètres et des règles de modélisation |

**MCS de travail :** 22 comptes, total de 11 137 562 MDH. Elle comprend 6 produits et activités (Primaire, Agro-textile, Chimie, Autres industries, Services marchands, Services non marchands), 2 facteurs (travail, capital), 3 institutions (sociétés, État, ménages), les droits de douane et les autres impôts, le compte de capital et un reste du monde scindé en ZLECAf et hors ZLECAf.

## Le modèle

- **Type :** statique, petite économie ouverte, de type IFPRI standard (Lofgren, Harris et Robinson, 2002).
- **Taille :** système carré de **140 équations et 140 inconnues**, résolu sous GAMS (type CNS, solveur CONOPT).
- **Production :** Leontief entre consommations intermédiaires et valeur ajoutée, CES travail-capital (σ = 0,8), production jointe.
- **Commerce :** transformation CET pour les exportations (ω = 2), Armington à deux niveaux (local ou importé, puis origine ZLECAf ou hors ZLECAf, avec σ^m = 2σ^q).
- **Ménages :** système linéaire de dépenses (LES, Stone-Geary), Frisch = -2,5, élasticités-revenu entre 0,6 et 1,3. Les services non marchands, de consommation négative dans la MCS, sont maintenus en volume fixe hors du LES.
- **Fermeture :** plein emploi avec facteurs mobiles, épargne étrangère fixe avec taux de change flexible, numéraire = indice des prix à la consommation, investissement tiré par l'épargne, demandes publique et des sociétés en volumes fixes.

### Validation du modèle de référence

| Test | Résultat |
|---|---|
| Statut du modèle / du solveur | 16 (résolu) / 1 (normal) |
| Écart maximal avec le benchmark | 2,2e-16 |
| Écart de Walras | 5,8e-11 MDH |
| Écart PIB production / demande | inférieur à 1e-6 |

## Scénarios

| Scénario | Description |
|---|---|
| S1 | Protectionnisme global : droits de douane multipliés par 1,2 |
| S2 | Libéralisation totale : suppression de tous les droits |
| S3 | Libéralisation ZLECAf : droits nuls pour l'Afrique, inchangés pour le reste du monde |

Chaque scénario est rejoué avec 4 jeux d'élasticités : **REF** (littérature), **LOW** (σ^q x 0,5), **HIGH** (σ^q x 2) et **ORIG1** (σ^m = σ^q), soit 16 simulations.

## Principaux résultats (cas REF, variation par rapport à 2023)

| | S1 | S2 | S3 |
|---|---|---|---|
| Variation équivalente (MDH) | -1 679 | +8 675 | +501 |
| Variation équivalente (% de la consommation) | -0,185 | +0,956 | +0,055 |
| Taux de change | -0,17 % | +0,90 % | +0,07 % |
| PIB réel | -0,016 % | +0,057 % | -0,002 % |
| Recettes douanières (MDH) | +2 926 | -15 577 | -799 |
| Investissement réel | +0,34 % | -1,82 % | -0,12 % |
| Importations depuis la ZLECAf | -0,71 % | +3,83 % | +17,68 % |

**À retenir :**
- Classement du bien-être : S2 > S3 > S1, robuste à tous les jeux d'élasticités.
- Les effets agrégés sont faibles car la protection initiale l'est (droit moyen de 2,1 %).
- Le véritable enjeu est budgétaire et sectoriel : recettes douanières, investissement, Agro-textile.
- Le détournement de trafic vers l'Afrique en S3 est très sensible aux élasticités (de +8 % à +40 %).
- Pas de désindustrialisation générale en S2 : Chimie et Autres industries exportatrices gagnent.

## Utilisation

**Prérequis :** GAMS (avec CONOPT) et le fichier `MCS_PCOM.xlsx`. L'export Excel des résultats utilise `gdxxrw`.

1. Adapter les chemins en tête des fichiers `.gms` (par défaut `C:\Projet_MEGC_Maroc\`).
2. Lancer `MCS_ZLECAF.gms` pour calibrer et valider le modèle de référence (génère `CALIB_REF.gdx`).
3. Lancer `MEGC_SIMULATIONS.gms` pour exécuter les 16 simulations (génère `RESULTATS_SIM.gdx` et `RESULTATS_SIM.xlsx`).
4. Compiler le rapport et la présentation avec `pdflatex` (deux passes pour les références).

Le programme s'interrompt avec un message d'erreur si un contrôle de cohérence échoue (équilibre de la MCS, reproduction de la valeur ajoutée, du LES ou du compte courant, échec d'une résolution).

## Limites et prolongements

**Limites :**
- Modèle statique, sans effets de croissance.
- Élasticités issues de la littérature et non estimées pour le Maroc.
- Droits identiques par origine au départ (paramètre `kappaZ` = 1).
- Parts d'exportation fixes entre destinations.
- Pas de baisse des droits des partenaires africains (réciprocité non simulée).
- Plein emploi : pas de chômage.

**Prolongements :**
- Simuler une ouverture réciproque de l'Afrique.
- Tester une fermeture alternative avec compensation fiscale de la perte de droits.
- Introduire des droits observés par origine.
- Raffiner la désagrégation sectorielle et ajouter une dimension dynamique.

## Références

- Armington, P. (1969). A Theory of Demand for Products Distinguished by Place of Production. *IMF Staff Papers*, 16(1).
- Dervis, K., de Melo, J. et Robinson, S. (1982). *General Equilibrium Models for Development Policy*. Cambridge University Press.
- Hertel, T. (1997). *Global Trade Analysis: Modeling and Applications*. Cambridge University Press.
- Lofgren, H., Harris, R. L. et Robinson, S. (2002). *A Standard Computable General Equilibrium (CGE) Model in GAMS*. IFPRI.
- Touitou, M. Introduction aux modèles d'équilibre général calculable. *Revue de droit et des sciences humaines, Études économiques*, n° 21, Université de Djelfa.
- Sources statistiques : HCP, Office des Changes, TGR, GTAP (voir la section Données).

## Licence et usage

Projet académique réalisé dans le cadre d'une formation à l'INSEA. Les données sont issues de sources publiques marocaines. Toute réutilisation doit citer les auteurs.
