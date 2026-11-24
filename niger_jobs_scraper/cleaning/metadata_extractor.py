import re
import pandas as pd
from cleaning.text_cleaner import clean_whitespace
from cleaning.geo_niger import infer_region_pays

MOIS_FR = {
    "janvier": "01", "janv": "01", "jan": "01",
    "février": "02", "fevrier": "02", "févr": "02", "fevr": "02", "feb": "02",
    "mars": "03", "mar": "03",
    "avril": "04", "avr": "04", "apr": "04",
    "mai": "05", "may": "05",
    "juin": "06", "jun": "06",
    "juillet": "07", "juil": "07", "jul": "07",
    "août": "08", "aout": "08", "aug": "08",
    "septembre": "09", "sept": "09", "sep": "09",
    "octobre": "10", "oct": "10",
    "novembre": "11", "nov": "11",
    "décembre": "12", "decembre": "12", "déc": "12", "dec": "12",
}


def parse_french_date(val):
    """Convertit une date textuelle française en format ISO YYYY-MM-DD."""
    if not isinstance(val, str) or not val.strip():
        return None
    s = val.strip().lower()
    m = re.search(r"\b(\d{1,2})[-/](\d{1,2})[-/](\d{4})\b", s)
    if m:
        d, mo, y = m.groups()
        return f"{y}-{int(mo):02d}-{int(d):02d}"
    m = re.search(r"\b(\d{1,2})(?:er)?\s+([a-zéûôà]+)\.?\s+(\d{4})\b", s)
    if m:
        d, mo_str, y = m.groups()
        mo = MOIS_FR.get(mo_str)
        if mo:
            return f"{y}-{mo}-{int(d):02d}"
    m = re.search(r"\b(\d{1,2})(?:er)?\s+([a-zéûôà]+)\.?\b", s)
    if m:
        d, mo_str = m.groups()
        mo = MOIS_FR.get(mo_str)
        if mo:
            return f"2026-{mo}-{int(d):02d}"
    return None


def extract_org_from_intro(text_lines):
    """Extrait l'organisation recruteuse dans le paragraphe de présentation (NigerCarriere)."""
    for line in text_lines[:4]:
        if re.match(r"^PR[ÉE]SENTATION", line, re.I):
            continue
        m = re.match(r"^Pr[ée]sentation\s+(?:de\s+l['’]|du\s+|des\s+|de\s+|d['’])(.+)$", line, re.I)
        if m:
            return m.group(1).strip().rstrip(".")
        m = re.match(r"^([A-ZÉÈÊÀÂÎÔÛÇ0-9\-\s\(\)&]{3,50}),\s+(?:ONG|ORGANISATION|SOCI[ÉE]T[ÉE])", line)
        if m:
            return m.group(1).strip()
        m = re.match(r"^(?:L['’]|Le\s+|La\s+|Les\s+)?(.+?)\s+(?:est\s+un(?:e)?|intervient|répond|est\s+cité|est\s+l['’]entreprise)", line)
        if m:
            org = m.group(1).strip()
            if 2 <= len(org) <= 100:
                return org
    return None


def parse_single_offer(row):
    """Extrait l'ensemble des métadonnées structurées depuis le corpus brut d'une annonce."""
    src = row["site_source"]
    corpus = str(row["description_complete_corpus"] or "")
    lines = [l.strip() for l in corpus.split("\n") if l.strip()]

    res = {
        "reference_offre": None,
        "titre_poste": row["titre_poste"] if pd.notna(row["titre_poste"]) else None,
        "entreprise_ou_ong": row["entreprise_ou_ong"] if pd.notna(row["entreprise_ou_ong"]) else None,
        "nature_annonce": "Offre d'emploi",
        "type_contrat": row["type_contrat"] if pd.notna(row["type_contrat"]) else None,
        "secteur_activite": None,
        "ville": row["ville"] if pd.notna(row["ville"]) else None,
        "region": None,
        "pays": "Niger",
        "niveau_etude": None,
        "experience_requise": None,
        "salaire_affiche": row["salaire_affiche"] if pd.notna(row["salaire_affiche"]) else None,
        "date_publication": parse_french_date(str(row["date_publication"])) if pd.notna(row["date_publication"]) else None,
        "date_limite_candidature": parse_french_date(str(row["date_limite_candidature"])) if pd.notna(row["date_limite_candidature"]) else None,
        "description_propre": None,
        "profil_exige_corpus": row["profil_exige_corpus"] if pd.notna(row["profil_exige_corpus"]) else None,
    }

    if src == "NigerEmploi":
        if lines and not res["titre_poste"]:
            res["titre_poste"] = lines[0]
        idx = 1
        if idx < len(lines) and lines[idx].startswith("Numéro"):
            if idx + 1 < len(lines):
                res["reference_offre"] = lines[idx + 1]
            idx += 2
        if idx < len(lines) and lines[idx].startswith("Publiée le"):
            if idx + 1 < len(lines):
                res["date_publication"] = parse_french_date(lines[idx + 1])
            idx += 2
        if idx < len(lines) and lines[idx].startswith("Mise à jour le"):
            idx += 2
        if idx < len(lines):
            res["entreprise_ou_ong"] = lines[idx]; idx += 1
        if idx < len(lines):
            res["secteur_activite"] = lines[idx]; idx += 1
        if idx < len(lines):
            res["date_limite_candidature"] = parse_french_date(lines[idx]); idx += 1
        if idx < len(lines) and ("Annonce close" in lines[idx] or "Annonce expir" in lines[idx]):
            idx += 1
        if idx < len(lines):
            res["type_contrat"] = lines[idx]; idx += 1
        if idx < len(lines):
            sal = lines[idx]
            res["salaire_affiche"] = None if sal.lower() == "non précisé" else sal
            idx += 1
        if idx < len(lines):
            res["ville"] = lines[idx]; idx += 1
        if idx < len(lines) and lines[idx].startswith("(") and lines[idx].endswith(")"):
            res["pays"] = lines[idx].strip("()"); idx += 1

        meta_extra = []
        while idx < len(lines) and not lines[idx].startswith("- Suivre notre canal"):
            meta_extra.append(lines[idx])
            idx += 1
        for item in meta_extra:
            if re.search(r"\b(bac\s*\+?\s*\d|doctorat|master|licence|bts|dess|dut|dipl[ôo]me|secondaire|bepc|cap|bachelor|degree)\b", item, re.I) and not res["niveau_etude"]:
                res["niveau_etude"] = item
            elif re.search(r"\b\d+\s*(?:an|ans|mois)\b", item, re.I) and not res["experience_requise"]:
                res["experience_requise"] = item

        body_start = idx
        for j in range(idx, min(idx + 8, len(lines))):
            if lines[j] == "WhatsApp":
                body_start = j + 1
                break
        body_end = len(lines)
        for j in range(len(lines) - 1, body_start, -1):
            if lines[j] in ("A noter", "Niamey - Niger") or lines[j].startswith("[email"):
                body_end = j
        body_lines = lines[body_start:body_end]
        res["description_propre"] = "\n".join(body_lines)

        for j, bl in enumerate(body_lines):
            if re.match(r"^(profil\s+(recherch[ée]|exig[ée]|requis)|qualifications\s+requises|comp[ée]tences\s+requises)\s*:?$", bl, re.I):
                prof_lines = []
                for k in range(j + 1, len(body_lines)):
                    if re.match(r"^(dossier\s+de\s+candidature|comment\s+postuler|d[ée]p[ôo]t|conditions|pour\s+postuler)\b", body_lines[k], re.I):
                        break
                    prof_lines.append(body_lines[k])
                if prof_lines:
                    res["profil_exige_corpus"] = "\n".join(prof_lines)
                break

    elif src == "NigerCarriere":
        if len(lines) >= 5:
            if not res["titre_poste"]:
                res["titre_poste"] = lines[0]
            res["secteur_activite"] = lines[1]
            m_loc = re.match(r"^(.+?)\s*\(([^)]+)\)$", lines[2])
            if m_loc:
                res["ville"] = m_loc.group(1).strip()
                res["pays"] = m_loc.group(2).strip().title()
            else:
                res["ville"] = lines[2]
            res["date_publication"] = parse_french_date(lines[3])
            res["type_contrat"] = lines[4]

        for j, l in enumerate(lines):
            if l.startswith("Fin des candidatures") and j + 1 < len(lines):
                res["date_limite_candidature"] = parse_french_date(lines[j + 1])
            elif l == "Expérience" and j + 1 < len(lines):
                res["experience_requise"] = lines[j + 1]
            elif l == "Niveau d'étude" and j + 1 < len(lines):
                res["niveau_etude"] = lines[j + 1]
            elif l == "Type de contrat" and j + 1 < len(lines) and not res["type_contrat"]:
                res["type_contrat"] = lines[j + 1]

        pres_idx = next((i for i, l in enumerate(lines) if "Présentation" in l), None)
        end_idx = next((i for i, l in enumerate(lines) if l == "Partager cet article"), len(lines))
        if pres_idx is not None:
            res["entreprise_ou_ong"] = extract_org_from_intro(lines[pres_idx + 1:pres_idx + 5])
            body_lines = lines[pres_idx:end_idx]
            res["description_propre"] = "\n".join(body_lines)
            for j, bl in enumerate(body_lines):
                if re.match(r"^Profil\s+recherch[ée]", bl, re.I):
                    prof_lines = []
                    for k in range(j + 1, len(body_lines)):
                        if re.match(r"^(Ce\s+que\s+nous\s+offrons|Conditions\s+du\s+contrat|Mention\s+Obligatoire|Comment\s+postuler|Dossier)", body_lines[k], re.I):
                            break
                        prof_lines.append(body_lines[k])
                    if prof_lines:
                        res["profil_exige_corpus"] = "\n".join(prof_lines)
                    break

    elif src == "NigerOpportunites":
        if len(lines) >= 4:
            res["nature_annonce"] = lines[0]
            res["reference_offre"] = lines[1]
            if not res["titre_poste"]:
                res["titre_poste"] = lines[2]
            res["entreprise_ou_ong"] = lines[3]

        kv_labels = {"Lieu", "Contrat", "Postes", "Niveau", "Expérience", "Secteur", "Description", "Profil recherché", "Date limite"}
        for j, l in enumerate(lines):
            if l == "Lieu" and j + 1 < len(lines):
                res["ville"] = lines[j + 1]
            elif l == "Contrat" and j + 1 < len(lines):
                res["type_contrat"] = lines[j + 1]
            elif l == "Niveau" and j + 1 < len(lines):
                res["niveau_etude"] = lines[j + 1]
            elif l == "Expérience" and j + 1 < len(lines):
                res["experience_requise"] = lines[j + 1]
            elif l == "Secteur" and j + 1 < len(lines):
                res["secteur_activite"] = lines[j + 1]
            elif l == "Date limite" and j + 1 < len(lines):
                res["date_limite_candidature"] = parse_french_date(lines[j + 1])
            elif l.startswith("Publiée le ") and len(l) > 15:
                d_pub = parse_french_date(l.replace("Publiée le ", "").rstrip("."))
                if d_pub:
                    res["date_publication"] = d_pub
            elif l == "Description":
                desc_lines = []
                for k in range(j + 1, len(lines)):
                    if lines[k] in kv_labels or lines[k] in ("En ligne", "Par e-mail", "Sur place", "Date limite", "Partager cette annonce"):
                        break
                    desc_lines.append(lines[k])
                res["description_propre"] = "\n".join(desc_lines)
            elif l == "Profil recherché":
                prof_lines = []
                for k in range(j + 1, len(lines)):
                    if lines[k] in kv_labels or lines[k] in ("En ligne", "Par e-mail", "Sur place", "Date limite", "Partager cette annonce"):
                        break
                    prof_lines.append(lines[k])
                res["profil_exige_corpus"] = "\n".join(prof_lines)

    elif src == "Zonemploi_Niger":
        start_idx = next((i + 1 for i, l in enumerate(lines) if "publier une of" in l.lower()), 11)
        if start_idx < len(lines) and not res["titre_poste"]:
            res["titre_poste"] = lines[start_idx]
        partager_idx = next((i for i, l in enumerate(lines) if l == "Partager"), len(lines))
        if start_idx + 1 < partager_idx:
            res["description_propre"] = "\n".join(lines[start_idx + 1:partager_idx])

        for j, l in enumerate(lines):
            if l == "Réf" and j + 1 < len(lines):
                res["reference_offre"] = re.sub(r"^Dossier\s*n°\s*", "", lines[j + 1], flags=re.I).strip()
            elif l == "Pays" and j + 1 < len(lines):
                res["pays"] = lines[j + 1]
            elif l == "Lieu" and j + 1 < len(lines):
                res["ville"] = lines[j + 1]
            elif l == "Publié" and j + 1 < len(lines):
                res["date_publication"] = parse_french_date(lines[j + 1])
            elif l == "Expire le" and j + 1 < len(lines):
                res["date_limite_candidature"] = parse_french_date(lines[j + 1])
            elif l == "Budget" and j + 1 < len(lines):
                res["salaire_affiche"] = None if lines[j + 1].upper() == "N/A" else lines[j + 1]
            elif l == "Secteur" and j + 1 < len(lines):
                res["secteur_activite"] = lines[j + 1]
            elif "fournies par l’annonceur" in l or "fournies par l'annonceur" in l:
                if j + 1 < len(lines):
                    org = lines[j + 1].strip()
                    if org.endswith("(CRN"):
                        org += ")"
                    res["entreprise_ou_ong"] = org

    titre_low = str(res["titre_poste"] or "").lower()
    contrat_low = str(res["type_contrat"] or "").lower()
    if src == "Zonemploi_Niger" or "appel d'offre" in contrat_low or re.search(r"\b(appel d['’]offres|manifestation d['’]int[ée]r[êe]t|fourniture|acquisition|r[ée]habilitation|travaux|selection d['’]un cabinet)\b", titre_low):
        if re.search(r"\b(recrutement de|collaborateurs|consultant|consultante)\b", titre_low) and not re.search(r"\b(cabinet|fournisseur|compagnie)\b", titre_low):
            res["nature_annonce"] = "Offre d'emploi / Consultance"
        else:
            res["nature_annonce"] = "Appel d'offres / Marché"
    elif "formation" in contrat_low or titre_low.startswith("programme de formation") or titre_low.startswith("formation certifiante"):
        res["nature_annonce"] = "Formation"

    res["description_propre"] = clean_whitespace(res["description_propre"])
    res["profil_exige_corpus"] = clean_whitespace(res["profil_exige_corpus"])
    res["titre_poste"] = clean_whitespace(res["titre_poste"])
    res["entreprise_ou_ong"] = clean_whitespace(res["entreprise_ou_ong"])

    reg, pays_norm = infer_region_pays(res["ville"], res["pays"])
    res["region"] = reg
    res["pays"] = pays_norm
    return pd.Series(res)


def extract_all_metadata(df_valid):
    """Applique l'extraction sur l'ensemble du DataFrame filtré."""
    parsed = df_valid.apply(parse_single_offer, axis=1)
    return pd.concat([df_valid[["url_offre", "site_source", "date_scraping"]], parsed], axis=1)