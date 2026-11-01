$title MEGC Maroc 2023 - ZLECAf - Calibration du modele de reference (sans choc)

$onText
=====================================================================
 MEGC MAROC : POLITIQUE COMMERCIALE ET ZLECAf
 VERSION : CALIBRATION COMPLETE DU MODELE DE REFERENCE (AUCUN CHOC)
=====================================================================
 Plan
   1. Ensembles
   2. Import de la MCS et verification d'equilibre
   3. MCS de travail (retraitements transparents) + controles de structure
   4. Flux commerciaux, droits de douane, taxes
   5. Production : Leontief (CI) / CES (VA) / production jointe
   6. Commerce : Armington (D/M), nid d'origine (ZLECAf/Hors), CET (X/D)
   7. Demande finale : LES (menages), Etat, investissement
   8. Institutions, transferts, epargne, compte exterieur
   9. Indicateurs macro et structurels de reference
  10. Modele (equations) + test de replication du benchmark
  11. Controles de validation et export

 HYPOTHESES PRINCIPALES 
  H1  Prix de reference = 1 ; prix des importations tarif-inclusif PM0 = 1+tm ;
      quantites = valeurs de la MCS (MDH).
  H2  Droits de douane (TAX_DD) repartis par origine au prorata des
      importations (kappaZ = 1). Donc tm_ZLEC = tm_HORS au benchmark.
  H3  Production : Leontief entre CI et VA ; VA = CES travail-capital ;
      production jointe via la matrice Theta (activite -> produits).
  H4  Importations : Armington D/M (niveau 1) puis nid d'origine
      ZLECAf/Hors-ZLECAf (niveau 2, sigma2 = 2 x sigma1).
  H5  Exportations : CET production/exportation ; petit pays preneur de
      prix (prix mondiaux fixes) ; repartition ZLECAf/Hors fixe.
  H6  Menages : LES (Stone-Geary) calibree avec Frisch et elasticites-revenu.
      Flux P_SERVN negatif dans la MCS = volume fixe hors LES.
  H7  Etat et societes : volumes reels de demande fixes ; investissement
      en proportions fixes (facteur IADJ).
  H8  Fermetures : facteurs en plein emploi et mobiles ; epargne etrangere
      fixe ; taux de change flexible ; IPC = numeraire ; epargne menages =
      taux fixe, epargne Etat/societes = residu ; investissement tire par
      l'epargne (verification de Walras apres resolution).
  H9  Flux internes des institutions (diagonale INST x INST) consolides.
$offText


* ============================================================
* 1. ENSEMBLES
* ============================================================

Sets
    a   "Comptes de la MCS"
        / P_PRIM, P_AGRTEX, P_CHIM, P_AUTIND, P_SERVM, P_SERVN
          A_PRIM, A_AGRTEX, A_CHIM, A_AUTIND, A_SERVM, A_SERVN
          F_TRAV, F_CAP
          INST_SOC, INST_APU, INST_MEN
          TAX_DD, TAX_AUT, CAP_INV
          RDM_ZLECAf, RDM_HORS /

    p(a)    "Comptes de produits"
        / P_PRIM, P_AGRTEX, P_CHIM, P_AUTIND, P_SERVM, P_SERVN /

    act(a)  "Comptes d'activites"
        / A_PRIM, A_AGRTEX, A_CHIM, A_AUTIND, A_SERVM, A_SERVN /

    f(a)    "Facteurs de production"
        / F_TRAV, F_CAP /

    inst(a) "Institutions"
        / INST_SOC, INST_APU, INST_MEN /

    tax(a)  "Comptes de taxes"
        / TAX_DD, TAX_AUT /

    ext(a)  "Comptes du reste du monde"
        / RDM_ZLECAf, RDM_HORS /;

Alias (a, ap);
Alias (p, pp);
Alias (f, f2);
Alias (inst, inst2);
Alias (act, act2);


* ============================================================
* 2. IMPORTATION DE LA MCS ET VERIFICATION
* Convention : lignes = recettes, colonnes = depenses.
* ============================================================

Parameter
    MCS(a,ap)     "MCS 2023 importee (jamais modifiee)"
    Recettes(a)   "Total des recettes par compte"
    Depenses(a)   "Total des depenses par compte"
    Ecart(a)      "Ecart comptable par compte";

Scalar
    EcartMax      "Ecart comptable maximal"
    TotalMCS      "Total des ressources de la MCS (MDH)";

$call gdxxrw.exe "C:\Projet_MEGC_Maroc\MCS_PCOM.xlsx" output="C:\Projet_MEGC_Maroc\MCS.gdx" par=MCS rng=MCS-ZLECAF!A1:W23 rdim=1 cdim=1

$if not exist "C:\Projet_MEGC_Maroc\MCS.gdx" $abort "Fichier GDX non cree : verifier Excel, GDXXRW et la plage"

$gdxin "C:\Projet_MEGC_Maroc\MCS.gdx"
$load MCS
$gdxin

Recettes(a) = sum(ap, MCS(a,ap));
Depenses(a) = sum(ap, MCS(ap,a));
Ecart(a)    = Recettes(a) - Depenses(a);
EcartMax    = smax(a, abs(Ecart(a)));
TotalMCS    = sum(a, Recettes(a));

Display TotalMCS, EcartMax;

abort$(EcartMax > 0.01) "ERREUR : la MCS importee n'est pas equilibree";


* ============================================================
* 3. MCS DE TRAVAIL (retraitements transparents, MCS originale intacte)
*   3.1 impots directs eventuels reclasses vers l'Etat
*   3.2 consolidation des flux internes des institutions (diagonale)
* ============================================================

Parameter
    SAMW(a,ap)        "MCS de travail"
    ImpDirects(a)     "Impots directs payes via TAX_AUT / TAX_DD par institutions ou facteurs"
    FluxInternes(a)   "Flux internes des institutions retires (diagonale)"
    RecW(a)           "Recettes MCS de travail"
    DepW(a)           "Depenses MCS de travail"
    EcartW(a)         "Ecart MCS de travail";

Scalar
    ImpDirTotAUT      "Total impots directs transitant par TAX_AUT"
    ImpDirTotDD       "Total impots directs transitant par TAX_DD"
    EcartMaxW         "Ecart maximal MCS de travail"
    TotalMCSW         "Total des ressources MCS de travail";

SAMW(a,ap) = MCS(a,ap);

* 3.1 Les taxes payees par institutions/facteurs sont versees directement a l'Etat
ImpDirects(a)$(inst(a) or f(a)) = SAMW('TAX_AUT',a) + SAMW('TAX_DD',a);
ImpDirTotAUT = sum(a$(inst(a) or f(a)), SAMW('TAX_AUT',a));
ImpDirTotDD  = sum(a$(inst(a) or f(a)), SAMW('TAX_DD',a));

SAMW('INST_APU',a)$(inst(a) or f(a)) = SAMW('INST_APU',a) + ImpDirects(a);
SAMW('INST_APU','TAX_AUT') = SAMW('INST_APU','TAX_AUT') - ImpDirTotAUT;
SAMW('INST_APU','TAX_DD')  = SAMW('INST_APU','TAX_DD')  - ImpDirTotDD;
SAMW('TAX_AUT',a)$(inst(a) or f(a)) = 0;
SAMW('TAX_DD',a)$(inst(a) or f(a))  = 0;

* 3.2 Flux internes des institutions (INST_MEN->INST_MEN, INST_APU->INST_APU, ...)
FluxInternes(inst) = SAMW(inst,inst);
SAMW(inst,inst)    = 0;

RecW(a)  = sum(ap, SAMW(a,ap));
DepW(a)  = sum(ap, SAMW(ap,a));
EcartW(a) = RecW(a) - DepW(a);
EcartMaxW = smax(a, abs(EcartW(a)));
TotalMCSW = sum(a, RecW(a));

Display ImpDirTotAUT, ImpDirTotDD, FluxInternes, EcartMaxW, TotalMCSW;

abort$(EcartMaxW > 0.01) "ERREUR : la MCS de travail n'est pas equilibree";

* --- 3.3 Controles de structure (tous doivent etre nuls) ---
Set chk "Controles de structure"
    / c01*c16 /;

Parameter ViolStruct(chk) "Violations de la structure attendue";

* activites : ventes uniquement vers produits
ViolStruct('c01') = sum((act,a)$(not p(a)), abs(SAMW(act,a)));
* activites : couts = CI (produits) + facteurs + TAX_AUT
ViolStruct('c02') = sum((a,act)$(not p(a) and not f(a) and not sameas(a,'TAX_AUT')), abs(SAMW(a,act)));
* produits : recettes = CI, demande finale, investissement, exportations, marges
ViolStruct('c03') = sum((p,a)$(not act(a) and not inst(a) and not ext(a) and not p(a) and not sameas(a,'CAP_INV')), abs(SAMW(p,a)));
* produits : couts = production, importations, taxes, marges
ViolStruct('c04') = sum((a,p)$(not act(a) and not ext(a) and not tax(a) and not p(a)), abs(SAMW(a,p)));
* facteurs : recettes uniquement des activites
ViolStruct('c05') = sum((f,a)$(not act(a)), abs(SAMW(f,a)));
* facteurs : revenus verses aux institutions et au reste du monde
ViolStruct('c06') = sum((a,f)$(not inst(a) and not ext(a)), abs(SAMW(a,f)));
* institutions : recettes (facteurs, institutions, RDM, taxes)
ViolStruct('c07') = sum((inst,a)$(not f(a) and not inst(a) and not ext(a) and not tax(a)), abs(SAMW(inst,a)));
* seule l'Etat recoit les taxes
ViolStruct('c08') = sum((inst,tax)$(not sameas(inst,'INST_APU')), abs(SAMW(inst,tax)));
* institutions : depenses (produits, institutions, RDM, epargne)
ViolStruct('c09') = sum((a,inst)$(not p(a) and not inst(a) and not ext(a) and not sameas(a,'CAP_INV')), abs(SAMW(a,inst)));
* taxes : recettes uniquement des produits et activites
ViolStruct('c10') = sum((tax,a)$(not p(a) and not act(a)), abs(SAMW(tax,a)));
* droits de douane : uniquement sur les produits
ViolStruct('c11') = sum(act, abs(SAMW('TAX_DD',act)));
* taxes : reversees uniquement a l'Etat
ViolStruct('c12') = sum(a$(not sameas(a,'INST_APU')), abs(SAMW(a,'TAX_AUT')) + abs(SAMW(a,'TAX_DD')));
* CAP_INV : recettes des institutions et du RDM seulement
ViolStruct('c13') = sum(a$(not inst(a) and not ext(a)), abs(SAMW('CAP_INV',a)));
* CAP_INV : depenses vers les produits seulement
ViolStruct('c14') = sum(a$(not p(a)), abs(SAMW(a,'CAP_INV')));
* RDM : recettes (importations, transferts, revenus des facteurs)
ViolStruct('c15') = sum((ext,a)$(not p(a) and not inst(a) and not f(a)), abs(SAMW(ext,a)));
* RDM : depenses (exportations, transferts, epargne etrangere)
ViolStruct('c16') = sum((a,ext)$(not p(a) and not inst(a) and not sameas(a,'CAP_INV')), abs(SAMW(a,ext)));

Display ViolStruct;

abort$(smax(chk, ViolStruct(chk)) > 0.01)
    "ERREUR : structure de la MCS differente de celle supposee par le modele (voir ViolStruct)";


* ============================================================
* 4. FLUX COMMERCIAUX, DROITS DE DOUANE, TAXES
* ============================================================

Parameter
    M_ZLEC(p)       "Importations depuis la ZLECAf (cif)"
    M_HORS(p)       "Importations depuis le reste du monde (cif)"
    X_ZLEC(p)       "Exportations vers la ZLECAf (fob)"
    X_HORS(p)       "Exportations vers le reste du monde (fob)"
    M_TOTAL(p)      "Importations totales"
    X_TOTAL(p)      "Exportations totales"
    DD(p)           "Droits de douane par produit"
    TaxProd(p)      "Taxes sur les produits (TAX_AUT, colonne produit)"
    TaxAct(act)     "Taxes sur la production (TAX_AUT, colonne activite)"

    Part_ZLEC(p)    "Part de la ZLECAf dans les importations"
    DD_ZLEC(p)      "Droits attribues aux importations ZLECAf"
    DD_HORS(p)      "Droits attribues aux autres importations"
    tm_ZLEC(p)      "Taux tarifaire de reference ZLECAf"
    tm_HORS(p)      "Taux tarifaire de reference hors ZLECAf"
    tm_MOY(p)       "Taux tarifaire apparent moyen"
    pwmZ(p)         "Prix mondial des importations ZLECAf"
    pwmH(p)         "Prix mondial des importations hors ZLECAf"
    pweZ(p)         "Prix mondial des exportations vers la ZLECAf"
    pweH(p)         "Prix mondial des exportations hors ZLECAf";

Scalar
    kappaZ        "Intensite tarifaire relative des importations ZLECAf (1 = proportionnelle)" /1/
    Controle_DD   "Controle de la repartition des droits"
    ControleTax   "Controle des taxes TAX_AUT";

M_ZLEC(p) = SAMW('RDM_ZLECAf',p);
M_HORS(p) = SAMW('RDM_HORS',p);
X_ZLEC(p) = SAMW(p,'RDM_ZLECAf');
X_HORS(p) = SAMW(p,'RDM_HORS');
M_TOTAL(p) = M_ZLEC(p) + M_HORS(p);
X_TOTAL(p) = X_ZLEC(p) + X_HORS(p);
DD(p)      = SAMW('TAX_DD',p);
TaxProd(p) = SAMW('TAX_AUT',p);
TaxAct(act) = SAMW('TAX_AUT',act);

abort$(smin(p, M_ZLEC(p)) <= 0 or smin(p, M_HORS(p)) <= 0 or smin(p, X_ZLEC(p)) <= 0 or smin(p, X_HORS(p)) <= 0)
    "ERREUR : flux commerciaux nuls ou negatifs (nids CES/CET impossibles)";

ControleTax = sum(p, TaxProd(p)) + sum(act, TaxAct(act)) - SAMW('INST_APU','TAX_AUT');
abort$(abs(ControleTax) > 0.01) "ERREUR : TAX_AUT ne se retrouve pas dans produits + activites";

* Repartition des droits par origine (H2). kappaZ = 1 : au prorata des importations
DD_ZLEC(p) = 0;
DD_ZLEC(p)$(DD(p) > 0) = DD(p)*kappaZ*M_ZLEC(p)/(kappaZ*M_ZLEC(p) + M_HORS(p));
DD_HORS(p) = DD(p) - DD_ZLEC(p);

Part_ZLEC(p) = M_ZLEC(p)/M_TOTAL(p);

tm_ZLEC(p) = DD_ZLEC(p)/M_ZLEC(p);
tm_HORS(p) = DD_HORS(p)/M_HORS(p);
tm_MOY(p)  = DD(p)/M_TOTAL(p);

pwmZ(p) = 1;  pwmH(p) = 1;  pweZ(p) = 1;  pweH(p) = 1;

Controle_DD = sum(p, DD_ZLEC(p) + DD_HORS(p)) - sum(p, DD(p));
abort$(abs(Controle_DD) > 0.01) "ERREUR : la repartition ne conserve pas les droits de douane";

Display M_ZLEC, M_HORS, X_ZLEC, X_HORS, DD, TaxProd, TaxAct;
Display Part_ZLEC, DD_ZLEC, DD_HORS, tm_ZLEC, tm_HORS, tm_MOY, Controle_DD;


* ============================================================
* 5. PRODUCTION
* ============================================================
* Elasticite de substitution travail-capital (litterature ; a referencer)

Parameter
    SigmaVA(act)  "Elasticite de substitution travail-capital"
        / A_PRIM 0.8, A_AGRTEX 0.8, A_CHIM 0.8, A_AUTIND 0.8, A_SERVM 0.8, A_SERVN 0.8 /

    ProdRef(act)      "Production de reference (prix de base)"
    CIRef(p,act)      "Consommations intermediaires (prix acheteur)"
    CI_Total(act)     "CI totales"
    FactRef(f,act)    "Utilisation des facteurs"
    VARef(act)        "Valeur ajoutee"
    Ica(p,act)        "Coefficients techniques de CI"
    Iva(act)          "Coefficient de valeur ajoutee"
    TxAct(act)        "Taux de taxe sur la production"
    Theta(act,p)      "Part du produit p dans la production de l'activite act"
    ControleCouts(act) "Controle des parts de cout (doit etre nul)"
    PartFact(f,act)   "Parts des facteurs dans la VA"

    RhoVA(act)        "Exposant CES"
    DeltaVA(act)      "Parametre de partage CES (travail)"
    DeltaF(f,act)     "Parametre de partage CES par facteur"
    ScaleVA(act)      "Parametre d'echelle CES"
    AggVARef(act)     "Agregateur CES au point de reference"
    EcartVA_CES(act)  "Ecart de reproduction de la VA";

Scalar
    EcartMaxVA_CES    "Ecart maximal de reproduction CES";

ProdRef(act) = sum(p, SAMW(act,p));
abort$(smin(act, ProdRef(act)) <= 0) "ERREUR : production nulle ou negative";

CIRef(p,act)   = SAMW(p,act);
CI_Total(act)  = sum(p, CIRef(p,act));
FactRef(f,act) = SAMW(f,act);
VARef(act)     = sum(f, FactRef(f,act));

Ica(p,act) = CIRef(p,act)/ProdRef(act);
Iva(act)   = VARef(act)/ProdRef(act);
TxAct(act) = TaxAct(act)/ProdRef(act);
Theta(act,p) = SAMW(act,p)/ProdRef(act);
PartFact(f,act) = FactRef(f,act)/VARef(act);

ControleCouts(act) = sum(p, Ica(p,act)) + Iva(act) + TxAct(act) - 1;
abort$(smax(act, abs(ControleCouts(act))) > 1e-6)
    "ERREUR : CI + VA + taxe ne couvrent pas la production d'une activite";

abort$(smin(act, sum(f, FactRef(f,act))) <= 0 or smin((f,act), FactRef(f,act)) <= 0)
    "ERREUR : facteur nul ou negatif dans une activite (CES impossible)";

abort$(smin(act, abs(SigmaVA(act) - 1)) < 1e-6 or smin(act, SigmaVA(act)) <= 0)
    "ERREUR : sigma VA egal a 1 ou non positif (formulation CES impossible)";

RhoVA(act) = (SigmaVA(act) - 1)/SigmaVA(act);

DeltaVA(act) =
    (PartFact('F_TRAV',act)*FactRef('F_CAP',act)**RhoVA(act))
    /
    (PartFact('F_TRAV',act)*FactRef('F_CAP',act)**RhoVA(act)
     + PartFact('F_CAP',act)*FactRef('F_TRAV',act)**RhoVA(act));

DeltaF('F_TRAV',act) = DeltaVA(act);
DeltaF('F_CAP',act)  = 1 - DeltaVA(act);

AggVARef(act) = sum(f, DeltaF(f,act)*FactRef(f,act)**RhoVA(act))**(1/RhoVA(act));
ScaleVA(act)  = VARef(act)/AggVARef(act);

EcartVA_CES(act) = ScaleVA(act)*AggVARef(act) - VARef(act);
EcartMaxVA_CES   = smax(act, abs(EcartVA_CES(act)));
abort$(EcartMaxVA_CES > 0.01) "ERREUR : la CES ne reproduit pas la valeur ajoutee";

Display ProdRef, CI_Total, VARef, Ica, Iva, TxAct, Theta, PartFact;
Display SigmaVA, RhoVA, DeltaVA, ScaleVA, EcartMaxVA_CES;


* ============================================================
* 6. COMMERCE : Armington, nid d'origine, CET
* ============================================================
* Elasticites tirees de la litterature - A REFERENCER dans le rapport.
* Valeurs de travail : ordre de grandeur GTAP / Hertel et al. / Loefgren et al.
* (2002). Convention GTAP : sigma d'origine = 2 x sigma Armington D/M.

Parameter
    SigArm(p)  "Elasticite d'Armington domestique/importe (niveau 1)"
        / P_PRIM 2.5, P_AGRTEX 3.0, P_CHIM 3.3, P_AUTIND 3.5, P_SERVM 1.9, P_SERVN 1.9 /

    OmegaX(p)  "Elasticite de transformation CET (production/exportation)"
        / P_PRIM 2.0, P_AGRTEX 2.0, P_CHIM 2.0, P_AUTIND 2.0, P_SERVM 2.0, P_SERVN 2.0 /;

Parameter
    SigM(p)     "Elasticite d'origine ZLECAf/Hors (niveau 2)"
    RhoQ(p)     "Exposant Armington"
    RhoM(p)     "Exposant CES d'origine"
    RhoX(p)     "Exposant CET"

    QD0(p)      "Ventes domestiques de reference"
    QE0(p)      "Exportations de reference"
    QX0(p)      "Production domestique par produit"
    QM0(p)      "Importations de reference (cif)"
    QMZ0(p)     "Importations ZLECAf de reference"
    QMH0(p)     "Importations hors ZLECAf de reference"
    PMZ0(p)     "Prix import ZLECAf tarif-inclusif"
    PMH0(p)     "Prix import hors ZLECAf tarif-inclusif"
    PM0(p)      "Prix import agrege tarif-inclusif"
    PD0(p)      "Prix domestique de reference"
    PE0(p)      "Prix export de reference"
    MargRec(p)  "Marges payees par le produit p (couts)"
    Absorp(p)   "Absorption domestique au prix acheteur (QQ0)"
    QQ0(p)      "Offre composite de reference"
    BaseCost(p) "Base de calcul de la taxe produit"
    tq(p)       "Taux de taxe sur les produits"
    Mc(p,pp)    "Marge du produit p (fournisseur) par unite de QQ du produit pp (utilisateur)"

    DQ(p)       "Parametre de partage Armington (importations)"
    AQ(p)       "Parametre d'echelle Armington"
    DM(p)       "Parametre de partage origine (ZLECAf)"
    AM(p)       "Parametre d'echelle origine"
    GamX(p)     "Parametre de partage CET (exportations)"
    AtX(p)      "Parametre d'echelle CET"
    ShXZ(p)     "Part des exportations vers la ZLECAf"

    tmZ(p)      "Taux tarifaire ZLECAf utilise par le modele (modifiable pour les chocs)"
    tmH(p)      "Taux tarifaire hors ZLECAf utilise par le modele"

    EcartPQ(p)   "Controle prix acheteur"
    EcartARM(p)  "Controle Armington"
    EcartMCES(p) "Controle CES d'origine"
    EcartCET(p)  "Controle CET";

QD0(p) = sum(act, SAMW(act,p)) - X_TOTAL(p);
abort$(smin(p, QD0(p)) <= 0) "ERREUR : ventes domestiques nulles ou negatives pour un produit";

QE0(p)  = X_TOTAL(p);
QX0(p)  = QD0(p) + QE0(p);
QM0(p)  = M_TOTAL(p);
QMZ0(p) = M_ZLEC(p);
QMH0(p) = M_HORS(p);
PD0(p)  = 1;
PE0(p)  = 1;

tmZ(p) = tm_ZLEC(p);
tmH(p) = tm_HORS(p);

PMZ0(p) = pwmZ(p)*(1 + tmZ(p));
PMH0(p) = pwmH(p)*(1 + tmH(p));
PM0(p)  = (PMZ0(p)*QMZ0(p) + PMH0(p)*QMH0(p))/QM0(p);

MargRec(p) = sum(pp, SAMW(pp,p));
Absorp(p)  = sum(a, SAMW(p,a)) - X_TOTAL(p);
QQ0(p)     = Absorp(p);
BaseCost(p) = QD0(p)*PD0(p) + PM0(p)*QM0(p) + MargRec(p);
tq(p)      = TaxProd(p)/BaseCost(p);
Mc(pp,p)   = SAMW(pp,p)/QQ0(p);

EcartPQ(p) = Absorp(p) - (BaseCost(p) + TaxProd(p));
Display EcartPQ;
abort$(smax(p, abs(EcartPQ(p))) > 0.01)
    "ERREUR : le compte produit n'est pas reproduit (domestique + import + droits + taxes + marges)";

abort$(smin(p, abs(SigArm(p) - 1)) < 1e-6 or smin(p, abs(OmegaX(p))) < 1e-6)
    "ERREUR : elasticite egale a 1 (Armington) ou nulle (CET) interdite par la formulation";

* --- Armington niveau 1 (domestique / importe)
RhoQ(p) = (SigArm(p) - 1)/SigArm(p);
DQ(p)   = PM0(p)*QM0(p)**(1 - RhoQ(p))
          /(PM0(p)*QM0(p)**(1 - RhoQ(p)) + PD0(p)*QD0(p)**(1 - RhoQ(p)));
AQ(p)   = QQ0(p)/(DQ(p)*QM0(p)**RhoQ(p) + (1 - DQ(p))*QD0(p)**RhoQ(p))**(1/RhoQ(p));
EcartARM(p) = AQ(p)*(DQ(p)*QM0(p)**RhoQ(p) + (1 - DQ(p))*QD0(p)**RhoQ(p))**(1/RhoQ(p)) - QQ0(p);

* --- Armington niveau 2 (origine ZLECAf / hors ZLECAf)
SigM(p) = 2*SigArm(p);
RhoM(p) = (SigM(p) - 1)/SigM(p);
DM(p)   = PMZ0(p)*QMZ0(p)**(1 - RhoM(p))
          /(PMZ0(p)*QMZ0(p)**(1 - RhoM(p)) + PMH0(p)*QMH0(p)**(1 - RhoM(p)));
AM(p)   = QM0(p)/(DM(p)*QMZ0(p)**RhoM(p) + (1 - DM(p))*QMH0(p)**RhoM(p))**(1/RhoM(p));
EcartMCES(p) = AM(p)*(DM(p)*QMZ0(p)**RhoM(p) + (1 - DM(p))*QMH0(p)**RhoM(p))**(1/RhoM(p)) - QM0(p);

* --- CET (exportations / ventes domestiques)
RhoX(p) = (OmegaX(p) + 1)/OmegaX(p);
GamX(p) = PE0(p)*QE0(p)**(1 - RhoX(p))
          /(PE0(p)*QE0(p)**(1 - RhoX(p)) + PD0(p)*QD0(p)**(1 - RhoX(p)));
AtX(p)  = QX0(p)/(GamX(p)*QE0(p)**RhoX(p) + (1 - GamX(p))*QD0(p)**RhoX(p))**(1/RhoX(p));
EcartCET(p) = AtX(p)*(GamX(p)*QE0(p)**RhoX(p) + (1 - GamX(p))*QD0(p)**RhoX(p))**(1/RhoX(p)) - QX0(p);

ShXZ(p) = X_ZLEC(p)/X_TOTAL(p);

Display SigArm, SigM, OmegaX;
Display QD0, QE0, QX0, QM0, PM0, QQ0, tq, Mc;
Display DQ, AQ, DM, AM, GamX, AtX, ShXZ;
Display EcartARM, EcartMCES, EcartCET;


* ============================================================
* 7. DEMANDE FINALE : MENAGES (LES), ETAT, INVESTISSEMENT
* ============================================================
* LES : C_i = gamma_i + beta_i (Y - sum P_j gamma_j)/P_i
*  - elasticites-revenu et parametre de Frisch issus de la litterature
*  - beta_i = e_i w_i / sum(e_j w_j)   (agregation d'Engel)
*  - gamma_i = C_i + beta_i Y / Frisch (Frisch < 0)
* Le flux P_SERVN des menages est negatif dans la MCS : il est traite comme
* un volume fixe hors LES (gamma = valeur MCS, beta = 0), sans modifier la MCS.

Scalar
    Frisch   "Parametre de Frisch (litterature, a referencer)" /-2.5/;

Parameter
    ElastRev(p)  "Elasticites-revenu de la demande des menages (litterature)"
        / P_PRIM 0.6, P_AGRTEX 0.8, P_CHIM 1.0, P_AUTIND 1.2, P_SERVM 1.3 /

    HHCons0(p)     "Consommation des menages de la MCS (peut etre negative)"
    ConsLES(p)     "Consommation positive entrant dans la LES"
    ConsFixe(p)    "Consommation hors LES (volume fixe)"
    wLES(p)        "Parts budgetaires LES"
    BetaLES(p)     "Parts marginales de budget"
    GammaLES(p)    "Consommation de subsistance (volume)"
    ElastRevAdj(p) "Elasticite-revenu apres normalisation d'Engel"
    ElastPropre(p) "Elasticite-prix propre marshallienne"
    DemLESRef(p)   "Demande LES reproduite"
    EcartLES(p)    "Ecart de reproduction LES"
    QG(p)          "Demande publique reelle (fixe)"
    QS(p)          "Demande reelle des societes (fixe)"
    Qinv0(p)       "Demande d'investissement de reference"
    QINSD(p,inst)  "Demande de produits des institutions hors menages";

Set pl(p) "Produits entrant dans la LES (flux menages positifs)";

Scalar
    CBUD0        "Budget de consommation des menages de reference"
    YLES         "Budget soumis a la LES"
    EngelAgg     "Agregation d'Engel avant normalisation"
    SurplusRef   "Revenu supernumeraire de reference"
    FrischCheck  "Parametre de Frisch recalcule"
    NbFluxNegatifs "Nombre de flux de consommation negatifs";

HHCons0(p) = SAMW(p,'INST_MEN');
pl(p) = yes$(HHCons0(p) > 0);
NbFluxNegatifs = sum(p$(HHCons0(p) < 0), 1);

ConsLES(p)$pl(p)        = HHCons0(p);
ConsFixe(p)$(not pl(p)) = HHCons0(p);

CBUD0 = sum(p, HHCons0(p));
YLES  = sum(pl, ConsLES(pl));

wLES(p)$pl(p) = ConsLES(p)/YLES;
EngelAgg      = sum(pl, wLES(pl)*ElastRev(pl));
BetaLES(p)$pl(p)      = wLES(p)*ElastRev(p)/EngelAgg;
ElastRevAdj(p)$pl(p)  = BetaLES(p)/wLES(p);
GammaLES(p)$pl(p)        = ConsLES(p) + BetaLES(p)*YLES/Frisch;
GammaLES(p)$(not pl(p))  = ConsFixe(p);

abort$(smin(pl, GammaLES(pl)) < 0)
    "ERREUR : consommation de subsistance negative (revoir Frisch ou elasticites-revenu)";

SurplusRef     = CBUD0 - sum(p, GammaLES(p));
FrischCheck    = -YLES/(YLES - sum(pl, GammaLES(pl)));
DemLESRef(p)   = GammaLES(p) + BetaLES(p)*SurplusRef;
EcartLES(p)    = DemLESRef(p) - HHCons0(p);
ElastPropre(p)$pl(p) = -1 + (1 - BetaLES(p))*GammaLES(p)/ConsLES(p);

abort$(smax(p, abs(EcartLES(p))) > 0.01) "ERREUR : la LES ne reproduit pas la consommation de reference";
abort$(abs(sum(p, BetaLES(p)) - 1) > 1e-6) "ERREUR : les parts marginales ne somment pas a 1";

QINSD(p,inst)$(not sameas(inst,'INST_MEN')) = SAMW(p,inst);
QG(p)    = QINSD(p,'INST_APU');
QS(p)    = QINSD(p,'INST_SOC');
Qinv0(p) = SAMW(p,'CAP_INV');

Display NbFluxNegatifs, HHCons0, ConsLES, ConsFixe, YLES, CBUD0, wLES;
Display EngelAgg, ElastRev, ElastRevAdj, BetaLES, GammaLES, ElastPropre;
Display Frisch, FrischCheck, SurplusRef, DemLESRef, EcartLES;
Display QG, QS, Qinv0;


* ============================================================
* 8. INSTITUTIONS, TRANSFERTS, EPARGNE, COMPTE EXTERIEUR
* ============================================================

Parameter
    YI0(inst)         "Revenu de reference des institutions"
    DepInst(inst)     "Depenses de reference des institutions"
    EcartInst(inst)   "Controle budgetaire des institutions"
    Ts(inst,inst2)    "Part du revenu de inst2 transferee a inst"
    TRtoROW(inst)     "Transferts de l'institution vers le RDM (monnaie etrangere)"
    TRfromROW(inst)   "Transferts du RDM vers l'institution (monnaie etrangere)"
    FacToROW(f)       "Revenus des facteurs verses au RDM (monnaie etrangere)"
    Fshr(inst,f)      "Part du revenu factoriel net distribue a l'institution"
    FS(f)             "Offre de facteurs"
    SAV0(inst)        "Epargne de reference"
    YIcalc(inst)      "Revenu reconstitue"
    EcartYI(inst)     "Ecart revenu reconstitue"
    wfd(f)            "Prix des facteurs de reference"
    cwts(p)           "Poids de l'indice des prix a la consommation";

Scalar
    mps          "Taux d'epargne des menages"
    SF           "Epargne etrangere (monnaie etrangere)"
    REC_DD0      "Recettes de droits de douane de reference"
    REC_TA0      "Taxes sur la production de reference"
    REC_TQ0      "Taxes sur les produits de reference"
    RecFisc0     "Recettes fiscales totales de reference"
    EcartCA0     "Controle du compte courant"
    EcartCBUD    "Controle du budget de consommation";

YI0(inst)     = sum(a, SAMW(inst,a));
DepInst(inst) = sum(a, SAMW(a,inst));
EcartInst(inst) = YI0(inst) - DepInst(inst);
abort$(smax(inst, abs(EcartInst(inst))) > 0.01) "ERREUR : institution desequilibree";
abort$(smin(inst, YI0(inst)) <= 0) "ERREUR : revenu d'institution nul ou negatif";

Ts(inst,inst2) = SAMW(inst,inst2)/YI0(inst2);

TRtoROW(inst)   = sum(ext, SAMW(ext,inst));
TRfromROW(inst) = sum(ext, SAMW(inst,ext));
FacToROW(f)     = sum(ext, SAMW(ext,f));
FS(f)           = sum(act, FactRef(f,act));
Fshr(inst,f)    = SAMW(inst,f)/sum(inst2, SAMW(inst2,f));
wfd(f)          = 1;

SAV0(inst) = SAMW('CAP_INV',inst);
mps        = SAV0('INST_MEN')/YI0('INST_MEN');
SF         = sum(ext, SAMW('CAP_INV',ext));

REC_DD0  = sum(p, DD(p));
REC_TA0  = sum(act, TaxAct(act));
REC_TQ0  = sum(p, TaxProd(p));
RecFisc0 = REC_DD0 + REC_TA0 + REC_TQ0;

cwts(p) = wLES(p);

* Controle : revenu des institutions reconstitue a partir des regles du modele
YIcalc(inst) = sum(f, Fshr(inst,f)*(FS(f) - FacToROW(f)))
             + sum(inst2, Ts(inst,inst2)*YI0(inst2))
             + TRfromROW(inst)
             + RecFisc0$sameas(inst,'INST_APU');
EcartYI(inst) = YIcalc(inst) - YI0(inst);
abort$(smax(inst, abs(EcartYI(inst))) > 0.01)
    "ERREUR : le revenu des institutions n'est pas reproduit par les regles de distribution";

abort$(smax(f, abs(FS(f) - FacToROW(f) - sum(inst, SAMW(inst,f)))) > 0.01)
    "ERREUR : revenus factoriels non couverts par institutions + RDM";

EcartCBUD = YI0('INST_MEN')*(1 - sum(inst2, Ts(inst2,'INST_MEN')))
            - TRtoROW('INST_MEN') - SAV0('INST_MEN') - CBUD0;
abort$(abs(EcartCBUD) > 0.01) "ERREUR : budget de consommation des menages non reproduit";

* Compte courant en monnaie etrangere
EcartCA0 = sum(p, M_TOTAL(p)) + sum(inst, TRtoROW(inst)) + sum(f, FacToROW(f))
           - sum(p, X_TOTAL(p)) - sum(inst, TRfromROW(inst)) - SF;
abort$(abs(EcartCA0) > 0.01) "ERREUR : compte courant non equilibre au benchmark";

Display YI0, Ts, TRtoROW, TRfromROW, FacToROW, Fshr, FS, SAV0, mps, SF;
Display REC_DD0, REC_TA0, REC_TQ0, RecFisc0, EcartYI, EcartCBUD, EcartCA0;


* ============================================================
* 9. INDICATEURS MACRO ET STRUCTURELS DE REFERENCE
* ============================================================

Parameter
    TxOuvExp(p)   "Part des exportations dans la production domestique"
    TxPenImp(p)   "Part des importations dans l'offre composite"
    PartExpZ(p)   "Part de la ZLECAf dans les exportations"
    PartVAact(act) "Part de la VA de l'activite dans la VA totale";

Scalar
    PIB_VA      "PIB au prix du marche, approche production"
    PIB_DEM     "PIB au prix du marche, approche demande"
    EcartPIB    "Ecart entre les deux approches"
    ConsMenTot  "Consommation finale des menages"
    DepPubTot   "Consommation finale Etat + societes"
    FBCFTot     "Investissement total"
    ImportTotalRef "Importations totales"
    ExportTotalRef "Exportations totales"
    DroitsTotalRef "Droits de douane totaux"
    TxOuvert    "Taux d'ouverture (X+M)/PIB"
    TxEpargne   "Taux d'investissement / PIB"
    TarifMoyen  "Taux de droit moyen sur l'ensemble des importations"
    PartImpZ    "Part de la ZLECAf dans les importations"
    PartExpZtot "Part de la ZLECAf dans les exportations";

TxOuvExp(p) = QE0(p)/QX0(p);
TxPenImp(p) = QM0(p)/QQ0(p);
PartExpZ(p) = X_ZLEC(p)/X_TOTAL(p);
PartVAact(act) = VARef(act)/sum(act2, VARef(act2));

ImportTotalRef = sum(p, M_TOTAL(p));
ExportTotalRef = sum(p, X_TOTAL(p));
DroitsTotalRef = sum(p, DD(p));

PIB_VA     = sum(act, VARef(act)) + sum(act, TaxAct(act)) + sum(p, TaxProd(p)) + sum(p, DD(p));
ConsMenTot = sum(p, HHCons0(p));
DepPubTot  = sum(p, QG(p)) + sum(p, QS(p));
FBCFTot    = sum(p, Qinv0(p));
PIB_DEM    = ConsMenTot + DepPubTot + FBCFTot + ExportTotalRef - ImportTotalRef;
EcartPIB   = PIB_VA - PIB_DEM;

TxOuvert    = (ExportTotalRef + ImportTotalRef)/PIB_VA;
TxEpargne   = FBCFTot/PIB_VA;
TarifMoyen  = DroitsTotalRef/ImportTotalRef;
PartImpZ    = sum(p, M_ZLEC(p))/ImportTotalRef;
PartExpZtot = sum(p, X_ZLEC(p))/ExportTotalRef;

Display PIB_VA, PIB_DEM, EcartPIB, ConsMenTot, DepPubTot, FBCFTot;
Display ImportTotalRef, ExportTotalRef, DroitsTotalRef;
Display TxOuvert, TxEpargne, TarifMoyen, PartImpZ, PartExpZtot;
Display TxOuvExp, TxPenImp, PartExpZ, PartVAact;


* ============================================================
* 10. MODELE : VARIABLES, EQUATIONS, TEST DE REPLICATION
* ============================================================

Positive Variables
    QA(act)      "Production de l'activite"
    QVA(act)     "Valeur ajoutee reelle"
    FD(f,act)    "Demande de facteurs"
    PVA(act)     "Prix de la valeur ajoutee"
    PA(act)      "Prix de la production de l'activite"
    QX(p)        "Production domestique du produit"
    PXC(p)       "Prix de la production domestique du produit"
    QD(p)        "Ventes domestiques"
    PD(p)        "Prix des ventes domestiques"
    QE(p)        "Exportations totales"
    PE(p)        "Prix des exportations (monnaie nationale)"
    QEZ(p)       "Exportations vers la ZLECAf"
    QEH(p)       "Exportations hors ZLECAf"
    QM(p)        "Importations totales"
    PM(p)        "Prix des importations (tarif inclus)"
    QMZ(p)       "Importations ZLECAf"
    QMH(p)       "Importations hors ZLECAf"
    QQ(p)        "Offre composite"
    PQ(p)        "Prix acheteur du composite"
    wf(f)        "Prix des facteurs"
    YI(inst)     "Revenu des institutions"
    CBUD         "Budget de consommation des menages"
    REC_DD       "Recettes de droits de douane"
    REC_TA       "Taxes sur la production"
    REC_TQ       "Taxes sur les produits"
    EXR          "Taux de change"
    CPI          "Indice des prix a la consommation (numeraire)"
    IADJ         "Facteur d'ajustement de l'investissement reel";

Variables
    QHH(p)       "Consommation des menages (volume, peut etre negatif)"
    SAV(inst)    "Epargne des institutions";

Equations
    EQ_QVA(act)     "VA Leontief avec la production"
    EQ_CES(act)     "VA CES"
    EQ_FOC(f,act)   "Conditions de premier ordre CES"
    EQ_PVA(act)     "Prix de la production = couts"
    EQ_PA(act)      "Prix de l'activite"
    EQ_QX(p)        "Production jointe"
    EQ_CET(p)       "CET"
    EQ_ESUP(p)      "Offre d'exportation"
    EQ_PXC(p)       "Prix de la production domestique"
    EQ_QEZ(p)       "Exportations ZLECAf"
    EQ_QEH(p)       "Exportations hors ZLECAf"
    EQ_PE(p)        "Prix export agrege"
    EQ_MCES(p)      "CES d'origine"
    EQ_MFOC(p)      "Arbitrage ZLECAf / Hors ZLECAf"
    EQ_PM(p)        "Prix import agrege"
    EQ_ARM(p)       "Armington"
    EQ_ARMFOC(p)    "Arbitrage domestique / importe"
    EQ_PQ(p)        "Prix acheteur"
    EQ_MKT(p)       "Equilibre des marches de produits"
    EQ_LES(p)       "Demande LES"
    EQ_FMKT(f)      "Equilibre des marches de facteurs"
    EQ_REC_DD       "Recettes douanieres"
    EQ_REC_TA       "Taxes sur la production"
    EQ_REC_TQ       "Taxes sur les produits"
    EQ_YI(inst)     "Revenu des institutions"
    EQ_SAVM         "Epargne des menages"
    EQ_SAVO(inst)   "Epargne Etat et societes (residu)"
    EQ_CBUD         "Budget de consommation"
    EQ_CA           "Compte courant"
    EQ_CPI          "Indice des prix";

* --- Production
EQ_QVA(act).. QVA(act) =E= Iva(act)*QA(act);

EQ_CES(act)..
    QVA(act) =E= ScaleVA(act)*sum(f, DeltaF(f,act)*FD(f,act)**RhoVA(act))**(1/RhoVA(act));

EQ_FOC(f,act)..
    wf(f)*FD(f,act) =E= PVA(act)*QVA(act)*DeltaF(f,act)*FD(f,act)**RhoVA(act)
                        /sum(f2, DeltaF(f2,act)*FD(f2,act)**RhoVA(act));

EQ_PVA(act).. PA(act)*(1 - TxAct(act)) =E= Iva(act)*PVA(act) + sum(p, Ica(p,act)*PQ(p));

EQ_PA(act).. PA(act) =E= sum(p, Theta(act,p)*PXC(p));

EQ_QX(p).. QX(p) =E= sum(act, Theta(act,p)*QA(act));

* --- Exportations
EQ_CET(p)..
    QX(p) =E= AtX(p)*(GamX(p)*QE(p)**RhoX(p) + (1 - GamX(p))*QD(p)**RhoX(p))**(1/RhoX(p));

EQ_ESUP(p)..
    QE(p) =E= QD(p)*(PE(p)/PD(p)*(1 - GamX(p))/GamX(p))**OmegaX(p);

EQ_PXC(p).. PXC(p)*QX(p) =E= PD(p)*QD(p) + PE(p)*QE(p);

EQ_QEZ(p).. QEZ(p) =E= ShXZ(p)*QE(p);

EQ_QEH(p).. QEH(p) =E= (1 - ShXZ(p))*QE(p);

EQ_PE(p).. PE(p)*QE(p) =E= EXR*pweZ(p)*QEZ(p) + EXR*pweH(p)*QEH(p);

* --- Importations
EQ_MCES(p)..
    QM(p) =E= AM(p)*(DM(p)*QMZ(p)**RhoM(p) + (1 - DM(p))*QMH(p)**RhoM(p))**(1/RhoM(p));

EQ_MFOC(p)..
    QMZ(p) =E= QMH(p)*((EXR*pwmH(p)*(1 + tmH(p)))/(EXR*pwmZ(p)*(1 + tmZ(p)))
                       *DM(p)/(1 - DM(p)))**SigM(p);

EQ_PM(p)..
    PM(p)*QM(p) =E= EXR*pwmZ(p)*(1 + tmZ(p))*QMZ(p) + EXR*pwmH(p)*(1 + tmH(p))*QMH(p);

EQ_ARM(p)..
    QQ(p) =E= AQ(p)*(DQ(p)*QM(p)**RhoQ(p) + (1 - DQ(p))*QD(p)**RhoQ(p))**(1/RhoQ(p));

EQ_ARMFOC(p)..
    QM(p) =E= QD(p)*(PD(p)/PM(p)*DQ(p)/(1 - DQ(p)))**SigArm(p);

EQ_PQ(p)..
    PQ(p)*QQ(p) =E= (1 + tq(p))*(PD(p)*QD(p) + PM(p)*QM(p)
                                 + sum(pp, PQ(pp)*Mc(pp,p))*QQ(p));

EQ_MKT(p)..
    QQ(p) =E= sum(act, Ica(p,act)*QA(act)) + QHH(p) + QG(p) + QS(p)
              + IADJ*Qinv0(p) + sum(pp, Mc(p,pp)*QQ(pp));

* --- Menages : LES
EQ_LES(p)..
    PQ(p)*QHH(p) =E= PQ(p)*GammaLES(p)
                      + BetaLES(p)*(CBUD - sum(pp, PQ(pp)*GammaLES(pp)));

* --- Facteurs
EQ_FMKT(f).. sum(act, FD(f,act)) =E= FS(f);

* --- Taxes
EQ_REC_DD.. REC_DD =E= sum(p, EXR*pwmZ(p)*tmZ(p)*QMZ(p) + EXR*pwmH(p)*tmH(p)*QMH(p));
EQ_REC_TA.. REC_TA =E= sum(act, TxAct(act)*PA(act)*QA(act));
EQ_REC_TQ.. REC_TQ =E= sum(p, tq(p)/(1 + tq(p))*PQ(p)*QQ(p));

* --- Institutions
EQ_YI(inst)..
    YI(inst) =E= sum(f, Fshr(inst,f)*(wf(f)*FS(f) - EXR*FacToROW(f)))
                 + sum(inst2, Ts(inst,inst2)*YI(inst2))
                 + EXR*TRfromROW(inst)
                 + (REC_DD + REC_TA + REC_TQ)$sameas(inst,'INST_APU');

EQ_SAVM.. SAV('INST_MEN') =E= mps*YI('INST_MEN');

EQ_SAVO(inst)$(not sameas(inst,'INST_MEN'))..
    SAV(inst) =E= YI(inst)*(1 - sum(inst2, Ts(inst2,inst))) - EXR*TRtoROW(inst)
                  - sum(p, PQ(p)*QINSD(p,inst));

EQ_CBUD..
    CBUD =E= YI('INST_MEN')*(1 - sum(inst2, Ts(inst2,'INST_MEN')))
             - EXR*TRtoROW('INST_MEN') - SAV('INST_MEN');

* --- Compte courant (monnaie etrangere) et numeraire
EQ_CA..
    sum(p, pwmZ(p)*QMZ(p) + pwmH(p)*QMH(p)) + sum(inst, TRtoROW(inst)) + sum(f, FacToROW(f))
    =E= sum(p, pweZ(p)*QEZ(p) + pweH(p)*QEH(p)) + sum(inst, TRfromROW(inst)) + SF;

EQ_CPI.. CPI =E= sum(p, cwts(p)*PQ(p));

* --- Valeurs initiales = benchmark
QA.l(act)    = ProdRef(act);
QVA.l(act)   = VARef(act);
FD.l(f,act)  = FactRef(f,act);
PVA.l(act)   = 1;
PA.l(act)    = 1;
QX.l(p)      = QX0(p);
PXC.l(p)     = 1;
QD.l(p)      = QD0(p);
PD.l(p)      = PD0(p);
QE.l(p)      = QE0(p);
PE.l(p)      = PE0(p);
QEZ.l(p)     = X_ZLEC(p);
QEH.l(p)     = X_HORS(p);
QM.l(p)      = QM0(p);
PM.l(p)      = PM0(p);
QMZ.l(p)     = QMZ0(p);
QMH.l(p)     = QMH0(p);
QQ.l(p)      = QQ0(p);
PQ.l(p)      = 1;
QHH.l(p)     = HHCons0(p);
wf.l(f)      = 1;
YI.l(inst)   = YI0(inst);
SAV.l(inst)  = SAV0(inst);
CBUD.l       = CBUD0;
REC_DD.l     = REC_DD0;
REC_TA.l     = REC_TA0;
REC_TQ.l     = REC_TQ0;
EXR.l        = 1;
CPI.l        = 1;
IADJ.l       = 1;

* --- Numeraire et bornes de securite(Pour garder la positivité des quantités et éviter les éventuelles divisions par 0 durant les itérations)
CPI.fx = 1;

QA.lo(act) = 1e-6;  QVA.lo(act) = 1e-6;  FD.lo(f,act) = 1e-6;
PVA.lo(act) = 1e-6; PA.lo(act) = 1e-6;
QX.lo(p) = 1e-6;  PXC.lo(p) = 1e-6;  QD.lo(p) = 1e-6;  PD.lo(p) = 1e-6;
QE.lo(p) = 1e-6;  PE.lo(p) = 1e-6;   QEZ.lo(p) = 1e-6; QEH.lo(p) = 1e-6;
QM.lo(p) = 1e-6;  PM.lo(p) = 1e-6;   QMZ.lo(p) = 1e-6; QMH.lo(p) = 1e-6;
QQ.lo(p) = 1e-6;  PQ.lo(p) = 1e-6;
wf.lo(f) = 1e-6;  YI.lo(inst) = 1e-6;
EXR.lo = 1e-6;    IADJ.lo = 1e-6;

Model MEGC_REF "MEGC Maroc - modele de reference" / all /;

Option limrow = 0, limcol = 0, solprint = on, iterlim = 500;
MEGC_REF.holdfixed = 1;

Solve MEGC_REF using cns;


* ============================================================
* 11. CONTROLES DE VALIDATION ET EXPORT
* ============================================================

Set devs "Variables controlees pour la replication"
    / QA, QD, QM, QE, QQ, QHH, PQ, PD, wf, EXR, YI, SAV, IADJ /;

Parameter DevRel(devs) "Ecart relatif maximal entre solution et benchmark";

DevRel('QA')   = smax(act, abs(QA.l(act)/ProdRef(act) - 1));
DevRel('QD')   = smax(p, abs(QD.l(p)/QD0(p) - 1));
DevRel('QM')   = smax(p, abs(QM.l(p)/QM0(p) - 1));
DevRel('QE')   = smax(p, abs(QE.l(p)/QE0(p) - 1));
DevRel('QQ')   = smax(p, abs(QQ.l(p)/QQ0(p) - 1));
DevRel('QHH')  = smax(p, abs(QHH.l(p)/HHCons0(p) - 1));
DevRel('PQ')   = smax(p, abs(PQ.l(p) - 1));
DevRel('PD')   = smax(p, abs(PD.l(p) - 1));
DevRel('wf')   = smax(f, abs(wf.l(f) - 1));
DevRel('EXR')  = abs(EXR.l - 1);
DevRel('YI')   = smax(inst, abs(YI.l(inst)/YI0(inst) - 1));
DevRel('SAV')  = smax(inst, abs(SAV.l(inst)/SAV0(inst) - 1));
DevRel('IADJ') = abs(IADJ.l - 1);

Scalar
    MaxDevRel "Ecart relatif maximal de replication"
    Walras    "Ecart de Walras : epargne totale + epargne etrangere - investissement"
    ReplicOK  "1 si la replication du benchmark est reussie (ecart < 1e-5)" /0/;

MaxDevRel = smax(devs, DevRel(devs));
Walras    = sum(inst, SAV.l(inst)) + EXR.l*SF - IADJ.l*sum(p, PQ.l(p)*Qinv0(p));
ReplicOK$(MaxDevRel < 1e-5 and abs(Walras) < 1e-3) = 1;

Display MEGC_REF.modelstat, MEGC_REF.solvestat, MEGC_REF.iterusd;
Display DevRel, MaxDevRel, Walras, ReplicOK;

Execute_Unload "C:\Projet_MEGC_Maroc\CALIB_REF.gdx";
