import requests
import os
import json
from urllib.parse import urlparse
from fake_useragent import UserAgent

class BaseScraper:
    def __init__(self):
        self.ua = UserAgent()
        self.session = requests.Session()
        self.seen_urls = self.load_seen_urls()

    def load_seen_urls(self, filepath="data/processed/offres.jsonl"):
        seen = set()
        if os.path.exists(filepath):
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    for line in f:
                        if line.strip():
                            data = json.loads(line)
                            if "url_offre" in data and data["url_offre"]:
                                seen.add(data["url_offre"])
            except Exception:
                pass
        return seen

    def get_headers(self):
        return {'User-Agent': self.ua.random}

    def is_valid_job_url(self, url, allowed_domain, required_pattern=None):
        if not url or url in self.seen_urls:
            return False
        
        ignored_keywords = ['javascript', 'facebook.com', 'twitter.com', 'linkedin.com', 'whatsapp.com', 'categorie', 'localisation', 'employeur', '#']
        
        if any(keyword in url.lower() for keyword in ignored_keywords):
            return False

        parsed = urlparse(url)
        if parsed.scheme not in ['http', 'https'] or allowed_domain not in parsed.netloc:
            return False
            
        if required_pattern and required_pattern not in parsed.path:
            return False

        return True
