from cleaning.text_cleaner import normalize_key

ORG_ALIASES = [
    "irc", "nrc", "drc", "pam", "acf", "cosef", "pnlp", "paludisme",
    "world vision", "eam progres", "swisscontact", "2isoft", "dhy technologie",
]


def normalize_org_key(org):
    """Harmonise les acronymes et variantes d'organisations pour la fusion inter-sites."""
    k = normalize_key(org)
    for token in ORG_ALIASES:
        if token in k:
            return "pnlp" if token in ("pnlp", "paludisme") else token
    return k


def deduplicate_offers(df_clean):
    """Supprime les doublons d'URL et fusionne les rediffusions inter-plateformes."""
    df = df_clean.copy()
    df["_completude"] = (
        df.notna().sum(axis=1) * 10000
        + df["description_propre"].fillna("").str.len()
    )
    df = df.sort_values("_completude", ascending=False)

    # 1. Dédoublonnage strict par URL
    df = df.drop_duplicates(subset=["url_offre"], keep="first").copy()

    # 2. Clé composite (titre + organisation + ville, en résolvant la ville générique 'Niger')
    df["_titre_k"] = df["titre_poste"].apply(normalize_key)
    df["_org_k"] = df["entreprise_ou_ong"].apply(normalize_org_key)
    df["_ville_k"] = df["ville"].apply(normalize_key)

    specific_city_by_pair = (
        df[df["_ville_k"] != "niger"]
        .groupby(["_titre_k", "_org_k"])["_ville_k"]
        .first()
        .to_dict()
    )
    df["_ville_resolved"] = df.apply(
        lambda r: specific_city_by_pair.get((r["_titre_k"], r["_org_k"]), r["_ville_k"])
        if r["_ville_k"] == "niger" else r["_ville_k"],
        axis=1,
    )

    df["_dedup_key"] = df["_titre_k"] + " | " + df["_org_k"] + " | " + df["_ville_resolved"]

    sources_map = df.groupby("_dedup_key")["site_source"].apply(
        lambda x: " ; ".join(dict.fromkeys(x))
    ).to_dict()
    urls_map = df.groupby("_dedup_key")["url_offre"].apply(
        lambda x: list(dict.fromkeys(x))
    ).to_dict()

    df_final = df.drop_duplicates(subset=["_dedup_key"], keep="first").copy()
    df_final["sources_multiples"] = df_final["_dedup_key"].map(sources_map)
    df_final["urls_alternatives"] = df_final["_dedup_key"].map(
        lambda k: " ; ".join(urls_map[k][1:]) if len(urls_map[k]) > 1 else None
    )

    df_final = df_final.drop(
        columns=["_completude", "_titre_k", "_org_k", "_ville_k", "_ville_resolved", "_dedup_key"]
    ).reset_index(drop=True)
    df_final.insert(0, "id_offre", [f"OFFRE_{i+1:03d}" for i in range(len(df_final))])
    return df_final