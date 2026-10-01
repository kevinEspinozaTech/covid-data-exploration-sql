

SELECT *
from [Portfolio Project 1].dbo.['covid-data-deaths$']
where continent is not null
order by 3,4


SELECT *
from [Portfolio Project 1].dbo.['covid-data-vaccinations$']
order by 3,4

 --selecting data to use

SELECT location, date, total_cases, new_cases, total_deaths, population
from [Portfolio Project 1].dbo.['covid-data-deaths$']
order by 1,2


--looking at total cases vs total deaths
--shows the likelihood of dying if you contract covid in your country

SELECT location, date, total_cases,total_deaths, (total_deaths /nullif (total_cases,0))*100 as DeathPercentage
from [Portfolio Project 1].dbo.['covid-data-deaths$']
where continent is not null
where location like 'Chile'
order by 1,2


-- looking at the total cases vs population
-- shows the percentage of the population that got covid

SELECT location, date, population, total_cases,  (total_Cases/population)*100 as PercentagePopulationInfected
from [Portfolio Project 1].dbo.['covid-data-deaths$']
where continent is not null
where location like 'Chile'
order by 1,2

-- looking at the countries with the highest infection rate compared to population

SELECT location, population, max(total_cases) as Highestinfeccioncount,  max((total_Cases/population))*100 as MAXPercentagePopulationInfected
from [Portfolio Project 1].dbo.['covid-data-deaths$']
where continent is not null
--where location like 'Chile'
Group by location, population
order by MAXPercentagePopulationInfected desc

--showing countries with the highest death count per population

SELECT location, population, max(total_deaths) as HighestDeathscount
from [Portfolio Project 1].dbo.['covid-data-deaths$']
where continent is not null
--where location like 'Chile'
Group by location, population
order by HighestDeathscount desc

-- let's do it by continent

SELECT continent, max(total_deaths) as HighestDeathscount
from [Portfolio Project 1].dbo.['covid-data-deaths$']
where continent is not null
--where location like 'Chile'
Group by continent
order by HighestDeathscount desc

-- Global Numbers
-- total new global cases and deaths per week 

SELECT date, sum(new_cases) as totalCases, sum(new_deaths) as totalDeaths, sum(new_deaths)/sum(Nullif(new_cases,0)) * 100 as GlobalPercentajeDeaths
from [Portfolio Project 1].dbo.['covid-data-deaths$']
where continent is not null
--where location like 'Chile'
group by date
order by 1,2

--show the global total deaths percentage

SELECT  sum(new_cases) as totalCases, sum(new_deaths) as totalDeaths, sum(new_deaths)/sum(Nullif(new_cases,0)) * 100 as GlobalPercentajeDeaths
from [Portfolio Project 1].dbo.['covid-data-deaths$']
where continent is not null
--where location like 'Chile'
--group by date
order by 1,2

-- total population vs vaccinations

select dea.continent,dea.location,dea.date,vac.new_vaccinations
from [Portfolio Project 1]..['covid-data-deaths$'] dea

join [Portfolio Project 1]..['covid-data-vaccinations$'] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 1,2,3



select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations, sum(convert(bigint,vac.new_vaccinations)) Over (partition by dea.location order by dea.location,dea.date)
as RollingPeopleVaccinatios
from [Portfolio Project 1]..['covid-data-deaths$'] dea

join [Portfolio Project 1]..['covid-data-vaccinations$'] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- USE CTE
with PopvsVac (continent,location,date,population,new_vaccinations,RollingPeopleVaccinatios)
as
(
select dea.continent,dea.location,dea.date,dea.population, vac.new_vaccinations, sum(convert(bigint,vac.new_vaccinations)) Over (partition by dea.location order by dea.location,dea.date)
as RollingPeopleVaccinatios
from [Portfolio Project 1]..['covid-data-deaths$'] dea

join [Portfolio Project 1]..['covid-data-vaccinations$'] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select*, (RollingPeopleVaccinatios/population)*100 as PercentajePeopleVac
from PopvsVac


-- TEMP TABLE

DROP TABLE IF exists #percentajePopulationVaccinated 

create table #percentajePopulationVaccinated 
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinatios numeric

)
insert into #percentajePopulationVaccinated 
select dea.continent,dea.location,dea.date,dea.population, vac.new_vaccinations, sum(cast(vac.new_vaccinations as bigint)) Over (partition by dea.location order by dea.location,dea.date)
as RollingPeopleVaccinatios
from [Portfolio Project 1]..['covid-data-deaths$'] dea

join [Portfolio Project 1]..['covid-data-vaccinations$'] vac
on dea.location = vac.location
and dea.date = vac.date
--where new_vaccinations is not null
--order by 2,3

select*, (RollingPeopleVaccinatios/population)*100 
from #percentajePopulationVaccinated 



-- create view to store data for later visualization 

create view 
percentajePopulationVaccinated as

select dea.continent,dea.location,dea.date,dea.population, vac.new_vaccinations, sum(cast(vac.new_vaccinations as bigint)) Over (partition by dea.location order by dea.location,dea.date)
as RollingPeopleVaccinatios
from [Portfolio Project 1]..['covid-data-deaths$'] dea

join [Portfolio Project 1]..['covid-data-vaccinations$'] vac
on dea.location = vac.location
and dea.date = vac.date
--where new_vaccinations is not null
--order by 2,3

select*
from percentajePopulationVaccinated