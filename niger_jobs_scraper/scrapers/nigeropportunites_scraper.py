import requests
from bs4 import BeautifulSoup
import logging
import time
import hashlib
from datetime import datetime
from scrapers.base_scraper import BaseScraper
from utils.exporter import DataExporter

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

class NigerOpportunitesScraper(BaseScraper):
    def __init__(self):
        super().__init__()
        self.domain = "nigeropportunites.com"
        self.base_url = "https://nigeropportunites.com"
        self.search_url = "https://nigeropportunites.com/emplois/"
        self.exporter = DataExporter()

    def fetch_page(self, url):
        try:
            time.sleep(2)
            response = self.session.get(url, headers=self.get_headers(), timeout=15)
            response.raise_for_status()
            return response.text
        except requests.exceptions.RequestException as e:
            logging.error(f"Erreur HTTP sur {url}: {e}")
            return None

    def parse_job_page(self, job_url):
        html = self.fetch_page(job_url)
        if not html: 
            return None
        
        soup = BeautifulSoup(html, 'html.parser')
        
        def get_text_or_none(selector):
            el = soup.select_one(selector)
            return el.get_text(strip=True, separator='\n') if el else None

        content_div = soup.select_one('.entry-content, article, .job-description, .post-content') or soup
        corpus_text = content_div.get_text(separator='\n', strip=True) if content_div else None

        offre = {
            "url_offre": job_url,
            "site_source": "NigerOpportunites",
            "date_scraping": datetime.utcnow().isoformat(),
            "titre_poste": get_text_or_none('h1.entry-title, h1, .job-title'),
            "entreprise_ou_ong": get_text_or_none('.company, .employer, .meta-company'),
            "ville": get_text_or_none('.location, .job-location'),
            "region": "Niger",
            "type_contrat": get_text_or_none('.job-type, .contract-type'),
            "date_publication": get_text_or_none('time, .posted-date, .entry-date'),
            "date_limite_candidature": None,
            "salaire_affiche": None,
            "description_complete_corpus": corpus_text,
            "profil_exige_corpus": None,
            "html_brut": html
        }
        
        html_filename = f"{hashlib.md5(job_url.encode()).hexdigest()}.html"
        self.exporter.save_raw_html(html, html_filename)
        return offre

    def run(self, max_pages=3):
        logging.info("Démarrage du scraper Niger Opportunités...")
        offres = []

        for page in range(1, max_pages + 1):
            page_url = f"{self.search_url}page/{page}/" if page > 1 else self.search_url
            logging.info(f"Scraping de la page d'index {page} : {page_url}")
            
            html = self.fetch_page(page_url)
            if not html:
                break
            
            soup = BeautifulSoup(html, 'html.parser')
            job_links = soup.select('article a, h2 a, h3 a, .entry-title a, .job-title a')
            
            urls_to_scrape = set()
            for link in job_links:
                href = link.get('href')
                if href:
                    full_url = href if href.startswith('http') else f"{self.base_url}/{href.lstrip('/')}"
                    if self.is_valid_job_url(full_url, self.domain) and full_url != self.search_url:
                        urls_to_scrape.add(full_url)
            
            if not urls_to_scrape:
                logging.info("Aucune nouvelle offre sur cette page. Fin de la pagination.")
                break

            logging.info(f"{len(urls_to_scrape)} NOUVELLES offres ciblées sur la page {page}.")
            
            for url in urls_to_scrape:
                logging.info(f"Extraction de : {url}")
                offre_data = self.parse_job_page(url)
                if offre_data:
                    offres.append(offre_data)
                    self.seen_urls.add(url)

        self.exporter.save_to_jsonl(offres)
        self.exporter.save_to_csv(offres)
        logging.info(f"Succès : {len(offres)} offres ajoutées depuis Niger Opportunités.")
