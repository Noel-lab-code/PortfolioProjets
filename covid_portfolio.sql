use PortfolioProject1;

select * from dbo.covidDeath order by 3, 4;

select * from dbo.covidVaccination order by 3, 4;

ALTER TABLE dbo.covidDeath DROP COLUMN F61,F62,F63,F64;


-- let's select Data that we're going to be using

select 
	location, date, total_cases, new_cases, total_deaths, population
fROM 
	dbo.covidDeath 
order by 1,2;

-- Looking at Total case vs total Deaths
-- shows likelihood of dying if you contract covid in your country
select 
	location, date, total_cases, total_deaths, (total_deaths/total_cases) *100 as DeathPercentage -- we multiply by 100 to result in pecentage
fROM 
	dbo.covidDeath 
order by 1,2;


-- filtering for a specific country

select 
	location, date, total_cases, total_deaths, (total_deaths/total_cases) *100 as DeathPercentage 
fROM 
	dbo.covidDeath
where location like '%states%'
order by 1,2;

-- looking at Total Cases vs Population
-- shows what percentage of population got covid

select 
	location, date, total_cases, population, (total_cases/population)*100 as PercentagePopulationInfected
fROM 
	dbo.covidDeath
where location like '%congo%'
order by 1,2;


-- looking at Counties with Highest Infection Rate compared toPopulation

select 
	location, population, Max(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as 
	PercentagePopulationInfected
fROM 
	dbo.covidDeath
--where location like '%congo%'
group by location, population
order by PercentagePopulationInfected desc;

-- showing countries with Highest death count per population

select 
	location, Max(cast(total_deaths as int)) as TotalDeathCount
fROM 
	dbo.covidDeath
--where location like '%congo%'
where continent is not null
group by location
order by TotalDeathCount desc;

-- let's break thing by continent

select 
	location, Max(cast(total_deaths as int)) as TotalDeathCount
fROM 
	dbo.covidDeath
--where location like '%congo%'
where continent is null
group by location
order by TotalDeathCount desc;

-- global numbers

select 
	date, SUM(new_cases) as New_cases, SUM(cast(new_deaths as int)) as New_death,  
	SUM(cast(new_deaths as int))/SUM(new_cases) as DeathPercentage
fROM 
	dbo.covidDeath
--where location like '%congo%'
where continent is not null
group by date
order by 1,2;


-- Global Total cases 

select 
	SUM(new_cases) as New_cases, SUM(cast(new_deaths as int)) as New_death,  
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
fROM 
	dbo.covidDeath
--where location like '%congo%'
where continent is not null
--group by date
order by 1,2;

-- Now let's join the two tables

select *
from dbo.covidDeath as dea
join dbo.covidVaccination as vac 
	on dea.location = vac.location
	and dea.date = vac.date

-- looking at Total population vs Vaccinations

select 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from dbo.covidDeath as dea
join dbo.covidVaccination as vac 
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2, 3;

-- creating a temp table wich will help us know how many people are vaccinated in any country

With 
	PopvsVac (continent, location, date, population, new_vaccination, RollingPeopleVaccination)
AS 
 (
	select 
		dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		Sum(Convert(int, vac.new_vaccinations)) Over (Partition by dea.location order by 
		dea.date) as RollingPeopleVaccination
	from dbo.covidDeath as dea
	join dbo.covidVaccination as vac 
		on dea.location = vac.location
		and dea.date = vac.date
	where dea.continent is not null
	--order by 2, 3
)
select *, (RollingPeopleVaccination/population)*100 as PercentageRollingPeopleVaccination
from PopvsVac

-- TEMP TABLE

DROP TABLE IF EXISTS #PercentagePopulationVaccinated
Create table #PercentagePopulationVaccinated
(
	continent nvarchar(255),
	location nvarchar(255),
	date nvarchar(255),
	population numeric,
	new_vaccinations numeric,
	RollingPeopleVaccination numeric
	)

Insert into #PercentagePopulationVaccinated

	select 
			dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
			Sum(Convert(int, vac.new_vaccinations)) Over (Partition by dea.location order by 
			dea.date) as RollingPeopleVaccination
		from dbo.covidDeath as dea
		join dbo.covidVaccination as vac 
			on dea.location = vac.location
			and dea.date = vac.date
		where dea.continent is not null


select *, (RollingPeopleVaccination/population)*100 as PercentageRollingPeopleVaccination
from #PercentagePopulationVaccinated


-- Creating View to store data for later visualizations

Create view PercentagePopulationVaccinated as
	select 
			dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
			Sum(Convert(int, vac.new_vaccinations)) Over (Partition by dea.location order by 
			dea.date) as RollingPeopleVaccination
		from dbo.covidDeath as dea
		join dbo.covidVaccination as vac 
			on dea.location = vac.location
			and dea.date = vac.date
		where dea.continent is not null

select * 
from PercentagePopulationVaccinated