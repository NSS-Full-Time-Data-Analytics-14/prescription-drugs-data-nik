--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?
SELECT 
	COUNT(prescriber.npi) AS npi_count
FROM prescriber
LEFT JOIN prescription ON prescriber.npi = prescription.npi
WHERE prescription.npi IS NULL;



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
SELECT generic_name
FROM drug
INNER JOIN prescription USING(drug_name)
INNER JOIN prescriber USING(npi)
WHERE prescriber.specialty_description = 'Family Practice'
LIMIT 5;



-- 2b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
SELECT generic_name
FROM drug
INNER JOIN prescription USING(drug_name)
INNER JOIN prescriber USING(npi)
WHERE prescriber.specialty_description = 'Cardiology'
LIMIT 5;



-- 2c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? 
--     Combine what you did for parts a and b into a single query to answer this question.
(SELECT generic_name
FROM drug
INNER JOIN prescription USING(drug_name)
INNER JOIN prescriber USING(npi)
WHERE prescriber.specialty_description ='Family Practice')
UNION
(SELECT generic_name
FROM drug
INNER JOIN prescription USING(drug_name)
INNER JOIN prescriber USING(npi)
WHERE prescriber.specialty_description = 'Cardiology')
LIMIT 5;



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
-- 3a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. 
--     Report the npi, the total number of claims, and include a column showing the city.
SELECT 
	CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name),
	npi,
	total_claim_count,
	nppes_provider_city
FROM prescriber
INNER JOIN prescription USING(npi)	
WHERE nppes_provider_city = 'NASHVILLE'
ORDER BY total_claim_count DESC
LIMIT 5;



-- 3b. Now, report the same for Memphis.
SELECT 
	CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name),
	npi,
	total_claim_count,
	nppes_provider_city
FROM prescriber
INNER JOIN prescription USING(npi)	
WHERE nppes_provider_city =
ORDER BY total_claim_count DESC
LIMIT 5;




-- 3c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
(SELECT 
	CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name),
	npi,
	total_claim_count,
	nppes_provider_city
FROM prescriber
INNER JOIN prescription USING(npi)	
WHERE nppes_provider_city = 'NASHVILLE'
ORDER BY total_claim_count DESC
LIMIT 5)
UNION
(SELECT 
	CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name),
	npi,
	total_claim_count,
	nppes_provider_city
FROM prescriber
INNER JOIN prescription USING(npi)	
WHERE nppes_provider_city = 'MEMPHIS'
ORDER BY total_claim_count DESC
LIMIT 5)
UNION
(SELECT 
	CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name),
	npi,
	total_claim_count,
	nppes_provider_city
FROM prescriber
INNER JOIN prescription USING(npi)	
WHERE nppes_provider_city = 'KNOXVILLE'
ORDER BY total_claim_count DESC
LIMIT 5)
UNION
(SELECT 
	CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name),
	npi,
	total_claim_count,
	nppes_provider_city
FROM prescriber
INNER JOIN prescription USING(npi)	
WHERE nppes_provider_city = 'CHATTANOOGA'
ORDER BY total_claim_count DESC
LIMIT 5);



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


WITH NASHVILLE AS (SELECT 
						CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name),
						npi,
						total_claim_count,
						nppes_provider_city
					FROM prescriber
					INNER JOIN prescription USING(npi)	
					WHERE nppes_provider_city = 'NASHVILLE'
					ORDER BY total_claim_count DESC
					LIMIT 5),
	MEMPHIS AS (SELECT 
						CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name),
						npi,
						total_claim_count,
						nppes_provider_city
					FROM prescriber
					INNER JOIN prescription USING(npi)	
					WHERE nppes_provider_city = 'MEMPHIS'
					ORDER BY total_claim_count DESC
					LIMIT 5),
	KNOXVILLE AS (SELECT 
						CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name),
						npi,
						total_claim_count,
						nppes_provider_city
					FROM prescriber
					INNER JOIN prescription USING(npi)	
					WHERE nppes_provider_city = 'KNOXVILLE'
					ORDER BY total_claim_count DESC
					LIMIT 5),
	CHATTANOOGA AS (SELECT 
						CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name),
						npi,
						total_claim_count,
						nppes_provider_city
					FROM prescriber
					INNER JOIN prescription USING(npi)	
					WHERE nppes_provider_city = 'CHATTANOOGA'
					ORDER BY total_claim_count DESC
					LIMIT 5)

SELECT *
FROM NASHVILLE
UNION ALL
SELECT *
FROM MEMPHIS
UNION ALL
SELECT *
FROM KNOXVILLE
UNION ALL
SELECT *
FROM CHATTANOOGA;



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 4. Find all counties which had an above-average number of overdose deaths.
--    Report the county name and number of overdose deaths.
SELECT 
	DISTINCT county,
	overdose_deaths
FROM fips_county
INNER JOIN overdose_deaths ON fips_county.fipscounty::integer = overdose_deaths.fipscounty::integer
WHERE overdose_deaths >= (SELECT AVG(overdose_deaths) FROM overdose_deaths)
ORDER BY overdose_deaths DESC;


	
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 5a. Write a query that finds the total population of Tennessee.
SELECT 
	SUM(population) AS TN_population
FROM population
INNER JOIN fips_county USING(fipscounty)
WHERE state = 'TN';



-- 5b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, 
--     its population, and the percentage of the total population of Tennessee that is contained in that county.



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------