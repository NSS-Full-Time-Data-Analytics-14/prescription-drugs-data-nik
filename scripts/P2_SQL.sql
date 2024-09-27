-- There is a duplication in the drugs table! --

SELECT COUNT(drug_name) FROM drug;                     -- 3425 --

SELECT COUNT (DISTINCT drug_name) FROM drug;           -- 3253 --

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT * FROM prescriber;

SELECT * FROM prescription;

SELECT * FROM drug;

SELECT * FROM zip_fips;

SELECT * FROM population;

SELECT * FROM cbsa;

SELECT * FROM fips_county;

SELECT * FROM overdose_deaths;
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.                                                                                        -- npi: 1881634483 --
                                                                                                                                                                                                                               -- total_claims: 99707 --                     
SELECT 
	prescriber.npi, 
	SUM(prescription.total_claim_count) AS buncha_claims
FROM prescriber
INNER JOIN prescription USING(npi)
GROUP BY prescriber.npi, prescriber.nppes_provider_first_name
ORDER BY buncha_claims DESC
LIMIT 1;



-- 1b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.

SELECT 
	CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name) AS doctors, 
	specialty_description,
	SUM(prescription.total_claim_count) AS buncha_claims
FROM prescriber
INNER JOIN prescription USING(npi)
GROUP BY prescriber.nppes_provider_first_name, prescriber.nppes_provider_last_org_name, prescriber.specialty_description
ORDER BY buncha_claims DESC;


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2a. Which specialty had the most total number of claims (totaled over all drugs)?                                                                                                                                        -- Family Practice --
SELECT  
	specialty_description,
	SUM(total_claim_count) AS total_num_claims
FROM prescriber 
INNER JOIN prescription ON prescriber.npi = prescription.npi
GROUP BY specialty_description
ORDER BY total_num_claims DESC
LIMIT 1;



-- 2b. Which specialty had the most total number of claims for opioids?                                                                                                                                                     -- Nurse Practitioner --    
SELECT  
	specialty_description,
	SUM(total_claim_count) AS total_num_claims
FROM prescriber 
INNER JOIN prescription ON prescriber.npi = prescription.npi
INNER JOIN drug ON prescription.drug_name = drug.drug_name
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY total_num_claims DESC
LIMIT 1;



-- 2c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT 
	specialty_description
FROM prescriber
LEFT JOIN prescription USING(npi)
GROUP BY specialty_description
HAVING SUM(total_claim_count) IS NULL;



-- 2d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!*

--                           For each specialty, report the percentage of total claims by that specialty which are for opioids. 
--                           Which specialties have a high percentage of opioids?                                                                                                                                          -- Case Manager/Care Coordinator, Orthopedic Surgery, Interventional Pain Management --
SELECT 
	specialty_description,
	ROUND((SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count END) / SUM(total_claim_count)) * 100, 2) AS total_opioids
FROM prescriber
INNER JOIN prescription USING(npi)
INNER JOIN drug USING (drug_name)
GROUP BY specialty_description
ORDER BY total_opioids DESC NULLS LAST;







-- Hmmm..... David Ruiz's CARPETBOMB Query --                                                                                          -- will compair and explore soon --

WITH sum_opioid AS    (SELECT
                        specialty_description,
                        SUM(total_claim_count) AS sum_opioid_claim_count
                    FROM prescriber
                    INNER JOIN prescription USING(npi)
                    INNER JOIN drug USING(drug_name)
                    WHERE opioid_drug_flag = 'Y'
                    GROUP BY specialty_description),
sum_total AS        (SELECT
                        specialty_description,
                        SUM(total_claim_count) AS sum_total_claim_count
                    FROM prescriber
                    INNER JOIN prescription USING(npi)
                    GROUP BY specialty_description)
SELECT
    specialty_description,
    ROUND((100 * sum_opioid_claim_count / sum_total_claim_count),2) as percent_opioids
FROM sum_opioid
INNER JOIN sum_total USING(specialty_description)
GROUP BY specialty_description, percent_opioids
ORDER BY percent_opioids DESC;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------  
-- 3a. Which drug (generic_name) had the highest total drug cost?                                                                                                                                                           -- Pirfenidone --            
SELECT
	generic_name
FROM drug
INNER JOIN prescription USING(drug_name)
WHERE total_drug_cost = (SELECT MAX(total_drug_cost) FROM prescription)
ORDER BY generic_name DESC;



-- 3b. Which drug (generic_name) has the hightest total cost per day?       																																			       -- Pirfenidone @ $7751 -- 				                         																												
SELECT
	generic_name,
	ROUND(total_drug_cost / 365) AS cost_per_day
FROM drug
INNER JOIN prescription USING(drug_name)
ORDER BY cost_per_day DESC
LIMIT 1;



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' 
--     for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. 
SELECT
	DISTINCT drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
FROM drug;



-- 4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. 
--     Hint: Format the total costs as MONEY for easier comparision.
WITH drug_cost AS (SELECT 
						DISTINCT drug.drug_name AS drug_name,
						SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_drug_cost ELSE 0 END)::numeric::money AS opioid_cost,
						SUM(CASE WHEN antibiotic_drug_flag = 'Y' THEN total_drug_cost ELSE 0 END)::numeric::money AS antibiotic_cost
					FROM prescription
					INNER JOIN drug USING(drug_name)
					GROUP BY drug.drug_name)

SELECT
	SUM(opioid_cost) AS opioid_total_cost,
	SUM(antibiotic_cost) AS antibiotic_total_cost
FROM drug_cost;


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 5a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.																						              -- 38 --
SELECT 
	COUNT(cbsa)
FROM cbsa
WHERE cbsaname ILIKE '%TN';


	
-- 5b. Which cbsa has the largest combined population? 
--     Which has the smallest? Report the CBSA name and total population.   
(SELECT 
	DISTINCT cbsa.cbsaname,
	SUM(population) AS pop
FROM cbsa
INNER JOIN population ON cbsa.fipscounty = population.fipscounty
GROUP BY DISTINCT cbsa.cbsaname
ORDER BY pop DESC
LIMIT 1)
UNION
(SELECT 
	DISTINCT cbsa.cbsaname,
	SUM(population) AS pop
FROM cbsa
INNER JOIN population ON cbsa.fipscounty = population.fipscounty
GROUP BY DISTINCT cbsa.cbsaname
ORDER BY pop ASC
LIMIT 1);



-- 5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.   																					           -- Shelby County (population: 937847) --
SELECT
	county,
	MAX(population) AS big_poppa
FROM fips_county
INNER JOIN population USING(fipscounty)
WHERE fipscounty NOT IN (SELECT fipscounty FROM cbsa)
GROUP BY county
ORDER BY big_poppa DESC;



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT 
	drug_name,
	total_claim_count
FROM prescription
INNER JOIN drug USING(drug_name)
WHERE total_claim_count >= 3000;


	
-- 6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
WITH at_3k AS (SELECT 
					drug_name,
					total_claim_count,
					opioid_drug_flag,
					antibiotic_drug_flag
				FROM prescription
				INNER JOIN drug USING(drug_name)
				WHERE total_claim_count >= 3000)

SELECT 
	drug_name,
	total_claim_count,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	ELSE 'other' END AS drug_category
FROM at_3k;



-- 6c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
WITH at_3k AS (SELECT 
					drug_name,
					total_claim_count,
					opioid_drug_flag,
					antibiotic_drug_flag,
					nppes_provider_first_name,
					nppes_provider_last_org_name
				FROM prescription
				INNER JOIN drug USING(drug_name)
				INNER JOIN prescriber USING(npi)
				WHERE total_claim_count >= 3000)

SELECT 
	CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name) AS doctor_names,
	drug_name,
	total_claim_count,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	ELSE 'other' END AS drug_category
FROM at_3k;



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. 
--    **Hint:** The results from all 3 parts will have 637 rows.

-- 7a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). 
--     **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT 
	npi,
	drug_name
FROM prescriber CROSS JOIN drug 
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
ORDER BY npi ASC;



-- 7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. 
--     You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT 
	pt1.npi,
	d.drug_name,
	SUM(total_claim_count) AS total_claim_count
FROM prescriber pt1
CROSS JOIN drug d
LEFT JOIN prescription pt3 USING(drug_name)
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
GROUP BY pt1.npi, d.drug_name
ORDER BY pt1.npi ASC;




	
-- 7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT 
	CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name),
	prescriber.npi,
	drug_name,
	COALESCE(SUM(total_claim_count),0) AS total_claim_count
FROM prescriber
CROSS JOIN drug 
LEFT JOIN prescription USING(drug_name)
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, drug_name, nppes_provider_first_name, nppes_provider_last_org_name
ORDER BY npi ASC;


