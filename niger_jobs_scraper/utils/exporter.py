import json
import csv
import os

class DataExporter:
    def __init__(self, output_dir="data/processed/", raw_dir="data/raw/"):
        self.output_dir = output_dir
        self.raw_dir = raw_dir
        os.makedirs(self.output_dir, exist_ok=True)
        os.makedirs(self.raw_dir, exist_ok=True)

    def save_to_jsonl(self, data_list, filename="offres.jsonl"):
        if not data_list: return
        filepath = os.path.join(self.output_dir, filename)
        with open(filepath, 'a', encoding='utf-8') as f:
            for item in data_list:
                item_light = {k: v for k, v in item.items() if k != "html_brut"}
                f.write(json.dumps(item_light, ensure_ascii=False) + '\n')

    def save_to_csv(self, data_list, filename="offres.csv"):
        if not data_list: return
        filepath = os.path.join(self.output_dir, filename)
        file_exists = os.path.isfile(filepath)
        
        keys = [k for k in data_list[0].keys() if k != "html_brut"]
        with open(filepath, 'a', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=keys, quoting=csv.QUOTE_ALL)
            if not file_exists:
                writer.writeheader()
            for item in data_list:
                writer.writerow({k: v for k, v in item.items() if k in keys})

    def save_raw_html(self, html_content, filename):
        if not html_content: return
        filepath = os.path.join(self.raw_dir, filename)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(html_content)
