import re
import unicodedata

try:
    from unidecode import unidecode as _unidecode

    def _to_ascii(text: str) -> str:
        return _unidecode(text)
except ImportError:
    def _to_ascii(text: str) -> str:
        return "".join(
            c for c in unicodedata.normalize("NFD", text)
            if unicodedata.category(c) != "Mn"
        )


def fix_mojibake(text):
    """Répare les caractères UTF-8 mal décodés en Latin-1 (ex: 'donnÃ©es' -> 'données')."""
    if not isinstance(text, str):
        return text
    try:
        return text.encode("latin1").decode("utf-8")
    except Exception:
        return text


def clean_whitespace(text):
    """Normalise les espaces insécables et supprime les sauts de ligne excessifs."""
    if not isinstance(text, str) or not text.strip():
        return None
    text = text.replace("\xa0", " ").replace("\u202f", " ")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def is_valid_offer_url(url):
    """Filtre uniquement les URLs correspondant à de vraies fiches d'offres ou d'appels d'offres."""
    u = str(url).strip()
    if re.match(r"^https?://(www\.)?nigeremploi\.com/annonce-details-\d+\.html$", u):
        return True
    if re.match(r"^https?://(www\.)?connexion-carriere\.com/(emploi|offres-demplois)/[^/]+/?$", u):
        return not u.rstrip("/").endswith("/test")
    if re.match(r"^https?://(www\.)?nigeropportunites\.com/annonces/[^/]+/?$", u):
        return True
    if re.match(r"^https?://(www\.)?zonemploi\.africa/(appel-offre|offre-emploi|emploi)/[^/]+/?$", u):
        return True
    return False


def normalize_key(text):
    """Normalise un libellé (sans accents, casse ni mentions de genre) pour le dédoublonnage."""
    if not isinstance(text, str):
        return ""
    s = _to_ascii(text).lower()
    s = re.sub(r"\((?:e|s|es|trice|trices|teur|teurs)\)", "", s)
    s = re.sub(r"\b(h/f|f/h|f/m|h-f|f-h)\b", "", s)
    s = re.sub(r"[^a-z0-9]+", " ", s).strip()
    return s