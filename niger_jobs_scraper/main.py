import logging
from datetime import datetime
from scrapers.nigeremploi_scraper import NigerEmploiScraper
from scrapers.anpe_scraper import ANPEScraper
from scrapers.nigerjob_scraper import NigerJobScraper
from scrapers.nigercarriere_scraper import NigerCarriereScraper
from scrapers.zonemploi_scraper import ZonemploiScraper
from scrapers.nigeropportunites_scraper import NigerOpportunitesScraper
from scrapers.linkedin_scraper import LinkedInNigerScraper

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def run_pipeline():
    print("=" * 65)
    print(f" PIPELINE MULTI-SOURCES NIGER JOBS - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 65)
    
    scrapers = [
        NigerEmploiScraper(),
        ANPEScraper(),
        NigerJobScraper(),
        NigerCarriereScraper(),
        ZonemploiScraper(),
        NigerOpportunitesScraper(),
        LinkedInNigerScraper()
    ]
    
    for scraper in scrapers:
        scraper_name = scraper.__class__.__name__
        logging.info(f"---> Lancement du module : {scraper_name}")
        try:
            scraper.run()
        except Exception as e:
            logging.error(f"Échec sur {scraper_name}: {e}")
            
    print("=" * 65)
    print(" PIPELINE TERMINÉ : Données centralisées dans data/processed/")
    print("=" * 65)

if __name__ == "__main__":
    run_pipeline()
