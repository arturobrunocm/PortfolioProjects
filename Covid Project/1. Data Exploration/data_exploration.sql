------------------------------------
-- Data Exploration in SQL Server --
------------------------------------

/*
Author:     Arturo Contreras Montoya
Dataset:    https://ourworldindata.org/covid-deaths
*/


-- =================================================


-- Inicial exploration of the database COVID_PROJECT
USE COVID_PROJECT
GO

SELECT *
FROM COVID_DEATHS
GO

SELECT *
FROM COVID_VACCINATIONS
GO

SELECT LOCATION
  , DATE
  , TOTAL_CASES
  , NEW_CASES
  , TOTAL_DEATHS
  , POPULATION
FROM COVID_DEATHS
ORDER BY 1, 2
GO

SELECT *
FROM COVID_DEATHS
WHERE CONTINENT IS NULL
ORDER BY 3, 4
GO


-- =================================================


-- Total cases vs total deaths
-- Show the probability of dying if you contract COVID-19 in your country
SELECT LOCATION
  , DATE
  , TOTAL_CASES
  , TOTAL_DEATHS
  , (TOTAL_DEATHS / TOTAL_CASES) * 100 AS DEATH_PORCENTAGE
FROM COVID_DEATHS
WHERE LOCATION LIKE 'United States'
    AND CONTINENT IS NOT NULL
ORDER BY 1, 2
GO

-- Total cases vs population
-- Shows what % of the population got COVID-19
SELECT LOCATION
  , DATE
  , TOTAL_CASES
  , POPULATION
  , (TOTAL_CASES / POPULATION) * 100 AS INFECTION_PORCENTAGE
FROM COVID_DEATHS
WHERE LOCATION LIKE 'Peru'
ORDER BY 2
GO

-- Countries with the highest infection rate per population
SELECT LOCATION
  , POPULATION
  , MAX(TOTAL_CASES)                      AS HIGHEST_INFECTION_COUNT
  , MAX((TOTAL_CASES / POPULATION)) * 100 AS PERCENT_POPULATION_INFECTED
FROM COVID_DEATHS
GROUP BY LOCATION
  , POPULATION
ORDER BY PERCENT_POPULATION_INFECTED DESC
GO

-- Countries with the highest deathcount per population
SELECT LOCATION
  , MAX(CAST(TOTAL_DEATHS AS INT)) AS TOTAL_DEATH
FROM COVID_DEATHS
WHERE CONTINENT IS NOT NULL
GROUP BY LOCATION
ORDER BY TOTAL_DEATH DESC
GO


-- =================================================


-- Breaking things down by continent
-- Showing the continents with the highest deathcount per population
SELECT CONTINENT
  , MAX(CAST(TOTAL_DEATHS AS INT)) AS TOTAL_DEATH
FROM COVID_DEATHS
WHERE CONTINENT IS NOT NULL
GROUP BY CONTINENT
ORDER BY TOTAL_DEATH DESC
GO

-- Global numbers (untill febrary 4th, 2023)
SELECT SUM(NEW_CASES)                                   AS TOTAL_CASES
  , SUM(CAST(NEW_DEATHS AS INT))                        AS NEW_DEATHS
  , SUM(CAST(NEW_DEATHS AS INT)) / SUM(NEW_CASES) * 100 AS DEATH_PERCENTAGE
FROM COVID_DEATHS
WHERE CONTINENT IS NOT NULL
GO


-- =================================================


-- Total population vs total vaccs
WITH
    POPULATION_VS_VACCS (CONTINENT, LOCATION, DATE, POPULATION, NEW_VACCINATIONS, TOTAL_VACCS) AS (
        SELECT DT.CONTINENT
          , DT.LOCATION
          , DT.DATE
          , DT.POPULATION
          , VC.NEW_VACCINATIONS
          , SUM(CONVERT(BIGINT, VC.NEW_VACCINATIONS)) OVER (
                PARTITION BY DT.LOCATION
                ORDER BY DT.LOCATION
                  , DT.DATE
            ) AS TOTAL_VACCS
        FROM COVID_DEATHS DT
            JOIN COVID_VACCINATIONS VC
                ON DT.LOCATION = VC.LOCATION
                AND DT.DATE = VC.DATE
        WHERE DT.CONTINENT IS NOT NULL
    )

SELECT *
  , (TOTAL_VACCS / POPULATION) * 100 AS VACC_PERCENT
FROM POPULATION_VS_VACCS
GO


-- =================================================


-- Inserting the POPULATION_VS_VACCS in a table
-- Creating the table percent_pop_vaccs
CREATE TABLE PERCENT_POP_VACCS (
    CONTINENT NVARCHAR (255)
  , LOCATION NVARCHAR (255)
  , DATE DATETIME
  , POPULATION NUMERIC
  , NEW_VACCINATIONS NUMERIC
  , TOTAL_VACCS NUMERIC
)
GO

-- Inserting POPULATION_VS_VACCS rows into the table
INSERT INTO
    PERCENT_POP_VACCS
SELECT DT.CONTINENT
  , DT.LOCATION
  , DT.DATE
  , DT.POPULATION
  , VC.NEW_VACCINATIONS
  , SUM(CONVERT(BIGINT, VC.NEW_VACCINATIONS)) OVER (
        PARTITION BY DT.LOCATION
        ORDER BY DT.LOCATION
          , DT.DATE
    ) AS TOTAL_VACCS
FROM COVID_DEATHS DT
    JOIN COVID_VACCINATIONS VC
        ON DT.LOCATION = VC.LOCATION
        AND DT.DATE = VC.DATE
WHERE DT.CONTINENT IS NOT NULL
GO

-- Validating the insertion
SELECT *
FROM PERCENT_POP_VACCS
GO

-- Creating a view from POPULATION_VS_VACCS
-- This view will be used latter for a Power BI visualization
CREATE VIEW
    V_PERCENT_POP_VACCS AS (
        SELECT DT.CONTINENT
        , DT.LOCATION
        , DT.DATE
        , DT.POPULATION
        , VC.NEW_VACCINATIONS
        , SUM(CONVERT(BIGINT, VC.NEW_VACCINATIONS)) OVER (
                PARTITION BY DT.LOCATION
                ORDER BY DT.LOCATION
                , DT.DATE
            ) AS TOTAL_VACCS
        FROM COVID_DEATHS DT
            JOIN COVID_VACCINATIONS VC
                ON DT.LOCATION = VC.LOCATION
                AND DT.DATE = VC.DATE
        WHERE DT.CONTINENT IS NOT NULL
    )

SELECT *
FROM V_PERCENT_POP_VACCS
GO