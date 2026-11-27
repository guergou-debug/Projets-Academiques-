# MOROCCO-STAY
## Analyse économique et territoriale du marché de l'hébergement touristique au Maroc

**Auteur : Abdoul-Samah**  
**Technologies : R, R Shiny, statistiques descriptives, analyse économique, cartographie et données géospatiales**

---

## 1. Présentation du projet

**MOROCCO-STAY** est un projet indépendant d'analyse économique et territoriale consacré au marché de l'hébergement touristique au Maroc.

Il vise à étudier conjointement l'évolution de la demande touristique, les transformations de l'offre d'hébergement, les disparités entre destinations, la structure des marchés émetteurs et les effets descriptifs de la crise sanitaire de 2020.

Le projet s'appuie sur des données statistiques publiques issues du portail national des données ouvertes du Maroc et sur des données géographiques provenant d'OpenStreetMap (OSM).

Les données sont préparées et exploitées au moyen de méthodes statistiques et d'indicateurs économiques. Les résultats sont ensuite présentés dans une application interactive développée avec **R Shiny**, permettant d'explorer les différentes dimensions du marché touristique.

MOROCCO-STAY ne se limite donc pas à la visualisation de données : il propose un dispositif d'analyse et d'aide à la compréhension des dynamiques territoriales du secteur de l'hébergement touristique.

## 2. Problématique et objectifs

Le développement du tourisme dépend notamment de la capacité des territoires à attirer des visiteurs, à développer une offre d'hébergement adaptée et à maintenir une certaine adéquation entre la demande et les capacités disponibles.

Cependant, ces dynamiques ne sont pas nécessairement homogènes d'une destination à une autre.

L'étude s'organise autour de la question suivante :

> Dans quelle mesure les destinations touristiques marocaines présentent-elles des trajectoires différenciées en matière de demande, de capacité d'hébergement et de positionnement territorial, et comment ces dynamiques ont-elles été affectées par la crise sanitaire de 2020 ?

Les objectifs sont les suivants :

- Analyser l'évolution temporelle de la demande touristique.
- Étudier les transformations de la capacité d'hébergement.
- Comparer les performances et les profils des destinations.
- Examiner la répartition géographique de l'offre recensée.
- Mesurer la concentration et la spécialisation des marchés.
- Décrire les ruptures observées entre 2019 et 2020.
- Développer une interface interactive facilitant l'exploration des résultats.

## 3. Sources et données

L'étude repose principalement sur deux sources de données ouvertes.

### 3.1. Portail national des données ouvertes du Maroc

Les données statistiques touristiques proviennent du portail national des données ouvertes du Maroc, dans sa rubrique consacrée au tourisme :

**Source :** [data.gov.ma – Tourisme](https://data.gov.ma/data/fr/group/tourisme)

Les données exploitées portent notamment sur :

- Les nuitées touristiques par destination.
- Les capacités d'hébergement par destination.
- Les capacités selon les catégories d'établissements.
- Les nuitées selon les marchés émetteurs.
- Les arrivées selon la nationalité.
- Les arrivées selon les points d'entrée.

Ces données permettent de construire des séries temporelles et des indicateurs comparatifs sur la période disponible dans les fichiers exploités.

### 3.2. OpenStreetMap

Les données géographiques proviennent d'OpenStreetMap :

**Source :** [OpenStreetMap](https://www.openstreetmap.org/)

Elles sont utilisées pour identifier et cartographier des objets associés à l'hébergement touristique.

L'extraction réalisée porte sur quatre villes :

- Marrakech ;
- Casablanca ;
- Agadir ;
- Tanger.

La base géographique constituée comprend **1 646 objets recensés** :

| Ville | Nombre d'objets |
|---|---:|
| Marrakech | 1 068 |
| Casablanca | 201 |
| Agadir | 244 |
| Tanger | 133 |
| **Total** | **1 646** |

Les principales catégories d'objets retenues sont les hôtels, maisons d'hôtes, auberges, motels, appartements et complexes touristiques.

Les informations disponibles peuvent inclure le nom, le type d'hébergement, la localisation, le nombre d'étoiles, le nombre de chambres, l'opérateur et le site internet.

**Précaution :** les objets OSM ne correspondent pas nécessairement à des établissements actifs, distincts ou exhaustivement recensés. La couverture dépend de la contribution des utilisateurs et de la qualité des informations disponibles dans chaque ville.

Les données OpenStreetMap sont soumises à la licence Open Database License (ODbL). L'attribution aux contributeurs est à respecter : [OpenStreetMap Copyright](https://www.openstreetmap.org/copyright).

### 3.3. Organisation des données

Les données sont structurées en deux ensembles :

- `data/raw/` : données sources et extractions initiales ;
- `data/processed/` : bases nettoyées, harmonisées et indicateurs calculés.

Parmi les principaux fichiers exploités figurent :

| Fichier | Contenu |
|---|---|
| `tourism_destination.csv` | Nuitées par destination |
| `capacity_destination.csv` | Capacité en lits par destination |
| `capacity_category.csv` | Capacité par catégorie d'hébergement |
| `tourism_market_nights.csv` | Nuitées par marché émetteur |
| `arrivals_nationality.csv` | Arrivées par nationalité |
| `arrivals_entry_point.csv` | Arrivées par point d'entrée |
| `osm_accommodation.csv` | Inventaire géographique OSM |
| `panel_destination.csv` | Panel destination-année et indicateurs associés |
| `market_indicators.csv` | Indicateurs de structure des marchés |
| `growth_indicators.csv` | Indicateurs de croissance |
| `cagr_indicators.csv` | Taux de croissance annuels composés |
| `hhi_indicators.csv` | Indicateurs de concentration |
| `destination_positioning.csv` | Positionnement comparatif des destinations |
| `covid_destination_impact.csv` | Comparaison des destinations en 2019 et 2020 |
| `covid_market_impact.csv` | Évolution des marchés touristiques |
| `covid_aggregate_comparison.csv` | Comparaison agrégée de la demande et de la capacité |
| `covid_international_markets.csv` | Évolution des principaux marchés internationaux |

Les fichiers sont susceptibles d'être actualisés à mesure que le projet évolue.

## 4. Périmètre de l'étude

L'analyse couvre plusieurs dimensions complémentaires du marché touristique.

### 4.1. Dimension temporelle

Les principales séries statistiques par destination couvrent la période **2012–2020**.

Les comparaisons relatives à la crise sanitaire portent principalement sur les années 2019 et 2020.

### 4.2. Dimension territoriale

L'analyse comparative porte sur les destinations présentes dans les bases statistiques, avec une couverture qui varie selon les indicateurs.

La partie géographique fondée sur OpenStreetMap est limitée à quatre villes : Marrakech, Casablanca, Agadir et Tanger.

### 4.3. Dimension sectorielle

L'étude porte sur le marché de l'hébergement touristique dans son ensemble, et non exclusivement sur les locations de courte durée ou les annonces Airbnb.

## 5. Méthodologie et indicateurs

L'approche combine des statistiques descriptives, des indicateurs de structure de marché, des mesures de croissance, des comparaisons territoriales et des outils de cartographie.

### 5.1. Analyse de la demande touristique

L'évolution de la demande est étudiée à travers les nuitées et les arrivées touristiques.

Les analyses comprennent :

- Les évolutions annuelles ;
- Les variations absolues et relatives ;
- La répartition territoriale ;
- La structure des marchés émetteurs ;
- Les comparaisons entre demande nationale et internationale.

### 5.2. Analyse de la capacité d'hébergement

L'offre est appréhendée à partir du nombre de lits disponibles, selon les destinations et les catégories d'établissements.

L'objectif est de mesurer les transformations de la capacité d'hébergement et de comparer sa répartition à celle de la demande touristique.

Il convient de distinguer les lits, les chambres et les établissements : ces unités ne sont pas interchangeables.

### 5.3. Taux de croissance annuel composé (CAGR)

Le taux de croissance annuel composé permet de mesurer la croissance moyenne annuelle d'une variable entre deux périodes.

\[
CAGR=\left(\frac{V_T}{V_0}\right)^{\frac{1}{T}}-1
\]

où :

- \(V_0\) représente la valeur initiale ;
- \(V_T\) représente la valeur finale ;
- \(T\) représente le nombre d'années écoulées.

Cet indicateur facilite la comparaison des trajectoires de croissance des destinations.

Son interprétation nécessite de tenir compte des niveaux initiaux, notamment lorsque les valeurs de départ sont faibles.

### 5.4. Parts de marché

La part d'une destination dans la demande totale est calculée comme suit :

\[
Part_i=\frac{N_i}{\sum_j N_j}\times100
\]

où \(N_i\) représente le nombre de nuitées de la destination \(i\).

Une démarche similaire est appliquée à la capacité d'hébergement.

### 5.5. Proxy de pression sur la capacité

Un indicateur de pression relative sur la capacité est construit à partir des nuitées et des lits disponibles :

\[
P_i=\frac{N_i}{L_i\times365}
\]

où :

- \(N_i\) désigne le nombre annuel de nuitées ;
- \(L_i\) désigne le nombre de lits disponibles.

Cet indicateur rapporte les nuitées à une capacité théorique annuelle.

**Il ne constitue pas un taux officiel d'occupation hôtelière.** Il ne prend notamment pas en compte les variations infra-annuelles de capacité, les fermetures, les lits effectivement commercialisés ou les différences de couverture statistique.

Il doit donc être interprété comme un proxy comparatif de pression sur la capacité.

### 5.6. Quotient de localisation (Location Quotient)

Le quotient de localisation permet de comparer la spécialisation relative d'une destination en matière de demande par rapport à sa part dans la capacité d'hébergement.

\[
LQ_i=
\frac{N_i/N}{L_i/L}
\]

où :

- \(N_i\) désigne les nuitées de la destination ;
- \(N\) représente les nuitées totales du périmètre étudié ;
- \(L_i\) désigne sa capacité en lits ;
- \(L\) représente la capacité totale correspondante.

Interprétation :

- \(LQ_i>1\) : la part de la destination dans la demande est supérieure à sa part dans la capacité ;
- \(LQ_i<1\) : sa part dans la demande est inférieure à sa part dans la capacité ;
- \(LQ_i=1\) : les deux parts sont identiques.

Cet indicateur renseigne sur un positionnement relatif et ne mesure directement ni la rentabilité ni l'occupation effective.

### 5.7. Indice de concentration de Herfindahl-Hirschman (HHI)

L'indice HHI est utilisé pour étudier la concentration de la demande entre les destinations ou entre les marchés émetteurs.

\[
HHI=\sum_{i=1}^{n}s_i^2
\]

où \(s_i\) désigne la part de chaque composante dans le total, exprimée entre 0 et 1.

Une valeur plus élevée indique une concentration plus importante.

Les périmètres de calcul doivent être distingués : les indices calculés sur les destinations et ceux calculés sur les marchés internationaux ne sont pas directement comparables si leurs unités et leurs couvertures diffèrent.

### 5.8. Positionnement des destinations

Les destinations sont comparées selon leurs dynamiques de croissance et leur position relative dans le marché.

Une classification descriptive distingue notamment :

- Les leaders dynamiques ;
- Les marchés émergents ;
- Les destinations spécialisées à croissance modérée ;
- Les destinations en retrait relatif.

Cette classification est construite à partir de critères relatifs à l'échantillon étudié, notamment les médianes des indicateurs retenus. Elle ne constitue pas une typologie institutionnelle ou une notation absolue des destinations.

### 5.9. Analyse de la rupture liée à la Covid-19

La période 2019–2020 est étudiée à travers les variations des nuitées, de la capacité d'hébergement et de la structure des marchés.

L'analyse est descriptive. Elle permet d'observer l'ampleur et l'hétérogénéité des évolutions, mais ne permet pas d'isoler un effet causal de la pandémie.

### 5.10. Analyse géographique

Les objets OpenStreetMap sont exploités pour produire des visualisations cartographiques et examiner la distribution spatiale des hébergements recensés dans les quatre villes étudiées.

La couverture géographique et la qualité des attributs renseignés constituent des limites importantes de cette analyse.

## 6. Principaux résultats descriptifs

Les résultats ci-dessous correspondent aux bases exploitées dans la version actuelle du projet.

### 6.1. Évolution de la demande touristique

Pour les douze destinations comparables :

- Les nuitées passent de **22 772 936 en 2019** à **5 985 787 en 2020**.
- La variation correspond à une diminution de **73,7 %**.

Cette contraction illustre l'ampleur de la rupture observée en 2020.

### 6.2. Évolution de la capacité d'hébergement

Sur le même périmètre de douze destinations :

- La capacité passe de **201 231 lits en 2019** à **205 221 lits en 2020**.
- La variation correspond à une progression d'environ **1,98 %**.

La divergence entre l'évolution des nuitées et celle de la capacité met en évidence une forte modification de la relation entre demande et offre pendant la période étudiée.

### 6.3. Structure de la demande

En 2019 :

- Les nuitées des non-résidents représentent environ **69,0 %** du total considéré.
- Les nuitées des résidents représentent environ **31,0 %**.

Entre 2019 et 2020, les nuitées diminuent de :

- **80,1 %** pour les non-résidents ;
- **55,3 %** pour les résidents.

La part relative des résidents augmente ainsi à environ **50,3 %** en 2020, malgré la baisse de leurs nuitées en valeur absolue.

### 6.4. Marchés internationaux

Pour les marchés internationaux détaillés disponibles, la France, le Royaume-Uni et l'Allemagne figurent parmi les principaux marchés émetteurs en 2019.

Les trois premiers marchés représentent environ **67,2 %** du total des marchés détaillés considérés.

Ce périmètre ne couvre pas nécessairement l'ensemble des nuitées des non-résidents. Les parts calculées doivent donc être interprétées relativement au sous-ensemble de marchés documentés.

### 6.5. Positionnement territorial

Les résultats comparatifs de 2019 mettent notamment en évidence :

- Agadir : pression relative sur la capacité estimée à 41,3 % ;
- Rabat : 33,3 % ;
- El Jadida : 32,6 % ;
- Al Haouz : 32,1 % ;
- Marrakech : 31,3 %.

Ces valeurs correspondent au proxy défini dans l'étude et non à des taux officiels d'occupation.

Le quotient de localisation corrigé met notamment en évidence des valeurs supérieures à 1 pour Agadir, Rabat, El Jadida, Al Haouz et Marrakech.

### 6.6. Données géographiques

La base OpenStreetMap utilisée dans la version actuelle comprend 1 646 objets répartis entre quatre villes.

Marrakech concentre la majorité des objets recensés. Cette concentration doit toutefois être interprétée avec prudence, car elle peut refléter à la fois la densité de l'offre et des différences de couverture contributive d'OpenStreetMap.

## 7. Architecture de l'application

L'application R Shiny est organisée en modules thématiques permettant de naviguer entre les dimensions de l'étude.

| Module | Fonction |
|---|---|
| Vue d'ensemble | Présentation synthétique du marché et des indicateurs clés |
| Demande touristique | Analyse des nuitées et des arrivées |
| Offre d'hébergement | Analyse des capacités et des catégories |
| Concurrence et positionnement | Comparaisons entre destinations et indicateurs de spécialisation |
| Géographie touristique | Cartographie des objets d'hébergement issus d'OSM |
| Analyse Covid-19 | Comparaison descriptive des évolutions de 2019 à 2020 |
| Explorateur de données | Consultation et exploration des bases disponibles |
| Méthodologie | Documentation des sources, indicateurs, traitements et limites |

## 8. Technologies utilisées

Le projet mobilise principalement :

- **R** : préparation et analyse statistique des données ;
- **Shiny** : développement de l'application interactive ;
- **bslib** : structuration et présentation de l'interface ;
- **tidyverse** : manipulation et transformation des données ;
- **ggplot2** : visualisation statistique ;
- **leaflet** : cartographie interactive ;
- **sf** : manipulation de données spatiales ;
- **DT** : affichage interactif de tableaux ;
- **readr** : importation des données ;
- **dplyr** et **tidyr** : nettoyage et structuration.

La liste définitive des dépendances doit être vérifiée à partir des fichiers R de l'application.

## 9. Installation et lancement

### Prérequis

- R ;
- RStudio (recommandé) ;
- Les packages R nécessaires au fonctionnement de l'application.

### Installation des dépendances

Les dépendances peuvent être installées depuis la console R :

```r
install.packages(c(
  "shiny",
  "bslib",
  "tidyverse",
  "ggplot2",
  "leaflet",
  "sf",
  "DT",
  "readr",
  "dplyr",
  "tidyr"
))
```

D'autres packages peuvent être nécessaires selon les modules et les fonctions utilisés.

### Lancement

Depuis le répertoire racine du projet :

```r
shiny::runApp()
```

Le répertoire de travail doit correspondre au dossier contenant `app.R`.

## 10. Organisation du projet

```text
MOROCCO-STAY/
│
├── app.R
├── LancementDASHBOARDSHINY.R
│
├── R/
│   ├── 00_setup.R
│   ├── 01_data_loading.R
│   ├── 02_helpers.R
│   └── modules/
│       ├── mod_overview.R
│       ├── mod_demand.R
│       ├── mod_supply.R
│       ├── mod_competition.R
│       ├── mod_geography.R
│       ├── mod_covid.R
│       ├── mod_explorer.R
│       └── mod_methodology.R
│
├── data/
│   ├── raw/
│   └── processed/
│
├── outputs/
│   ├── audit/
│   ├── figures/
│   ├── maps/
│   ├── tables/
│   └── reports/
│
└── www/
```

L'arborescence peut évoluer avec les développements ultérieurs.

## 11. Reproductibilité et précautions d'interprétation

La reproductibilité repose sur la disponibilité des données sources, la documentation des traitements et l'accès au code de l'application.

Plusieurs précautions sont nécessaires :

1. Les valeurs manquantes ne doivent pas être assimilées automatiquement à des valeurs nulles.
2. Les agrégats statistiques ne doivent pas être additionnés à leurs composantes détaillées.
3. Les périmètres territoriaux peuvent varier selon les bases.
4. Les données OSM ne constituent pas un recensement exhaustif et certifié des établissements.
5. Le proxy de pression sur la capacité ne correspond pas à un taux officiel d'occupation.
6. Les comparaisons entre 2019 et 2020 sont descriptives et ne démontrent pas un effet causal.
7. Les indicateurs de concentration doivent être interprétés en fonction de leur périmètre de calcul.

Les sources, dates d'extraction et éventuelles transformations doivent être documentées pour chaque fichier de données.

## 12. Limites de l'étude

Les principales limites sont les suivantes :

- La disponibilité et l'homogénéité des statistiques selon les années et les territoires.
- La couverture partielle de certains marchés émetteurs détaillés.
- Les différences de périmètre entre les bases de demande et de capacité.
- La couverture géographique limitée de l'extraction OpenStreetMap.
- Le caractère imparfait des informations descriptives disponibles sur les objets géographiques.
- L'utilisation d'indicateurs descriptifs qui ne permettent pas, à eux seuls, d'établir des relations causales.

Ces limites doivent être prises en considération lors de l'interprétation des résultats.

## 13. Perspectives d'amélioration

Plusieurs prolongements peuvent être envisagés :

- Actualiser les séries statistiques avec les nouvelles données disponibles.
- Étendre l'analyse géographique à d'autres villes et régions.
- Enrichir les données géographiques avec des indicateurs socio-économiques et territoriaux.
- Introduire des méthodes d'analyse spatiale plus avancées.
- Développer des modèles de prévision de la demande touristique.
- Étudier les relations entre capacité, demande, accessibilité et attractivité territoriale.
- Ajouter des outils de comparaison et de simulation de scénarios.

## 14. Auteur et responsabilité scientifique

**MOROCCO-STAY est un projet conçu et développé par Abdoul-Samah.**

L'auteur a assuré la définition de la problématique, la collecte et la préparation des données, la construction des indicateurs, les analyses statistiques, les visualisations, la cartographie et le développement de l'application interactive.

Les sources de données demeurent la propriété de leurs producteurs respectifs et leur réutilisation est soumise à leurs conditions de licence.

### Références des sources

- OpenStreetMap : https://www.openstreetmap.org/
- OpenStreetMap – Copyright et licence : https://www.openstreetmap.org/copyright
- Portail national des données ouvertes du Maroc – Tourisme : https://data.gov.ma/data/fr/group/tourisme

---

*Dernière mise à jour : novembre 2026.*
