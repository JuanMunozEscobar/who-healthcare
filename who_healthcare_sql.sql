-- CREATE TABLE FOR RAW DATA
set global local_infile = 1;
use who_healthcare;


DROP TABLE IF EXISTS health_indicators;
CREATE TABLE health_indicators (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    ind_id                  VARCHAR(50),
    ind_code                VARCHAR(50),
    ind_uuid                VARCHAR(100),
    ind_per_code            VARCHAR(50),
    year                    INT,
    geo_code_m49            VARCHAR(10),
    geo_code_type           VARCHAR(50),
    publish_state_code      VARCHAR(20),
    indicator_name          VARCHAR(255),
    location_name           VARCHAR(100),
    sex                     VARCHAR(20),
    age_group               VARCHAR(50),
    rate_estimate           FLOAT,
    lower_bound             FLOAT,
    upper_bound             FLOAT
);

DROP TABLE IF EXISTS mortality_rates;
CREATE TABLE mortality_rates (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    year                    INT,
    indicator_name          VARCHAR(255),
    cause_of_death			VARCHAR(225),
    location_name           VARCHAR(100),
    sex                     VARCHAR(20),
    measure_type			VARCHAR(50),
    rate_estimate           FLOAT
);


-- CREATE NEW TABLE FOR CLEANING

DROP TABLE IF EXISTS health_indicators_cleaning;
CREATE TABLE health_indicators_cleaning (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    ind_id                  VARCHAR(50),
    ind_code                VARCHAR(50),
    ind_uuid                VARCHAR(100),
    ind_per_code            VARCHAR(50),
    year                    INT,
    geo_code_m49            VARCHAR(10),
    geo_code_type           VARCHAR(50),
    publish_state_code      VARCHAR(20),
    indicator_name          VARCHAR(255),
    location_name           VARCHAR(100),
    sex                     VARCHAR(20),
    age_group               VARCHAR(50),
    rate_estimate           FLOAT,
    lower_bound             FLOAT,
    upper_bound             FLOAT
);

DROP TABLE IF EXISTS mortality_rates_cleaning;
CREATE TABLE mortality_rates_cleaning (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    year                    INT,
    indicator_name          VARCHAR(255),
    cause_of_death			VARCHAR(225),
    location_name           VARCHAR(100),
    sex                     VARCHAR(20),
    measure_type			VARCHAR(50),
    rate_estimate           FLOAT
);


insert into health_indicators_cleaning
select * from health_indicators;

insert into mortality_rates_cleaning
select * from mortality_rates;

-- CLEANING THE DATA
SET SQL_SAFE_UPDATES = 0;
-- CHECK FOR AND DEAL WITH DUPLICATES

delete h 
from health_indicators_cleaning h
join (
    select id, row_number() over(
        partition by indicator_name, rate_estimate, ind_id, ind_uuid, lower_bound, upper_bound, year, sex
        order by id
    ) as row_num
    from health_indicators_cleaning
) dupe on h.id = dupe.id
where dupe.row_num > 1;

delete h 
from mortality_rates_cleaning h
join (
    select id, row_number() over(
        partition by cause_of_death, rate_estimate, sex, year
        order by id
    ) as row_num
    from mortality_rates_cleaning
) dupe on h.id = dupe.id
where dupe.row_num > 1;


-- CREATE AGE GROUPS

update health_indicators_cleaning
set age_group = case 
	when age_group = 'Y_GE18' then 'Adult'
    when age_group = 'Y10T19' then 'Adolescent'
    when age_group = 'Y5T9' then 'Kid'
end
where age_group in ('Y_GE18', 'Y10T19', 'Y5T9');

-- DEAL WITH NULL VALUES

update health_indicators_cleaning
set age_group = 'Adult'
where indicator_name like 'Alcohol%';

update health_indicators_cleaning
set age_group = 'Adult'
where indicator_name like 'Hypertension%';

update health_indicators_cleaning
set age_group = 'Adult'
where indicator_name like 'Tobacco%';

-- STANDARDIZE NAMES

update health_indicators_cleaning
set location_name = 'USA'
where location_name = 'United States of America';

update health_indicators_cleaning
set indicator_name = 'Obesity'
where indicator_name like 'Obesity%';

update health_indicators_cleaning
set indicator_name = 'Alcohol consumption'
where indicator_name like 'Alcohol%';

update health_indicators_cleaning
set indicator_name = 'Hypertension'
where indicator_name like 'Hypertension%';
 
-- STANDARDIZE GENDERS

update mortality_rates_cleaning
set sex = 'MALE'
where sex like 'MLE%';

update mortality_rates_cleaning
set sex = 'BOTH'
where sex like 'BTSX%';

update mortality_rates_cleaning
set sex = 'FEMALE'
where sex like 'FMLE%';


-- CHANGE NUMBERS TYPE

alter table health_indicators_cleaning
modify column rate_estimate decimal(10, 2);

alter table health_indicators_cleaning
modify column lower_bound decimal(10, 2);

alter table health_indicators_cleaning
modify column upper_bound decimal(10, 2);


alter table mortality_rates_cleaning
modify column rate_estimate decimal(10, 2);




-- DROP POINTLESS COLUMNS/ROWS

alter table mortality_rates_cleaning
drop column indicator_name;

alter table health_indicators_cleaning
drop column geo_code_type;

alter table health_indicators_cleaning
drop column geo_code_m49;

alter table health_indicators_cleaning
drop column publish_state_code;

delete
from health_indicators_cleaning
where age_group = 'Y5T19';

alter table health_indicators_cleaning
drop column sex;


delete
from health_indicators_cleaning
where indicator_name like '%expectancy%';


-- POTENTIAL JOIN BY YEAR TO SEE HIGHEST CAUSE OF DEATH AND USA HEALTH STATS

create or replace view usa_2021_health_vs_mortality as
select health_indicators_cleaning.year, health_indicators_cleaning.location_name,
health_indicators_cleaning.indicator_name as health_condition,
health_indicators_cleaning.rate_estimate as condition_rate_pct,
mortality_rates_cleaning.cause_of_death, 
mortality_rates_cleaning.rate_estimate as overall_mortality_rate
from health_indicators_cleaning
inner join mortality_rates_cleaning
	on health_indicators_cleaning.year = mortality_rates_cleaning.year
where health_indicators_cleaning.location_name = 'USA'
	and mortality_rates_cleaning.sex = 'BOTH'
order by mortality_rates_cleaning.rate_estimate desc;











