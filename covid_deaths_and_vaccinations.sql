-----------------------------------------------------------------------------------
-- Jesus Pompa COVID DATA Exploration Project 
-- PostgresSQL using PGAdmin
-----------------------------------------------------------------------------------

-- DATA from https://ourworldindata.org/covid-deaths February 04, 2020 - February 13, 2023
-- Downloaded CSV file and created two CSV files from it, one that contained information about deaths and one about vaccinations

-- Importing DATA from CSV file about COVID deaths

CREATE TABLE covid_deaths(
	iso_code text,
	continent text,
	location text,
	date date,
	population bigint,
	total_cases bigint,
	new_cases bigint,
	new_cases_smoothed numeric(20,3),
	total_deaths bigint,
	new_deaths int,
	new_deaths_smoothed numeric(20,3),
	total_cases_per_million numeric(20,3),
	new_cases_per_million numeric(20,3),
	new_cases_smoothed_per_million numeric(20,3),
	total_deaths_per_million numeric(20,3),
	new_deaths_per_million numeric(20,3),
	new_deaths_smoothed_per_million numeric(20,3),
	reproduction_rate numeric(4,2),
	icu_patients int,
	icu_patients_per_million numeric(20,3),
	hosp_patients int,
	hosp_patients_per_million numeric(20,3),
	weekly_icu_admissions int,
	weekly_icu_admissions_per_million numeric(20,3),
	weekly_hosp_admissions int,
	weekly_hosp_admissions_per_million numeric(20,3)
);
COPY covid_deaths
FROM '/Users/jesuspompa/Downloads/covid_deaths.csv'
WITH (FORMAT CSV, HEADER); 

-- To quickly see the top few rows and compare it from our CSV file
SELECT * FROM covid_deaths LIMIT 5;

-- To see how many rows were imported
SELECT count(*) FROM covid_deaths;
	-- 257,247 rows were imported which is the same as the CSV file
	
-- Import covid_vaccinations csv

CREATE TABLE covid_vaccinations(
	iso_code text,
	continent text,
	location text,
	date date,
	total_tests bigint,
	new_tests bigint,
	total_tests_per_thousand numeric(20,3),
	new_tests_per_thousand numeric(20,3),
	new_tests_smoothed bigint,
	new_tests_smoothed_per_thousand numeric(20,3),
	positive_rate numeric (20,4),
	tests_per_case numeric (20,1),
	tests_units text,
	total_vaccinations bigint,
	people_vaccinated bigint,
	people_fully_vaccinated bigint,
	total_boosters bigint,
	new_vaccinations bigint,
	new_vaccinations_smoothed bigint,
	total_vaccinations_per_hundred numeric(20,2),
	people_vaccinated_per_hundred numeric(20,2),
	people_fully_vaccinated_per_hundred numeric(20,2),
	total_boosters_per_hundred numeric(20,2),
	new_vaccinations_smoothed_per_million bigint,
	new_people_vaccinated_smoothed bigint, 
	new_peope_vaccinated_smoothed_per_hundred numeric(20,3),
	stringency_index numeric(20,2),
	population_density numeric(20,3),
	median_age numeric(20,1),
	aged_65_older numeric(20,3),
	aged_70_older numeric(20,3),
	gdp_per_capita numeric(20,3),
	extreme_poverty numeric(20,1),
	cardiovasc_death_rate numeric(20,3),
	diabetes_prevalance numeric(20,2),
	female_smokers numeric(20,2),
	male_smokers numeric(20,2),
	handwashing_facilities numeric(20,3),
	hospital_beds_per_thousand numeric(20,1),
	life_expectancy numeric(20,2),
	human_development_index numeric(20,3),
	excess_mortality_cumulative_absolute numeric(20,1),
	excess_mortality_cumulative numeric(20,2),
	excess_mortality numeric(20,2),
	excess_mortality_cumulative_million numeric(20,3)
);
COPY covid_vaccinations
FROM '/Users/jesuspompa/Downloads/covid_vaccinations.csv'
WITH (FORMAT CSV, HEADER); 

SELECT * FROM covid_vaccinations;

SELECT count(*) FROM covid_vaccinations; -- we get 257,257 same amount as rows from covid_deaths

-- Basic Information on cases of COVID 
SELECT location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM covid_deaths
ORDER BY location, date;

-- Information on Total Cases vs Total Deaths of the United States

SELECT location,
	date,
	total_cases,
	total_deaths,
	round((total_deaths/total_cases::numeric)*100,2) as prct_death --have to typecast a int into numeric for decimal results then we round off by 2 decimal places
FROM covid_deaths
WHERE location ilike '%states%' --ilike is case insensitive
ORDER BY 1, 2; -- 1,2 same as location and date

--Information of Total Cases vs Population of the United States
	--Shows what percentage of the population has had COVID

SELECT location,
	date,
	total_cases,
	population,
	round((total_cases/population::numeric)*100,7) as prct_population_covid --changed decimal place to see early percentage of cases when COVID was first documented
FROM covid_deaths
WHERE location ilike '%states%' 
ORDER BY 1, 2;

-- Information of Countries with the Highest Infection Rate

SELECT location,
	population,
	MAX(total_cases) as highest_infection_count,
	MAX(round((total_cases/population::numeric)*100,7)) as prct_population_covid 
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY prct_population_covid DESC;

-- Information of Countries and their Total Death Count

SELECT location,
	MAX(total_deaths) as total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;

-- Information of Continents and their Total Death Count
SELECT continent,
	MAX(total_deaths) as total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;

-- Global Numbers
SELECT date, 
	MAX(total_cases) as total_global_cases, 
	MAX(total_deaths) as total_global_deaths, 
	round((MAX(total_deaths)::numeric/MAX(total_cases))*100,2) as pct_global_deaths
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

--CTE of New Vaccinations being added to a Total per Date
WITH population_vaccinations (continent, location, date, population, new_vaccinations, total_vaccinations_per_location)
as (

SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations,
	SUM(vacc.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) as total_vaccinations_per_location
FROM covid_deaths deaths
JOIN covid_vaccinations vacc
	on deaths.location = vacc.location 
	and deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL
)
SELECT *, round((total_vaccinations_per_location/population)*100,2) as prct_change_vaccinations
FROM population_vaccinations