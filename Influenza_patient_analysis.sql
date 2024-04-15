-- 1. Patient Demographics Analysis: 
-- How many patients are in each age group 
SELECT
CASE
	WHEN EXTRACT(YEAR FROM AGE('2022-12-31', p.birthdate)) <= 18 THEN '0-18'
	WHEN EXTRACT(YEAR FROM AGE('2022-12-31', p.birthdate)) BETWEEN 19 and 35 THEN '19-35'
	WHEN EXTRACT(YEAR FROM AGE('2022-12-31', p.birthdate)) BETWEEN 36 and 60 THEN '36-60'
	ELSE '60+'
END AS AgeGroup,
COUNT(*) AS GroupCount
FROM patients as p
GROUP BY AgeGroup


-- 2. Geographical Distribution:
-- What are the top 5 cities with the highest number of patients?
SELECT p.city, COUNT(p.id)
FROM patients as p
GROUP BY p.city
ORDER BY COUNT(p.id) DESC
LIMIT 5


3.
-- 3. Healthcare Utilization Patterns:
-- How many encounters does each patient have on average?
-- According to my understanding, the above question has 2 meaning beacause it is incomplete.
-- 3.1
SELECT patient, COUNT(*) AS encounter_count
FROM conditions
GROUP BY patient;

-- 3.2
SELECT 
    AVG(encounter_count) AS AverageEncounters
FROM (
    SELECT 
        patient, 
        COUNT(*) AS encounter_count
    FROM 
        encounters
    GROUP BY 
        patient
);

--How many patients received a flu shot in the year 2022, broken down by age, race, and county?
SELECT  
	p.race, 
	p.county,
    CASE 
        WHEN EXTRACT(YEAR FROM AGE('2022-12-31', p.BIRTHDATE)) < 18 THEN '0-17'
        WHEN EXTRACT(YEAR FROM AGE('2022-12-31', p.BIRTHDATE)) BETWEEN 18 AND 35 THEN '18-35'
        WHEN EXTRACT(YEAR FROM AGE('2022-12-31', p.BIRTHDATE)) BETWEEN 36 AND 59 THEN '36-59'
        ELSE '60+'
     END AS AgeGroup,
	 COUNT (*) AS GroupCount
FROM patients as p
JOIN immunizations as i ON p.id = i.patient
WHERE EXTRACT(YEAR FROM i.date) = 2022
	AND i.code = 5302
GROUP BY p.race, p.county, AgeGroup, i.description


--What is the percentage of patients who received a flu shot in 2022 compared to the total number
--of patients, stratified by age, race, and county?


SELECT
	(SELECT COUNT(i.patient) --specific
	FROM immunizations as i
	WHERE i.code =5302
		AND EXTRACT(YEAR FROM i.date) = 2022) * 100 /
	(SELECT COUNT(i.patient) --total
	FROM immunizations as i) AS percentage_of_vaccinated

--flue shots given in 2022
SELECT COUNT(patient)
FROM immunizations as i
WHERE i.code = 5302
	AND EXTRACT(YEAR FROM i.date) = 2022



/*
Objectives
Come up with flu shots dashboard for 2022 that does the following

1.) Total % of patients getting flu shots stratified by
   a.) Age
   b.) Race
   c.) County (On a Map)
   d.) Overall
2.) Running Total of Flu Shots over the course of 2022
3.) Total number of Flu shots given in 2022
4.) A list of Patients that show whether or not they received the flu shots
   
Requirements:

Patients must have been "Active at our hospital"
*/

select * from immunizations

with active_patients as
(
	select distinct patient
	from encounters as e
	join patients as pat
	  on e.patient = pat.id
	where start between '2020-01-01 00:00' and '2022-12-31 23:59'
	  and pat.deathdate is null
	  and extract(month from age('2022-12-31',pat.birthdate)) >= 6
	  ),
flu_shot_2022 as
(
select patient, min(date) as earliest_flu_shot_2022 
from immunizations
where code = '5302'
  and date between '2022-01-01 00:00' and '2022-12-31 23:59'
group by patient
)

select pat.birthdate
      ,pat.race
	  ,pat.county
	  ,pat.id
	  ,pat.first
	  ,pat.last
	  ,pat.gender
	  ,extract(YEAR FROM age('12-31-2022', birthdate)) as age
	  ,flu.earliest_flu_shot_2022
	  ,flu.patient
	  ,case when flu.patient is not null then 1 
	   else 0
	   end as flu_shot_2022
from patients as pat
left join flu_shot_2022 as flu
  on pat.id = flu.patient
where 1=1
  and pat.id in (select patient from active_patients)
