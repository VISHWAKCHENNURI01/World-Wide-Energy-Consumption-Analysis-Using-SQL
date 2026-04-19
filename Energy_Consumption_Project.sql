CREATE DATABASE ENERGYDB2;
USE ENERGYDB2;

-- 1. country table
CREATE TABLE country (
    CID VARCHAR(10) PRIMARY KEY,
    Country VARCHAR(100) UNIQUE
);

SELECT * FROM COUNTRY;

-- 2. emission_3 table
CREATE TABLE emission_3 (
    country VARCHAR(100),
    energy_type VARCHAR(50),
    year INT,
    emission INT,
    per_capita_emission DOUBLE,
    FOREIGN KEY (country) REFERENCES country(Country)
);

SELECT * FROM EMISSION_3;


-- 3. population table
CREATE TABLE population (
    countries VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (countries) REFERENCES country(Country)
);

SELECT * FROM POPULATION;

-- 4. production table
CREATE TABLE production (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    production INT,
    FOREIGN KEY (country) REFERENCES country(Country)
);


SELECT * FROM PRODUCTION;

-- 5. gdp_3 table
CREATE TABLE gdp_3 (
    Country VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (Country) REFERENCES country(Country)
);

SELECT * FROM GDP_3;

-- 6. consumption table
CREATE TABLE consumption (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    consumption INT,
    FOREIGN KEY (country) REFERENCES country(Country)
);

SELECT * FROM CONSUMPTION;

-- What is the total emission per country for the most recent year available?
select country, SUM(emission) as total_emission
from emission_3
where year = 2023
group by country
order by total_emission desc;

-- What are the top 5 countries by GDP in the most recent year?
select * from gdp_3
where year = 2024
order by value desc
limit 5;

-- Compare energy production and consumption by country and year. 
select c.country, c.year,  c.consumption, p.production
from consumption c
inner join production p
ON c.country = p.country AND c.year = p.year
order by c.consumption desc;

-- Which energy types contribute most to emissions across all countries?
select energy_type, SUM(emission) AS total_emissions
from  emission_3
group by energy_type
order by total_emissions desc;
    
-- Trend Analysis Over Time
-- How have global emissions changed year over year?
select year, SUM(emission) AS total_emissions
from emission_3
group by year
order by year;

-- What is the trend in GDP for each country over the given years?
select country, year, value as  gdp
from gdp_3
order by country, year;
    
-- How has population growth affected total emissions in each country?
select e.country, e.year,sum(e.emission) as total_emission, p.value as population
from emission_3 e
join population p 
on e.country = p.countries
and e.year = p.year
group by e.country, e.year, p.value
order by e.country, e.year;

-- Has energy consumption increased or decreased over the years for major economies?
select country, year, sum(consumption) as total_consumption
from consumption
group by country, year
order by country, year;
   
-- What is the average yearly change in emissions per capita for each country?
select country, year, per_capita_emission, lag(per_capita_emission) over
	(partition by country order by year) as prev_value,
    per_capita_emission - lag(per_capita_emission) over
    (partition by country order by year) as diff
from emission_3;
    
-- Ratio & Per Capita Analysis
-- What is the emission-to-GDP ratio for each country by year?
select e.country, e.year, SUM(e.emission) / g.value as emission_gdp_ratio
from  emission_3 e
join gdp_3 g
on e.country = g.country 
and e.year = g.year
group by e.country, e.year, g.value
order by e.country, year;
    
-- What is the energy consumption per capita for each country over the last decade?
select c.country, c.year, SUM(c.consumption) / p.value as consumption_per_capita
from consumption c
join population p
on c.country = p.countries
and c.year = p.year
group by c.country, c.year, p.value;
    
-- How does energy production per capita vary across countries?
select prod.country, prod.year, SUM(prod.production) / max(p.value) as production_per_capita
from production prod
join population p
on prod.country = p.countries
and prod.year = p.year
group by prod.country, prod.year
order by prod.country, prod.year;
    
-- Which countries have the highest energy consumption relative to GDP?
select c.country, SUM(c.consumption) / max(g.value) as consumption_gdp_ratio
from consumption c
join gdp_3 g
on c.country = g.country 
and c.year = g.year
where c.year = (select max(year) from consumption)
group by c.country
order by consumption_gdp_ratio desc
limit 10;
    
-- What is the correlation between GDP growth and energy production growth?
with production_agg as (
	select country,
			year,
			sum(production) AS total_production
	from production 
    group by country, year
),
growth_data as (
		select g.country,
			   g.year,
               g.value - LAG(g.value) OVER (
					partition by g.country order by g.year
				) as gdp_growth
                p.total_production - LAG(p.total_production) OVER (
					partition by p.country order by p.year
				) as prod_growth
        
        FROM gdp_3 g
		join production_agg p
		on g.country = p.country 
        and g.year = p.year
),
latest_year AS (
  SELECT MAX(year) AS yr FROM population
)
SELECT p.country AS country,
       MAX(p.value) AS population,
       SUM(e.emission) AS total_emissions
FROM population p
JOIN emission_3 e
  ON p.country = e.country
GROUP BY p.country
ORDER BY population DESC
LIMIT 10;
    
-- Global Comparisons
-- What are the top 10 countries by population and how do their emissions compare?
with latest_year as (
	select max(year) as yr from population
)
select p.countries as country,
	MAX(p.value) as population,
    SUM(e.emission) AS total_emissions
from population p
join emission_3 e
on p.countries = e.country
group by p.countries
order by population desc
limit 10;

-- Which countries have improved (reduced) their per capita emissions the most over the last decade?
select country,
	   MAX(CASE WHEN year = (SELECT MIN(year) from emission_3)
				THEN per_captia_emission END)
	   - 
	   MAX(CASE WHEN year = (SELECT MAX(year) from emission_3)
				THEN per_captia_emission END) as reduction
from emission_3
group by country
order by reduction desc
limit 10;

-- What is the global share (%) of emissions by country?
select country, SUM(emission) * 100.0 / 
				(SELECT SUM(emission) FROM emission_3) as emission_share_percent
from emission_3
group by country
order by emission_share_percent desc;
    
-- What is the global average GDP, emission, and population by year?
select e.year,
	   AVG(e.emission) AS avg_emission,
	   AVG(g.value) AS avg_gdp,
       AVG(p.value) as avg_population
from emission_3 e
join gdp_3 g
on e.country = g.country AND e.year = g.year
join population p
on e.country = p.countries AND e.year = p.year
group by e.year
order by e.year;





