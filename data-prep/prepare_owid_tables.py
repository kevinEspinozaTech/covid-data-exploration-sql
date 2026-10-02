"""Split the Our World in Data COVID-19 CSV into the two tables used by SQLProject1.sql.

Input : owid-covid-data.csv (same folder)
Output: deaths.tsv and vaccinations.tsv (tab-separated, no header, empty cell = NULL)
Uses only the Python standard library.
"""
import csv
from pathlib import Path

HERE = Path(__file__).parent
DEATHS = ["iso_code", "continent", "location", "date", "population",
          "total_cases", "new_cases", "total_deaths", "new_deaths"]
VACCINATIONS = ["iso_code", "continent", "location", "date", "new_vaccinations"]

with open(HERE / "owid-covid-data.csv", encoding="utf-8") as src, \
     open(HERE / "deaths.tsv", "w", encoding="utf-8", newline="") as deaths, \
     open(HERE / "vaccinations.tsv", "w", encoding="utf-8", newline="") as vaccinations:
    rows = 0
    for row in csv.DictReader(src):
        deaths.write("\t".join(row[c] for c in DEATHS) + "\n")
        vaccinations.write("\t".join(row[c] for c in VACCINATIONS) + "\n")
        rows += 1

print(f"{rows} rows written to deaths.tsv and vaccinations.tsv")
