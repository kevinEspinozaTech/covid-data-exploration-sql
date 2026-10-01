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
| Source | **Source pending verification.** The column names (`continent`, `location`, `total_cases`, `new_vaccinations`, …) and aggregate locations such as `European Union (27)` and `high-income countries` match the [Our World in Data COVID-19 dataset](https://github.com/owid/covid-19-data), which the course uses. The exact file and download date were not recorded. |
| Included in this repo | **No.** The data is not included. Download it from the original source and import it yourself. |

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
├── SQLProject1.sql   # All exploration queries, in execution order
└── README.md
```

## Results

The repository contains only the SQL script, with no saved query output. **No numerical results are published here** because none were stored with the project. Run the script against the dataset to reproduce them.

The aggregated outputs were later used for a Tableau dashboard. See [covid-tableau-analysis-sql](https://github.com/kevinEspinozaTech/covid-tableau-analysis-sql).

## How to run

1. Download the COVID-19 dataset (see *Dataset and source*) and split it into a deaths sheet and a vaccinations sheet with the columns listed above.
2. In SSMS, create a database called `Portfolio Project 1`.
3. Import both sheets with the SQL Server Import and Export Wizard so that the tables are named `covid-data-deaths$` and `covid-data-vaccinations$`. If you use different names, adjust them in the script.
4. Open `SQLProject1.sql` and run the queries one block at a time.

## Limitations

- Two queries, *"total cases vs total deaths"* and *"total cases vs population"*, contain two consecutive `WHERE` clauses. SQL Server rejects this; to run them, replace the second `where` with `and`. The original script is kept unchanged on purpose as a record of the learning project.
- Reported COVID-19 figures depend on each country's testing and reporting practices, so comparisons between countries are only indicative.
- The temporary-table block keeps its `where` filter commented out, so it also includes continent-level aggregate rows.
- The source file and its version were not recorded, so results may differ from newer versions of the dataset.

## Next steps

- Fix the two invalid `WHERE` clauses in a separate, documented commit.
- Add a reproducible import script (for example `BULK INSERT`) and record the dataset version.
- Publish a small table of verified results together with the query that produced them.

## Credits

- Course and original query structure: [Alex The Analyst – PortfolioProjects](https://github.com/AlexTheAnalyst/PortfolioProjects).
- Data: see *Dataset and source* (source pending verification).

## Contact

**Kevin Espinoza**, Civil Engineer transitioning into Data Analytics and Automation
GitHub: [@kevinEspinozaTech](https://github.com/kevinEspinozaTech) · Email: [k.espinozano@gmail.com](mailto:k.espinozano@gmail.com)
