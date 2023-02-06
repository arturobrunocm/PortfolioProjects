USE covid_project
GO

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
ORDER BY 1, 2

SELECT *
FROM covid_deaths
WHERE continent IS NULL
ORDER BY 3, 4
GO

---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


-- total cases vs total deaths
-- show the likelyhood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths,
	(total_deaths / total_cases) * 100 AS death_porcentage
FROM covid_deaths
WHERE location LIKE 'United States'
	AND continent IS NOT NULL
ORDER BY 1, 2


-- total cases vs population
-- shows what % of the population got covid
SELECT location, date, total_cases, population,
	(total_cases / population) * 100 AS infection_porcentage
FROM covid_deaths
WHERE location LIKE 'Peru'
ORDER BY 2


-- looking at the country with the highest infection rate compared to population
SELECT location, population,
	MAX(total_cases) AS highest_infection_count,
	MAX((total_cases / population)) * 100 AS percent_population_infected
FROM covid_deaths
GROUP BY location, population
ORDER BY percent_population_infected DESC


-- countries with the highest deathcount per population
SELECT location,
	MAX(CAST(total_deaths AS int)) AS total_death
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death DESC


---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


-- breaking things down by continent
-- showing the continents with the highest death count per population
SELECT continent,
	MAX(CAST(total_deaths AS int)) AS total_death
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death DESC


-- global number
SELECT
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS int)) AS new_deaths,
	SUM(CAST(new_deaths AS int))  / SUM(new_cases) * 100 AS death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1, 2


---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


-- total population vs total vaccs
WITH population_vs_vaccs (continent, location, date, population, new_vaccinations, total_vaccs)
AS (
	SELECT dt.continent,
		dt.location,
		dt.date,
		dt.population,
		vc.new_vaccinations,
		SUM(CONVERT(BIGINT, vc.new_vaccinations)) OVER (
			PARTITION BY dt.location
			ORDER BY dt.location,
				dt.date
		) AS total_vaccs
	FROM covid_deaths dt
	JOIN covid_vaccinations vc
		ON dt.location = vc.location
		AND dt.date = vc.date
	WHERE dt.continent IS NOT NULL
)

SELECT *,
	(total_vaccs / population) * 100 AS vacc_percent
FROM population_vs_vaccs
GO


---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


-- inserting the population_vs_vaccs in a table
-- creating the table percent_pop_vaccs
CREATE TABLE percent_pop_vaccs
(
	CONTINENT NVARCHAR(255),
	LOCATION NVARCHAR(255),
	DATE DATETIME,
	POPULATION NUMERIC,
	NEW_VACCINATIONS NUMERIC,
	TOTAL_VACCS NUMERIC
)

--  inserting the values into the table
INSERT INTO percent_pop_vaccs
	SELECT dt.continent,
		dt.location,
		dt.date,
		dt.population,
		vc.new_vaccinations,
		SUM(CONVERT(BIGINT, vc.new_vaccinations)) OVER (
			PARTITION BY dt.location
			ORDER BY dt.location,
				dt.date
		) AS total_vaccs
	FROM covid_deaths dt
	JOIN covid_vaccinations vc
		ON dt.location = vc.location
		AND dt.date = vc.date
	WHERE dt.continent IS NOT NULL

-- validating information
SELECT * FROM
percent_pop_vaccs

-- creating a view from that information
CREATE VIEW v_percent_pop_vaccs AS (
SELECT dt.continent,
		dt.location,
		dt.date,
		dt.population,
		vc.new_vaccinations,
		SUM(CONVERT(BIGINT, vc.new_vaccinations)) OVER (
			PARTITION BY dt.location
			ORDER BY dt.location,
				dt.date
		) AS total_vaccs
	FROM covid_deaths dt
	JOIN covid_vaccinations vc
		ON dt.location = vc.location
		AND dt.date = vc.date
	WHERE dt.continent IS NOT NULL
)

-- this view will be used for a viz
SELECT *
FROM dbo.v_percent_pop_vaccs