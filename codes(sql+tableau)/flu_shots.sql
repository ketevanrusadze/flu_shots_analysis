CREATE TABLE conditions (
START DATE
,STOP DATE
,PATIENT VARCHAR(1000)
,ENCOUNTER VARCHAR(1000)
,CODE VARCHAR(1000)
,DESCRIPTION VARCHAR(200)
);

CREATE TABLE encounters (
 Id VARCHAR(100)
,START TIMESTAMP
,STOP TIMESTAMP
,PATIENT VARCHAR(100)
,ORGANIZATION VARCHAR(100)
,PROVIDER VARCHAR(100)
,PAYER VARCHAR(100)
,ENCOUNTERCLASS VARCHAR(100)
,CODE VARCHAR(100)
,DESCRIPTION VARCHAR(100)
,BASE_ENCOUNTER_COST FLOAT
,TOTAL_CLAIM_COST FLOAT
,PAYER_COVERAGE FLOAT
,REASONCODE VARCHAR(100)
--,REASONDESCRIPTION VARCHAR(100)
);

CREATE TABLE immunizations
(
 DATE TIMESTAMP
,PATIENT varchar(100)
,ENCOUNTER varchar(100)
,CODE int
,DESCRIPTION varchar(500)
--,BASE_COST float
);

CREATE TABLE patients
(
 Id VARCHAR(100)
,BIRTHDATE date
,DEATHDATE date
,SSN VARCHAR(100)
,DRIVERS VARCHAR(100)
,PASSPORT VARCHAR(100)
,PREFIX VARCHAR(100)
,FIRST VARCHAR(100)
,LAST VARCHAR(100)
,SUFFIX VARCHAR(100)
,MAIDEN VARCHAR(100)
,MARITAL VARCHAR(100)
,RACE VARCHAR(100)
,ETHNICITY VARCHAR(100)
,GENDER VARCHAR(100)
,BIRTHPLACE VARCHAR(100)
,ADDRESS VARCHAR(100)
,CITY VARCHAR(100)
,STATE VARCHAR(100)
,COUNTY VARCHAR(100)
,FIPS INT 
,ZIP INT
,LAT float
,LON float
,HEALTHCARE_EXPENSES float
,HEALTHCARE_COVERAGE float
,INCOME int
,Mrn int
);


-------------encounters 

--- 
select count(distinct i.patient),  extract(year from age(birthdate)) as ages, count(distinct i.patient) / sum(count(distinct i.patient)) over() * 100.0 as percentage
from patients p left join immunizations i
on p.id = i.patient  left join encounters e on e.patient = i.patient
where extract(year from (i.date)) = 2022 and e.start between '2022-01-01 00:00' and '2023-01-01 00:00' and i.code = 5302 and
EXTRACT(EPOCH FROM age('2022-12-31',p.birthdate)) >=6 and (deathdate is null or e.stop <= deathdate )
group by extract(year from age(birthdate))


---
--select sum(percentage) from(
select count(distinct i.patient), race, 1.0 * count(distinct i.patient) / sum(count(distinct i.patient)) over() * 100 as percentage
from immunizations i right join patients p on i.patient = p.id
left join encounters e on e.patient = i.patient
where extract(year from (i.date)) = 2022 and  e.start between '2022-01-01 00:00' and '2022-12-31 23:59' and i.code = 5302  and
EXTRACT(EPOCH FROM age('2022-12-31',p.birthdate)) >=6 and (deathdate is null or e.stop <= deathdate )
group by race
--)


---
--select sum(percentage) from(
select count(distinct i.patient),  county, 1.0 * count(distinct i.patient) / sum(count(distinct i.patient)) over() * 100 as percentage
from immunizations i right join patients p on i.patient = p.id
inner join encounters e on e.patient = i.patient
where extract(year from (i.date)) = 2022 and  e.start between '2022-01-01 00:00' and '2022-12-31 23:59' and i.code = 5302  and
EXTRACT(EPOCH FROM age('2022-12-31',p.birthdate)) >=6 and (deathdate is null or e.stop <= deathdate )
group by county
--)


---number of flu shots in 2022

select count(*) 
from immunizations i inner join  encounters e
on i.patient = e.patient inner join patients p on p.id  = i.patient
where date between '2022-01-01 00:00' and '2022-12-31 23:59' and e.start between '2022-01-01 00:00' and '2022-12-31 23:59' and i.code = 5302  and
EXTRACT(EPOCH FROM age('2022-12-31',p.birthdate)) >=6  and (deathdate is null or e.stop <= deathdate )


select sum(total_claim_cost) 
from encounters e inner join immunizations i on
e.patient = i.patient inner join conditions c on
c.patient = i.patient inner join patients p on p.id  = i.patient
where extract(year from (i.date)) = 2022 and  e.start between '2022-01-01 00:00' and '2022-12-31 23:59' and i.code = 5302  and
EXTRACT(EPOCH FROM age('2022-12-31',p.birthdate)) >=6  and (deathdate is null or e.stop <= deathdate )
--

select sum(base_encounter_cost + total_claim_cost - payer_coverage) 
from encounters e inner join immunizations i on
e.patient = i.patient inner join conditions c on
c.patient = i.patient inner join patients p on p.id  = i.patient
where extract(year from (i.date)) = 2022 and   e.start between '2022-01-01 00:00' and '2022-12-31 23:59' and i.code = 5302  and
EXTRACT(EPOCH FROM age('2022-12-31',p.birthdate)) >=6  and (deathdate is null or e.stop <= deathdate )


------------
create or replace view view_flu_shots as (
select distinct p.id, p.first, p.last, true as tookshoot ,  p.birthdate, p.race, p.county, p.gender
from patients p left join immunizations i 
on p.id = i.patient inner join encounters e on e.patient = i.patient
where extract(year from (i.date)) = 2022 and   e.start between '2020-01-01 00:00' and '2022-12-31 23:59' and i.code = 5302  and
EXTRACT(EPOCH FROM age('2022-12-31',p.birthdate)) >=6  and (deathdate is null or e.stop <= deathdate )
)

create or replace view view_none_flu_shots as (
select distinct p.id, p.first, p.last,  false as tookshoot,   p.birthdate, p.race, p.county, p.gender from 
patients p left join immunizations i on p.id = i.patient 
left join encounters e on p.id = e.patient
where p.id not in (select id from view_flu_shots) and date between '2022-01-01 00:00' and '2022-12-31 23:59'
and (deathdate is null or e.stop <= deathdate )
)


select * from view_flu_shots
union all
select * from view_none_flu_shots
-----


with active_patients as
(
	select distinct patient
	from encounters as e
	join patients as pat
	  on e.patient = pat.id
	where start between '2022-01-01 00:00' and '2022-12-31 23:59'
	  and (pat.deathdate is null  or e.stop <= deathdate)
	  and EXTRACT(EPOCH FROM age('2022-12-31',pat.birthdate)) >= 6
/* Might want to use this line below instead, as  the above isn't correct. However, once you do, your results will look a little different than the tutorial */    
/* EXTRACT(EPOCH FROM age('2022-12-31',pat.birthdate)) / 2592000  */
),

flu_shot_2022 as
(
select  distinct patient, min(date) as earliest_flu_shot_2022 
from immunizations
where code = '5302'
  and date between '2022-01-01 00:00' and '2022-12-31 23:59'
group by patient
)

select pat.birthdate
      ,pat.race
	  ,pat.county
	  , pat.id
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

















---by_month
select amount, monthss from  (
select amount, months, CASE 
           WHEN months = 1 THEN 'january'
           WHEN months = 2 THEN 'february'
           WHEN months = 3 THEN 'march'
           WHEN months = 4 THEN 'april'
           WHEN months = 5 THEN 'may'
           WHEN months = 6 THEN 'june'
           WHEN months = 7 THEN 'july'
           WHEN months = 8 THEN 'august'
           WHEN months = 9 THEN 'september'
           WHEN months = 10 THEN 'october'
           WHEN months = 11 THEN 'november'
           WHEN months = 12 THEN 'december'
       END AS monthss from (
select count(distinct i.patient) as amount, extract(month from (date)) as months
from immunizations i inner join patients p on i.patient = p.id
left join encounters e on e.patient = i.patient
where extract(year from (i.date)) = 2022 and  e.start between '2022-01-01 00:00' and '2022-12-31 23:59' and i.code = 5302  and
EXTRACT(EPOCH FROM age('2022-12-31',p.birthdate)) >=6 and (deathdate is null or e.stop <= deathdate )
group by months)
group by amount, months
order by months asc)


-------growth_RAte



with cte as (
select amount, months, CASE 
           WHEN months = 1 THEN 'january'
           WHEN months = 2 THEN 'february'
           WHEN months = 3 THEN 'march'
           WHEN months = 4 THEN 'april'
           WHEN months = 5 THEN 'may'
           WHEN months = 6 THEN 'june'
           WHEN months = 7 THEN 'july'
           WHEN months = 8 THEN 'august'
           WHEN months = 9 THEN 'september'
           WHEN months = 10 THEN 'october'
           WHEN months = 11 THEN 'november'
           WHEN months = 12 THEN 'december'
       END AS monthss from (
select count(distinct i.patient) as amount, extract(month from (date)) as months
from immunizations i inner join patients p on i.patient = p.id
left join encounters e on e.patient = i.patient
where extract(year from (i.date)) = 2022 and  e.start between '2022-01-01 00:00' and '2022-12-31 23:59' and i.code = 5302  and
EXTRACT(EPOCH FROM age('2022-12-31',p.birthdate)) >=6 and (deathdate is null or e.stop <= deathdate )
group by months)
group by amount, months
order by months asc
)

select ct.amount, ct.months, ct.monthss,
1.0 * (ct.amount - (select cte.amount from cte where cte.months = ct.months -1) )/ (select cte.amount from cte where cte.months = ct.months -1) * 100 as grwoth_rate
from cte ct


select count(distinct i.patient), income,  1.0 * count(distinct i.patient) / sum(count(distinct i.patient)) over() * 100 as percentage
from immunizations i inner join patients p on i.patient = p.id
left join encounters e on e.patient = i.patient
where extract(year from (i.date)) = 2022 and  e.start between '2022-01-01 00:00' and '2022-12-31 23:59' and i.code = 5302  and
EXTRACT(EPOCH FROM age('2022-12-31',p.birthdate)) >=6 and (deathdate is null or e.stop <= deathdate )
group by income

select max(income) from patients




with regression as (
select vaccinated_count, month_num, CASE 
           WHEN month_num = 1 THEN 'january'
           WHEN month_num = 2 THEN 'february'
           WHEN month_num = 3 THEN 'march'
           WHEN month_num = 4 THEN 'april'
           WHEN month_num = 5 THEN 'may'
           WHEN month_num = 6 THEN 'june'
           WHEN month_num = 7 THEN 'july'
           WHEN month_num = 8 THEN 'august'
           WHEN month_num = 9 THEN 'september'
           WHEN month_num = 10 THEN 'october'
           WHEN month_num = 11 THEN 'november'
           WHEN month_num = 12 THEN 'december'
       END AS monthss from (
select count(distinct i.patient) as  vaccinated_count, extract(month from (date)) as month_num
from immunizations i inner join patients p on i.patient = p.id
left join encounters e on e.patient = i.patient
where extract(year from (i.date)) = 2022 and  e.start between '2022-01-01 00:00' and '2022-12-31 23:59' and i.code = 5302  and
EXTRACT(EPOCH FROM age('2022-12-31',p.birthdate)) >=6 and (deathdate is null or e.stop <= deathdate )
group by month_num)
group by vaccinated_count, month_num
order by month_num asc
)
SELECT 
    -- Get the Intercept (b)
    regr_intercept(vaccinated_count, month_num) + 
    -- Get the Slope (m) * the next month (current month + 1)
    regr_slope(vaccinated_count, month_num) * (MAX(month_num) + 1) AS next_month_forecast, '2023-01-01' as month_of
FROM regression;



select count(distinct i.patient), extract(month from (date)) as months 
from  immunizations i inner join patients p on i.patient = p.id
left join encounters e on e.patient = i.patient
where extract(year from (i.date)) = 2023 and i.code = 5302  and
EXTRACT(EPOCH FROM age('2023-01-01',p.birthdate)) >=6 and (deathdate is null or e.stop <= deathdate )
and extract(month from (date))= 1
group by months