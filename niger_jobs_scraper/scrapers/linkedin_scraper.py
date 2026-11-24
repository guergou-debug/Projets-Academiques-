import logging
import hashlib
import time
from datetime import datetime
from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright
from scrapers.base_scraper import BaseScraper
from utils.exporter import DataExporter

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

class LinkedInNigerScraper(BaseScraper):
    def __init__(self):
        super().__init__()
        self.domain = "linkedin.com"
        self.search_url = "https://www.linkedin.com/jobs/search/?keywords=&location=Niger"
        self.exporter = DataExporter()

    def run(self):
        logging.info("Démarrage du scraper LinkedIn Niger (Playwright)...")
        offres = []

        try:
            with sync_playwright() as p:
                browser = p.chromium.launch(headless=True)
                page = browser.new_page()
                page.set_extra_http_headers({"User-Agent": self.ua.random})
                
                page.goto(self.search_url, timeout=30000)
                page.wait_for_selector('.jobs-search__results-list, .results-context-header', timeout=10000)
                
                # Défilement pour charger davantage d'offres dynamiques
                for _ in range(3):
                    page.mouse.wheel(0, 2000)
                    time.sleep(1.5)

                html_content = page.content()
                soup = BeautifulSoup(html_content, 'html.parser')
                
                links = soup.select('a.base-card__full-link, a[href*="/jobs/view/"]')
                urls_to_scrape = set()

                for a in links:
                    url = a.get('href', '').split('?')[0]
                    if self.is_valid_job_url(url, self.domain):
                        urls_to_scrape.add(url)

                logging.info(f"{len(urls_to_scrape)} NOUVELLES offres identifiées sur LinkedIn Niger.")

                for url in list(urls_to_scrape)[:15]:
                    logging.info(f"Extraction LinkedIn : {url}")
                    try:
                        page.goto(url, timeout=20000)
                        time.sleep(2)
                        job_html = page.content()
                        job_soup = BeautifulSoup(job_html, 'html.parser')

                        title = job_soup.select_one('h1.top-card-layout__title, h1')
                        company = job_soup.select_one('a.topcard__org-name-link, .topcard__flavor')
                        location = job_soup.select_one('span.topcard__flavor--bullet')
                        description = job_soup.select_one('.show-more-less-html__markup, .description__text')

                        corpus = description.get_text(separator='\n', strip=True) if description else None

                        offre = {
                            "url_offre": url,
                            "site_source": "LinkedIn_Niger",
                            "date_scraping": datetime.utcnow().isoformat(),
                            "titre_poste": title.get_text(strip=True) if title else None,
                            "entreprise_ou_ong": company.get_text(strip=True) if company else None,
                            "ville": location.get_text(strip=True) if location else None,
                            "region": "Niger",
                            "type_contrat": None,
                            "date_publication": None,
                            "date_limite_candidature": None,
                            "salaire_affiche": None,
                            "description_complete_corpus": corpus,
                            "profil_exige_corpus": None,
                            "html_brut": job_html
                        }

                        offres.append(offre)
                        self.seen_urls.add(url)

                        html_filename = f"{hashlib.md5(url.encode()).hexdigest()}.html"
                        self.exporter.save_raw_html(job_html, html_filename)

                    except Exception as e:
                        logging.error(f"Erreur sur la page d'offre LinkedIn {url}: {e}")

                browser.close()

        except Exception as e:
            logging.error(f"Erreur d'exécution de Playwright pour LinkedIn: {e}")

        self.exporter.save_to_jsonl(offres)
        self.exporter.save_to_csv(offres)
        logging.info(f"Succès : {len(offres)} offres exportées depuis LinkedIn Niger.")
