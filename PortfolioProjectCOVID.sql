select *
from CovidDeaths
order by location, date

select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
where location like '%states'
order by location, date

-- Total Cases vs Total Deaths
-- Shows likelyhood of dying of COVID-19 if contracted in your country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from CovidDeaths
where location = 'Brazil'
order by location, date

--Total Cases vs Population
--Shows % of population that got Covid
select location, date, population, total_cases, (total_cases/population)*100 as total_cases_per_pop
from CovidDeaths
where location = 'Brazil'
order by location, date

-- Countries with highest infection rate vs population
select location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population))*100 as percent_pop_infected
from CovidDeaths
group by location, population
order by percent_pop_infected DESC

--CREATING VIEW TO STORE DATA FOR LATER VISUALIZATION - Countries with highest infection rate vs population
CREATE VIEW country_max_infection_rate AS
select location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population))*100 as percent_pop_infected
from CovidDeaths
group by location, population

-- Countries with highest death count per population
select location, max(cast(total_deaths as int)) as total_death_count
from CovidDeaths
where continent is not null
group by location
order by total_death_count desc

CREATE VIEW country_death_data AS
select location, max(cast(total_deaths as int)) as total_death_count
from CovidDeaths
where continent is not null
group by location

-- Break data down by continent

-- Showing the continents with highest death count
select  continent, max(cast(total_deaths as int)) as total_death_count
from CovidDeaths
where continent is not null
group by continent
order by total_death_count desc

-- Global Numbers
select SUM(new_cases) as world_total_cases, SUM(cast(new_deaths as int)) as world_total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_percentage
from CovidDeaths
where continent is not null
order by 1,2

--CREATING VIEW TO STORE DATA FOR LATER VISUALIZATION - World total cases, deaths and death %
CREATE VIEW world_data AS
select  SUM(new_cases) as world_total_cases, SUM(cast(new_deaths as int)) as world_total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_percentage
from CovidDeaths
where continent is not null

-- Vaccinations data

--Total pops vs vaccinations
select dea.continent, dea.location, dea.population, vacc.new_vaccinations
, sum(cast(vacc.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as total_new_vaccs
from CovidDeaths as dea
join CovidVaccination as vacc
	on dea.location = vacc.location
	and dea.date = vacc.date
where dea.continent is not null
order by 2,3

-- USE CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, total_new_vaccs) AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations,
        SUM(CAST(vacc.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_new_vaccs
    FROM CovidDeaths AS dea
    JOIN CovidVaccination AS vacc ON dea.location = vacc.location AND dea.date = vacc.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, (total_new_vaccs/population)*100 as [%_pop_vaccinated]
FROM PopvsVac
ORDER BY location, date;

-- TEMP TABLE
DROP TABLE IF EXISTS #percent_pop_vaccinated
CREATE TABLE #percent_pop_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccs numeric,
total_new_vaccs numeric
)

INSERT INTO #percent_pop_vaccinated
    SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations,
        SUM(CAST(vacc.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_new_vaccs
    FROM CovidDeaths AS dea
    JOIN CovidVaccination AS vacc 
		ON dea.location = vacc.location AND dea.date = vacc.date
    WHERE dea.continent IS NOT NULL

SELECT *, (total_new_vaccs/population)*100 as [%_pop_vaccinated]
FROM #percent_pop_vaccinated
ORDER BY location, date;

--CREATING VIEW TO STORE DATA FOR LATER VISUALIZATION %PopVaccinated
CREATE VIEW percent_pop_vaccinated AS
	SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations,
        SUM(CAST(vacc.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_new_vaccs
    FROM CovidDeaths AS dea
    JOIN CovidVaccination AS vacc 
		ON dea.location = vacc.location AND dea.date = vacc.date
    WHERE dea.continent IS NOT NULL
