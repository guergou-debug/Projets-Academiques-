
import subprocess
import sys

scripts = [
    "src/ckan_collector.py",
    "src/osm_collector.py"
]

for script in scripts:
    print(f"\nLaunching {script}")

    result = subprocess.run(
        [sys.executable, script],
        check=False
    )

    if result.returncode != 0:
        print(f"Warning: {script} failed.")
    else:
        print(f"{script} completed.")
