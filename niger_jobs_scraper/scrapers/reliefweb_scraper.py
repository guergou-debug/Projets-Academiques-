import requests
from bs4 import BeautifulSoup
import logging
from datetime import datetime
from scrapers.base_scraper import BaseScraper
from utils.exporter import DataExporter

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

class ReliefWebNigerScraper(BaseScraper):
    def __init__(self):
        super().__init__()
        self.api_url = "https://api.reliefweb.int/v1/jobs"
        self.exporter = DataExporter()

    def strip_html_tags(self, html_content):
        if not html_content: return None
        soup = BeautifulSoup(html_content, 'html.parser')
        return soup.get_text(separator='\n', strip=True)

    def run(self):
        logging.info("Démarrage du scraper ReliefWeb Niger (via API)...")
        
        params = {
            "appname": "niger_jobs_scraper",
            "profile": "full",
            "limit": 100, 
            "filter[field]": "country.name",
            "filter[value]": "Niger",
            "sort[]": "date:desc"
        }

        try:
            response = self.session.get(self.api_url, params=params, timeout=15)
            response.raise_for_status()
            data = response.json()
        except requests.exceptions.RequestException as e:
            logging.error(f"Erreur HTTP lors de l'appel à l'API : {e}")
            return

        jobs = data.get('data', [])
        if not jobs:
            logging.warning("Aucune offre trouvée pour le Niger via l'API.")
            return

        logging.info(f"{len(jobs)} offres brutes trouvées. Début du formatage...")
        
        offres_collectees = []
        for job in jobs:
            fields = job.get('fields', {})
            
            job_url = fields.get('url', '')
            titre = fields.get('title')
            
            sources = fields.get('source', [])
            entreprise = sources[0].get('name') if sources else None
            
            job_types = fields.get('job_type', [])
            type_contrat = job_types[0].get('name') if job_types else None
            
            dates = fields.get('date', {})
            
            html_body = fields.get('body-html', '')
            corpus = self.strip_html_tags(html_body)

            offre = {
                "url_offre": job_url,
                "site_source": "ReliefWeb_Niger",
                "date_scraping": datetime.utcnow().isoformat(),
                "titre_poste": titre,
                "entreprise_ou_ong": entreprise,
                "ville": None,
                "region": "Niger",
                "type_contrat": type_contrat,
                "date_publication": dates.get('created'),
                "date_limite_candidature": dates.get('closing'),
                "salaire_affiche": None,
                "description_complete_corpus": corpus,
                "profil_exige_corpus": None,
                "html_brut": html_body
            }
            
            offres_collectees.append(offre)

        self.exporter.save_to_jsonl(offres_collectees)
        self.exporter.save_to_csv(offres_collectees)
        logging.info(f"Succès : {len(offres_collectees)} offres formatées et exportées dans data/processed/.")
