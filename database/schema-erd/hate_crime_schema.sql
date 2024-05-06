-- Project: US Hate Crimes

-- This SQL file includes:
-- 1. SQL code to create database tables
-- 2. SQL code to review and verify imported data
-- 3. SQL code to create database views for flask app

-- 1. Create database tables

CREATE TABLE jurisdiction (
	jurisdiction_id INT NOT NULL, 
	jurisdiction VARCHAR(25) NOT NULL,
	CONSTRAINT jurisdiction_pkey PRIMARY KEY (jurisdiction_id)
);

CREATE TABLE state (
	state_abbr VARCHAR(2) NOT NULL,
	state VARCHAR(25) NOT NULL, 
	division VARCHAR(20) NOT NULL,
	region VARCHAR(15) NOT NULL,
	CONSTRAINT state_pkey PRIMARY KEY (state_abbr)
);

CREATE TABLE race (
	race_id INT NOT NULL,
	race VARCHAR(50) NOT NULL,
	CONSTRAINT race_pkey PRIMARY KEY (race_id)
);

CREATE TABLE incident (
	incident_id INT NOT NULL,
	incident_year INT NOT NULL,
	incident_date DATE NOT NULL,
	jurisdiction_id INT NOT NULL,
	state_abbr VARCHAR(2) NOT NULL,
	offender_race_id INT NOT NULL,	
	offender_count INT NOT NULL,
	victim_count INT NOT NULL,
	CONSTRAINT incident_pkey PRIMARY KEY (incident_id),
	FOREIGN KEY (jurisdiction_id) REFERENCES jurisdiction(jurisdiction_id),
	FOREIGN KEY (state_abbr) REFERENCES state(state_abbr),
	FOREIGN KEY (offender_race_id) REFERENCES race(race_id)
);

CREATE TABLE bias (
	bias_id INT NOT NULL,
	bias VARCHAR(60) NOT NULL,
	bias_category VARCHAR(30) NOT NULL,
	CONSTRAINT bias_pkey PRIMARY KEY (bias_id)
);	

CREATE TABLE incident_bias (
	incident_id INT NOT NULL,
	bias_id INT NOT NULL,
	CONSTRAINT incident_bias_pkey PRIMARY KEY (incident_id, bias_id),
	FOREIGN KEY (incident_id) REFERENCES incident(incident_id),
	FOREIGN KEY (bias_id) REFERENCES bias(bias_id)
);

CREATE TABLE offense (
	offense_id INT NOT NULL,
	offense VARCHAR(50) NOT NULL,
	code VARCHAR(3) NOT NULL,
	offense_category VARCHAR(50) NOT NULL,
	crimes_against VARCHAR(15) NOT NULL,
	CONSTRAINT offense_id_pkey PRIMARY KEY (offense_id)
);

CREATE TABLE incident_offense (
	incident_id INT NOT NULL,
	offense_id INT NOT NULL,
	CONSTRAINT incident_offense_pkey PRIMARY KEY (incident_id, offense_id),
	FOREIGN KEY (incident_id) REFERENCES incident(incident_id),
	FOREIGN KEY (offense_id) REFERENCES offense(offense_id)
);

CREATE TABLE victim_type (
	victim_type_id INT NOT NULL,
	victim_type VARCHAR(25) NOT NULL,
	CONSTRAINT victim_type_id_pkey PRIMARY KEY (victim_type_id)
);

CREATE TABLE incident_victim_type (
	incident_id INT NOT NULL,
	victim_type_id INT NOT NULL,
	CONSTRAINT incident_victim_type_pkey PRIMARY KEY (incident_id, victim_type_id),
	FOREIGN KEY (incident_id) REFERENCES incident(incident_id),
	FOREIGN KEY (victim_type_id) REFERENCES victim_type(victim_type_id)
);

CREATE TABLE location (
	location_id INT NOT NULL,
	location VARCHAR(50) NOT NULL,
	CONSTRAINT location_id_pkey PRIMARY KEY (location_id)
);

CREATE TABLE incident_location (
	incident_id INT NOT NULL,
	location_id INT NOT NULL,
	CONSTRAINT incident_location_pkey PRIMARY KEY (incident_id, location_id),
	FOREIGN KEY (incident_id) REFERENCES incident(incident_id),
	FOREIGN KEY (location_id) REFERENCES location(location_id)
);

CREATE TABLE census_data (
	id INT NOT NULL,
	year INT NOT NULL,
	state_abbr VARCHAR(2) NOT NULL,
	race_id INT NOT NULL,
	population INT NOT NULL,
	CONSTRAINT id_pkey PRIMARY KEY (id),
	FOREIGN KEY (state_abbr) REFERENCES state(state_abbr),
	FOREIGN KEY (race_id) REFERENCES race(race_id)
);

-- 2. Review and verify imported data

SELECT * FROM jurisdiction;				-- 8 records
SELECT * FROM state;					-- 51 records
SELECT * FROM race;						-- 7 records
SELECT * FROM incident;					-- 81666 records
SELECT * FROM bias;						-- 34 records
SELECT * FROM incident_bias;			-- 82716 records
SELECT * FROM offense;					-- 49 records
SELECT * FROM incident_offense;			-- 84555 records
SELECT * FROM victim_type;				-- 9 records
SELECT * FROM incident_victim_type;		-- 83043 records
SELECT * FROM location;					-- 46 records
SELECT * FROM incident_location;		-- 81790 records
SELECT * FROM census_data;				-- 3978 records

-- 3. SQL views for flask app

-- View for list of years
CREATE VIEW year_view AS
SELECT ROW_NUMBER() OVER (ORDER BY 1) AS id, i.incident_year as year
FROM incident as i
GROUP BY i.incident_year
ORDER BY i.incident_year

-- View for population by state and year
CREATE VIEW population_view AS
SELECT ROW_NUMBER() OVER (ORDER BY 1) AS id, c.year, s.state, sum(c.population) AS population, 'All' AS _all
FROM census_data as c
LEFT JOIN (
	SELECT s.state_abbr, s.state, s.region, s.division
	FROM state AS s
) s
ON s.state_abbr = c.state_abbr
GROUP BY c.year, s.state
ORDER BY c.year, s.state

-- View of incident data used for all charts
CREATE VIEW incident_view AS
SELECT ROW_NUMBER() OVER (ORDER BY 1) AS id, i.incident_id, i.incident_year, s.state_abbr, s.state, s.region, s.division, ib.bias_category, io.offense, 'All' as _all
FROM incident AS i
LEFT JOIN (
	SELECT ib.incident_id, b.bias_category AS bias_category
	FROM incident_bias AS ib
	LEFT JOIN (
		SELECT b.bias_id, b.bias_category
		FROM bias AS b
	) b
	ON ib.bias_id = b.bias_id
) ib
ON i.incident_id = ib.incident_id
LEFT JOIN (
	SELECT io.incident_id, o.offense AS offense
	FROM incident_offense AS io
	LEFT JOIN (
		SELECT o.offense_id, o.offense
		FROM offense AS o
	) o
	ON io.offense_id = o.offense_id
) io
ON i.incident_id = io.incident_id
LEFT JOIN (
	SELECT s.state_abbr, s.state, s.region, s.division
	FROM state AS s
) s
ON i.state_abbr = s.state_abbr
ORDER BY i.incident_id