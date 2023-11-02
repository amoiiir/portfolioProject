SELECT * 
FROM [dbo].[CovidDeaths$]
WHERE continent is not null

/* SELECT * 
FROM [dbo].[CovidVaccinations$] */

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM [dbo].[CovidDeaths$]
order by 1,2

-- calculation for total cases and total deaths
-- visually seeing the ratio of people got infected by day and the total_death occured
-- understand the percentage of death according to the location
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
FROM [dbo].[CovidDeaths$]
Where location like '%Malaysia%'
order by 1,2

-- looking at the total_cases vs population
-- shows the percentage of the population that infected with covid
SELECT Location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
FROM [dbo].[CovidDeaths$]
Where location like '%Malaysia%'
order by 1,2

-- what country has the highest infection rate
SELECT Location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 as PercentPopulationInfected
FROM [dbo].[CovidDeaths$]
-- Where location like '%Malaysia%'
group by location, population
order by PercentPopulationInfected desc

-- temp tables
-- showing continents with highest death counts
-- need to cast to int because of the different data type
-- location is innaccurate since we also include continent
SELECT Location,  MAX(cast (total_deaths as int)) AS TotalDeathCount
FROM [dbo].[CovidDeaths$]
-- Where location like '%Malaysia%'
WHERE continent is not null
group by location
order by TotalDeathCount desc

-- Global numbers
-- we need to use aggregate functions to cater the error
SELECT date, SUM(new_cases) as TotalCases, sum(cast (new_deaths as int)) as TotalDeaths,sum(cast (new_deaths as int))/SUM(new_cases) * 100 as DeathPercentage --, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
FROM [dbo].[CovidDeaths$]
-- Where location like '%Malaysia%'
where continent is not null
group by date
order by 1,2

-- total deaths across the world
SELECT  SUM(new_cases) as TotalCases, sum(cast (new_deaths as int)) as TotalDeaths,sum(cast (new_deaths as int))/SUM(new_cases) * 100 as DeathPercentage --, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
FROM [dbo].[CovidDeaths$]
-- Where location like '%Malaysia%'
where continent is not null
-- group by date
order by 1,2

-- covid vaccination table

-- looking at total population
-- need to specify both of the table
-- using a temp table
select dea.continent, dea.location, dea.date, vac.new_vaccinations
, SUM(cast (vac.new_vaccinations as int)) OVER (Partition by  dea.location order by dea.location, dea.Date) as 
RollinPeopleVaccinated
, --(RollinPeopleVaccinated/Population) * 100
from [dbo].[CovidDeaths$] dea
join [dbo].[CovidVaccinations$] vac
	ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 1,2,3

-- the use of CTE

WITH PopulatVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast (vac.new_vaccinations as int)) OVER (Partition by  dea.location order by dea.location, dea.Date) as 
RollinPeopleVaccinated
--, (RollinPeopleVaccinated/Population) * 100
FROM [dbo].[CovidDeaths$] dea
join [dbo].[CovidVaccinations$] vac
	ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- order by 1,2,3
)
SELECT * , (RollingPeopleVaccinated/Population)* 100 as PercentageVaccinated
FROM PopulatVsVac

-- temp table 

DROP TABLE if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location  nvarchar(255),
date datetime,
Population numeric,
New_vaccination numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast (vac.new_vaccinations as int)) OVER (Partition by  dea.location order by dea.location, dea.Date) as 
RollinPeopleVaccinated
--, (RollinPeopleVaccinated/Population) * 100
FROM [dbo].[CovidDeaths$] dea
join [dbo].[CovidVaccinations$] vac
	ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- order by 1,2,3

SELECT * , (RollingPeopleVaccinated/Population)* 100 as PercentageVaccinated
FROM #PercentPopulationVaccinated

-- creating view

Create VIEW PercentPopulationVaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast (vac.new_vaccinations as int)) OVER (Partition by  dea.location order by dea.location, dea.Date) as 
RollinPeopleVaccinated
--, (RollinPeopleVaccinated/Population) * 100
FROM [dbo].[CovidDeaths$] dea
join [dbo].[CovidVaccinations$] vac
	ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- order by 1,2,3

Select * from PercentPopulationVaccinated