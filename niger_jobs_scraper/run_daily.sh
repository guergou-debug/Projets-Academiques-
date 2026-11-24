#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate
python main.py >> data/pipeline.log 2>&1
