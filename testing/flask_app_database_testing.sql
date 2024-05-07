-- Test SQL queries for flask app

-- Incident count totals by year
SELECT ROW_NUMBER() OVER (ORDER BY 1) AS id, i.incident_year AS year, 'All' as state, 'All' as region, 'All' as division, count(i.incident_id) AS incidents
FROM incident AS i
GROUP BY i.incident_year, state, region, division
ORDER BY i.incident_year, state, region, division;

-- Incident rate totals by year and state
SELECT ROW_NUMBER() OVER (ORDER BY 1) AS id, c.year, s.state, s.region, s.division, i.incidents, c.population
FROM state AS s
LEFT JOIN (
	SELECT i.incident_year AS year, i.state_abbr, count(i.incident_id) AS incidents
	FROM incident AS i
	GROUP BY i.incident_year, i.state_abbr
) i
ON s.state_abbr = i.state_abbr
LEFT JOIN (
	SELECT c.year, c.state_abbr, sum(c.population) AS population
	FROM census_data AS c
	GROUP BY c.year, c.state_abbr
) c
ON s.state_abbr = c.state_abbr
WHERE c.year = i.year
ORDER BY c.year, s.state;

-- Incident rate totals by state all years
SELECT ROW_NUMBER() OVER (ORDER BY 1) AS id, 'All' as year, s.state, s.region, s.division, CAST(ROUND(AVG(i.incidents)) AS INTEGER) as incidents, CAST(ROUND(AVG(c.population)) AS INTEGER) as population
FROM state AS s
LEFT JOIN (
	SELECT i.incident_year AS year, i.state_abbr, count(i.incident_id) AS incidents
	FROM incident AS i
	GROUP BY i.incident_year, i.state_abbr
) i
ON s.state_abbr = i.state_abbr
LEFT JOIN (
	SELECT c.year, c.state_abbr, sum(c.population) AS population
	FROM census_data AS c
	GROUP BY c.year, c.state_abbr
) c
ON s.state_abbr = c.state_abbr
GROUP BY s.state, s.region, s.division
ORDER BY s.state, s.region, s.division;

-- Bias totals by year and state
SELECT ROW_NUMBER() OVER (ORDER BY 1) AS id, i.incident_year AS year, s.state, s.region, s.division, ib.bias_category, count(i.incident_id) AS incidents
FROM incident AS i
LEFT JOIN (
	SELECT s.state_abbr, s.state, s.region, s.division
	FROM state AS s
) s
ON i.state_abbr = s.state_abbr
LEFT JOIN (
	SELECT ib.incident_id, b.bias_id, b.bias_category AS bias_category
	FROM incident_bias AS ib
	LEFT JOIN (
		SELECT b.bias_id, b.bias_category
		FROM bias AS b
	) b
	ON ib.bias_id = b.bias_id
	
) ib
ON i.incident_id = ib.incident_id
GROUP BY i.incident_year, s.state, s.region, s.division, ib.bias_category
ORDER BY i.incident_year, s.state, ib.bias_category;

-- Bias totals by year for all states
SELECT ROW_NUMBER() OVER (ORDER BY 1) AS id, i.incident_year AS year, 'All' as state, 'All' as region, 'All' as division, ib.bias_category, count(i.incident_id) AS incidents
FROM incident AS i
LEFT JOIN (
	SELECT ib.incident_id, b.bias_id, b.bias_category AS bias_category
	FROM incident_bias AS ib
	LEFT JOIN (
		SELECT b.bias_id, b.bias_category
		FROM bias AS b
	) b
	ON ib.bias_id = b.bias_id	
) ib
ON i.incident_id = ib.incident_id
GROUP BY i.incident_year, state, region, division, ib.bias_category
ORDER BY i.incident_year, state, region, division, ib.bias_category;

