VILLE_TO_REGION = {
    # Niger - 8 régions administratives
    "niamey": ("Niamey", "Niger"),
    "bangoula": ("Niamey", "Niger"),
    "agadez": ("Agadez", "Niger"),
    "iférouane": ("Agadez", "Niger"),
    "iferouane": ("Agadez", "Niger"),
    "arlit": ("Agadez", "Niger"),
    "diffa": ("Diffa", "Niger"),
    "goudoumaria": ("Diffa", "Niger"),
    "nguigmi": ("Diffa", "Niger"),
    "dosso": ("Dosso", "Niger"),
    "dogondoutchi": ("Dosso", "Niger"),
    "doutchi": ("Dosso", "Niger"),
    "gaya": ("Dosso", "Niger"),
    "maradi": ("Maradi", "Niger"),
    "chadakori": ("Maradi", "Niger"),
    "dakoro": ("Maradi", "Niger"),
    "guidan roumdji": ("Maradi", "Niger"),
    "guidan sori": ("Maradi", "Niger"),
    "tessaoua": ("Maradi", "Niger"),
    "téssaoua": ("Maradi", "Niger"),
    "tahoua": ("Tahoua", "Niger"),
    "abalak": ("Tahoua", "Niger"),
    "konni": ("Tahoua", "Niger"),
    "birni nkonni": ("Tahoua", "Niger"),
    "madaoua": ("Tahoua", "Niger"),
    "tchintabaraden": ("Tahoua", "Niger"),
    "tillia": ("Tahoua", "Niger"),
    "tillabéri": ("Tillabéri", "Niger"),
    "tillaberi": ("Tillabéri", "Niger"),
    "abala": ("Tillabéri", "Niger"),
    "filingué": ("Tillabéri", "Niger"),
    "filingue": ("Tillabéri", "Niger"),
    "gothèye": ("Tillabéri", "Niger"),
    "gotheye": ("Tillabéri", "Niger"),
    "tagazar": ("Tillabéri", "Niger"),
    "ouallam": ("Tillabéri", "Niger"),
    "téra": ("Tillabéri", "Niger"),
    "tera": ("Tillabéri", "Niger"),
    "say": ("Tillabéri", "Niger"),
    "torodi": ("Tillabéri", "Niger"),
    "zinder": ("Zinder", "Niger"),
    "mirriah": ("Zinder", "Niger"),
    "tanout": ("Zinder", "Niger"),
    "gouré": ("Zinder", "Niger"),
    "magaria": ("Zinder", "Niger"),
    # Villes hors Niger présentes dans NigerCarriere
    "abidjan": ("Lagunes / Abidjan", "Côte d'Ivoire"),
    "dakar": ("Dakar", "Sénégal"),
    "bamako": ("Bamako", "Mali"),
    "ouagadougou": ("Centre / Kadiogo", "Burkina Faso"),
    "ndjamena": ("N'Djamena", "Tchad"),
    "n'djamena": ("N'Djamena", "Tchad"),
    "abéché": ("Ouaddaï", "Tchad"),
    "abeche": ("Ouaddaï", "Tchad"),
    "abuja": ("FCT Abuja", "Nigeria"),
    "warri": ("Delta State", "Nigeria"),
}


def infer_region_pays(ville, pays_raw=None):
    """Déduit la région administrative et normalise le pays à partir de la ville."""
    if isinstance(ville, str) and ville.strip():
        v_clean = ville.strip().lower().replace("’", "'")
        if v_clean in ("niger", "tout le niger"):
            return "National (Tout le Niger)", "Niger"
        for key, (region, pays) in VILLE_TO_REGION.items():
            if key in v_clean:
                return region, pays
    if isinstance(pays_raw, str) and pays_raw.strip():
        p_clean = pays_raw.strip().strip("()").title()
        if "Ivoire" in p_clean:
            p_clean = "Côte d'Ivoire"
        return None, p_clean
    return None, "Niger"