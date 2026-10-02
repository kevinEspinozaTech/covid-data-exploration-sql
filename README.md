# COVID-19 Data Exploration with SQL Server

Exploratory analysis of global COVID-19 case, death and vaccination data written in T-SQL (Microsoft SQL Server).

> **Guided learning project.** This project follows the *Data Analyst Portfolio Project* series by
> [Alex The Analyst](https://github.com/AlexTheAnalyst/PortfolioProjects) ("COVID Portfolio Project – Data Exploration").
> I wrote and ran the queries myself while following the course and adapted parts of them, for example filtering on Chile.
> The structure and techniques come from the course, so this is not original research.

## Context

This was the first project in my transition from civil engineering into data analytics. Its aim was to practise SQL on a large, real-world public dataset: loading it, joining tables, calculating rates and preparing views for later visualisation.

## Questions explored

1. What share of reported cases ended in death, per country and over time (for example in Chile)?
2. What share of each country's population was reported as infected?
3. Which countries had the highest infection rate relative to their population?
4. Which countries and continents reported the highest death counts?
5. What were the global totals of new cases and deaths, and the global death percentage?
6. How did the cumulative number of vaccinations grow per country, relative to its population?

## Technologies

- Microsoft SQL Server (T-SQL)
- SQL Server Management Studio (SSMS)
- Excel files imported as SQL Server tables

## Dataset and source

| Item | Detail |
|---|---|
| Source | [Our World in Data – COVID-19 dataset](https://github.com/owid/covid-19-data), file [`owid-covid-data.csv`](https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/owid-covid-data.csv) (final version, last updated 2024-08-19; data from 2020-01-01 to 2024-08-14; 429,435 rows). License: CC BY 4.0. |
| How the source was verified | Re-running these queries on that file reproduces exactly the totals shown in my published [Tableau dashboard](https://public.tableau.com/app/profile/kevin.espinoza1014/viz/CovidDashboardP2/Dashboard1): 775,935,057 cases, 7,060,988 deaths and a maximum infection rate of 77.72%. The aggregate locations excluded in the scripts, such as `European Union (27)` and the income groups, also match this version. |
| Included in this repo | **No.** The ~98 MB CSV is not stored here. [`data-prep/`](data-prep/) contains the scripts that download it, split it into the two tables and load them. |

### Expected schema

The script expects a database called `Portfolio Project 1` with two tables. These were created by importing two Excel sheets, which is why the table names end in `$`:

| Table | Columns used by the queries |
|---|---|
| `dbo.['covid-data-deaths$']` | `continent`, `location`, `date`, `population`, `total_cases`, `new_cases`, `total_deaths`, `new_deaths` |
| `dbo.['covid-data-vaccinations$']` | `continent`, `location`, `date`, `new_vaccinations` |

The two tables are joined on `location` + `date`.

## Methodology

1. Inspect both tables and exclude continent-level aggregate rows (`where continent is not null`).
2. Calculate the death percentage (`total_deaths / total_cases`) and the infection percentage (`total_cases / population`), using `NULLIF` to avoid division by zero.
3. Aggregate with `MAX` and `GROUP BY` to rank countries and continents.
4. Calculate global totals with `SUM` over `new_cases` and `new_deaths`.
5. Join the death and vaccination tables and calculate a rolling vaccination count with a window function.
6. Reuse that rolling count through a CTE and a temporary table, then save it as a view for visualisation.

## Techniques demonstrated

| Technique | Where it is used |
|---|---|
| `JOIN` | Deaths ⟷ vaccinations on `location` and `date` |
| Window function | `SUM(...) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)` for rolling vaccinations |
| CTE | `WITH PopvsVac (...) AS (...)` to calculate the vaccinated percentage from the rolling count |
| Temporary table | `#percentajePopulationVaccinated` with `DROP TABLE IF EXISTS` and `INSERT INTO ... SELECT` |
| View | `CREATE VIEW percentajePopulationVaccinated` stores the result for later visualisation |
| Type conversion | `CONVERT(bigint, ...)` and `CAST(... AS bigint)` to avoid overflow in large sums |
| Safe division | `NULLIF(total_cases, 0)` |
| Aggregation | `MAX`, `SUM`, `GROUP BY`, `ORDER BY ... DESC` |

### Representative snippets

Rolling vaccinations with a window function:

```sql
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       sum(convert(bigint, vac.new_vaccinations))
           over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinatios
from [Portfolio Project 1]..['covid-data-deaths$'] dea
join [Portfolio Project 1]..['covid-data-vaccinations$'] vac
  on dea.location = vac.location
 and dea.date = vac.date
where dea.continent is not null
```

Reusing the rolling count in a CTE:

```sql
with PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinatios) as
( ... same query as above ... )
select *, (RollingPeopleVaccinatios / population) * 100 as PercentajePeopleVac
from PopvsVac
```

## Repository structure

```
.
├── SQLProject1.sql                 # All exploration queries, runnable end to end
├── data-prep/
│   ├── prepare_owid_tables.py      # Splits the OWID CSV into the two tables (standard library only)
│   ├── create_tables.sql           # Creates the database and the two tables
│   └── load_with_bcp.cmd           # Loads both tables with bcp
└── README.md
```

## Results

These results come from running `SQLProject1.sql` on SQL Server 2025 against the OWID file described above (run on 2026-10-02; data up to 2024-08-14). Each value is produced by the query named in the left column.

| Query in the script | Result |
|---|---|
| *Global total deaths percentage* | 775,935,057 cases · 7,060,988 deaths · **0.91%** of reported cases ended in death |
| *Highest infection rate compared to population* (top 5) | Cyprus 77.72% · Brunei 77.44% · San Marino 75.07% · Austria 68.04% · South Korea 66.72% |
| *Highest death count* (top 5) | United States 1,193,165 · Brazil 702,116 · India 533,623 · Russia 403,188 · Mexico 334,551 |
| *Total cases vs total deaths*, Chile, last reported date (2024-08-04) | 5,401,126 cases · 62,730 deaths · **1.16%** |

**One detail checked while validating the results:** the rolling "people vaccinated" column in the CTE adds up `new_vaccinations`. That field counts **doses**, not people. For Luxembourg the running total reaches 1,286,886 by 2023-03-25, which is about twice the country's population. So the "percentage of people vaccinated" calculated this way can exceed 100%. To measure people, use `people_vaccinated` or `people_fully_vaccinated` from the same dataset.

The aggregated outputs feed my Tableau dashboard. See [covid-tableau-analysis-sql](https://github.com/kevinEspinozaTech/covid-tableau-analysis-sql).

## How to run

1. Download `owid-covid-data.csv` (link in *Dataset and source*) into `data-prep/`.
2. Run `python data-prep/prepare_owid_tables.py`. It writes `deaths.tsv` and `vaccinations.tsv`.
3. Run `sqlcmd -S localhost -E -C -i data-prep/create_tables.sql` to create the database `Portfolio Project 1` and both tables.
4. Run `data-prep\load_with_bcp.cmd` to load the two tables (429,435 rows each).
5. Run `sqlcmd -S localhost -E -C -d "Portfolio Project 1" -i SQLProject1.sql`, or open the file in SSMS and execute it.

## Limitations

- Reported COVID-19 figures depend on each country's testing and reporting practices, so comparisons between countries are only indicative.
- `new_vaccinations` counts doses, so the rolling "people vaccinated" percentage is overstated (see *Results*).
- The temporary-table block keeps its `where` filter commented out, so it also includes continent-level aggregate rows.
- The "highest death count by continent" query takes the `MAX` of country rows, so it returns the worst-hit **country** in each continent, not the continent total. [covid-tableau-analysis-sql](https://github.com/kevinEspinozaTech/covid-tableau-analysis-sql) calculates the actual totals.

### Fixed issues

In October 2026 the script was corrected in a separate pull request. The original version is preserved in Git history.

- Two queries had two consecutive `WHERE` clauses, which SQL Server rejects. The second one is now `AND`.
- The CTE now starts with `;WITH`, and `CREATE VIEW` sits in its own batch (`GO`). Before this change, the file could not be executed as a whole.

## Next steps

- Measure vaccination coverage with `people_fully_vaccinated` instead of summing doses.
- Calculate true continent totals in the continent query.

## Credits

- Course and original query structure: [Alex The Analyst – PortfolioProjects](https://github.com/AlexTheAnalyst/PortfolioProjects).
- Data: Our World in Data, COVID-19 dataset (CC BY 4.0). Sources and citation: https://github.com/owid/covid-19-data.

## Contact

**Kevin Espinoza**, Civil Engineer transitioning into Data Analytics and Automation
GitHub: [@kevinEspinozaTech](https://github.com/kevinEspinozaTech) · Email: [k.espinozano@gmail.com](mailto:k.espinozano@gmail.com)
