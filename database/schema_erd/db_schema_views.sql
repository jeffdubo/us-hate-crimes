-- Project: US Hate Crimes

-- SQL code to create database views for flask app

CREATE OR REPLACE VIEW year_view AS
SELECT ROW_NUMBER() OVER (ORDER BY 1) AS id, i.incident_year as year
FROM incident as i
GROUP BY i.incident_year
ORDER BY i.incident_year;

CREATE OR REPLACE VIEW population_view AS
SELECT ROW_NUMBER() OVER (ORDER BY 1) AS id, c.year, s.state, sum(c.population) AS population, 'All' AS _all
FROM census_data as c
LEFT JOIN (
	SELECT s.state_abbr, s.state, s.region, s.division
	FROM state AS s
) s
ON s.state_abbr = c.state_abbr
GROUP BY c.year, s.state
ORDER BY c.year, s.state;

CREATE OR REPLACE VIEW incident_view AS
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
ORDER BY i.incident_id;