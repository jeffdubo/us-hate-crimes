-- Project: US Hate Crimes

-- SQL code to create database tables
-- Follow the order below to prevent errors due to foreign key constraints

CREATE TABLE IF NOT EXISTS jurisdiction (
	jurisdiction_id INT NOT NULL, 
	jurisdiction VARCHAR(25) NOT NULL,
	CONSTRAINT jurisdiction_pkey PRIMARY KEY (jurisdiction_id)
);

CREATE TABLE IF NOT EXISTS state (
	state_abbr VARCHAR(2) NOT NULL,
	state VARCHAR(25) NOT NULL, 
	division VARCHAR(20) NOT NULL,
	region VARCHAR(15) NOT NULL,
	CONSTRAINT state_pkey PRIMARY KEY (state_abbr)
);

CREATE TABLE IF NOT EXISTS race (
	race_id INT NOT NULL,
	race VARCHAR(50) NOT NULL,
	CONSTRAINT race_pkey PRIMARY KEY (race_id)
);

CREATE TABLE IF NOT EXISTS incident (
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

CREATE TABLE IF NOT EXISTS bias (
	bias_id INT NOT NULL,
	bias VARCHAR(60) NOT NULL,
	bias_category VARCHAR(30) NOT NULL,
	CONSTRAINT bias_pkey PRIMARY KEY (bias_id)
);	

CREATE TABLE IF NOT EXISTS incident_bias (
	incident_id INT NOT NULL,
	bias_id INT NOT NULL,
	CONSTRAINT incident_bias_pkey PRIMARY KEY (incident_id, bias_id),
	FOREIGN KEY (incident_id) REFERENCES incident(incident_id),
	FOREIGN KEY (bias_id) REFERENCES bias(bias_id)
);

CREATE TABLE IF NOT EXISTS offense (
	offense_id INT NOT NULL,
	offense VARCHAR(50) NOT NULL,
	code VARCHAR(3),
	offense_category VARCHAR(50) NOT NULL,
	crimes_against VARCHAR(15) NOT NULL,
	CONSTRAINT offense_id_pkey PRIMARY KEY (offense_id)
);

CREATE TABLE IF NOT EXISTS incident_offense (
	incident_id INT NOT NULL,
	offense_id INT NOT NULL,
	CONSTRAINT incident_offense_pkey PRIMARY KEY (incident_id, offense_id),
	FOREIGN KEY (incident_id) REFERENCES incident(incident_id),
	FOREIGN KEY (offense_id) REFERENCES offense(offense_id)
);

CREATE TABLE IF NOT EXISTS victim_type (
	victim_type_id INT NOT NULL,
	victim_type VARCHAR(25) NOT NULL,
	CONSTRAINT victim_type_id_pkey PRIMARY KEY (victim_type_id)
);

CREATE TABLE IF NOT EXISTS incident_victim_type (
	incident_id INT NOT NULL,
	victim_type_id INT NOT NULL,
	CONSTRAINT incident_victim_type_pkey PRIMARY KEY (incident_id, victim_type_id),
	FOREIGN KEY (incident_id) REFERENCES incident(incident_id),
	FOREIGN KEY (victim_type_id) REFERENCES victim_type(victim_type_id)
);

CREATE TABLE IF NOT EXISTS location (
	location_id INT NOT NULL,
	location VARCHAR(50) NOT NULL,
	CONSTRAINT location_id_pkey PRIMARY KEY (location_id)
);

CREATE TABLE IF NOT EXISTS incident_location (
	incident_id INT NOT NULL,
	location_id INT NOT NULL,
	CONSTRAINT incident_location_pkey PRIMARY KEY (incident_id, location_id),
	FOREIGN KEY (incident_id) REFERENCES incident(incident_id),
	FOREIGN KEY (location_id) REFERENCES location(location_id)
);

CREATE TABLE IF NOT EXISTS census_data (
	id INT NOT NULL,
	year INT NOT NULL,
	state_abbr VARCHAR(2) NOT NULL,
	race_id INT NOT NULL,
	population INT NOT NULL,
	CONSTRAINT id_pkey PRIMARY KEY (id),
	FOREIGN KEY (state_abbr) REFERENCES state(state_abbr),
	FOREIGN KEY (race_id) REFERENCES race(race_id)
);