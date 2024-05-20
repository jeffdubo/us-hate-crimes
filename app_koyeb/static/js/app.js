// Local URL
// var url = 'http://127.0.0.1:5000'
// Koyeb Public URL
var url = 'https://other-eyde-dubspace-9ddfbfe0.koyeb.app/'

// Set variables for html elements for dropdown filters 
var selectYear = d3.select("#selYear");  
var selectState = d3.select("#selState");
var selectBias = d3.select("#selBias");

// Set variables for html elements for information panel
var infoState = d3.select("#infoState");
var infoInc = d3.select("#infoInc");
var infoPop = d3.select("#infoPop");
var infoRate = d3.select("#infoRate");

// Set variable for colors for bias line chart
var biasColor = { 
	'Race, Ethnicity or Ancestry': '#FFBF00',
	'Religion': '#ed6028',
	'Disability': '#a5e84d',
	'Gender': '#f71e1e',
	'Gender Identity': '#4b50cc',
	'Sexual Orientation': '#aa2fcc',
	'All': '#e0e0e0'
};

// Create dropdown options for an HTML element
function createSelectOptions(select, values) {
	select.append("option").attr("value", "All").text("All");
	values.forEach(value => {
		select.append("option").attr("value", value).text(value);
  	});
}

// Get lists for dropdown filters from database
d3.json(url + '/api/lists')
	.then(function (data) {
    	   	
		// Populate the select options for state and year dropdowns
		createSelectOptions(selectYear, data.years);
		createSelectOptions(selectState, data.states);
		createSelectOptions(selectBias, data.bias);
		
		// Set selected year to most recent year
		selectYear.node().value = data.years[0];
	})
	.catch(function (error) {
		console.error("Error loading JSON data:", error);
	});

// Refresh charts, map and information panel with new data
function refreshData() {

	// Initialize variables for app calls
	var selectedYear = selectYear.node().value;
	var selectedState = selectState.node().value;
	var selectedBias = selectBias.node().value;
	if (selectedYear === '') { selectedYear = 2020; };
	if (selectedState === '') { selectedState = 'All'; };
	if (selectedBias === '') { selectedBias = 'All'; };

	// Get bias data and create/update charts
	d3.json(url + '/api/biasdata/'+ selectedState)
		.then(function (data) {
			
			// Create and update charts
			createBiasChart(data.bias, data.incident);
			createBiasPieChart(data.bias, selectedYear);
		})
		.catch(function (error) {
    		console.error("Error loading JSON data:", error);
		});	

	// Get offense data and create/update chart
	d3.json(url + '/api/offensedata/' + selectedYear + '/' + selectedState + '/' + selectedBias)
		.then(function (data) {
			
			createOffenseChart(data.offense);
		})
		.catch(function (error) {
    		console.error("Error loading JSON data:", error);
		});	

	// Get incident rate data and create/update charts, panel information and map
	d3.json(url + '/api/ratedata/' + selectedYear + '/' + selectedBias)
		.then(function (data) {
  			
			// Update panel information
			const infoDict = getStateInfo(data.rate);
			updatePanelandMap(infoDict, selectedState, selectedYear);

			// Create and update chart
			createIncRateChart(infoDict);
		})
		.catch(function (error) {
    		console.error("Error loading JSON data:", error);
		});

}

// Create charts and panel information when site launches
refreshData();

// Get panel information and data for incident rate chart
function getStateInfo(data, selectedState, selectedYear) {

	// Create dictionary with data
	const infoDict = {};
	
	// Initialize key to total incidents and population for all states
	infoDict['All'] = {'incidents': 0, 'incident_rate': 0, 'population': 0 };
    
	data.forEach(entry => {
        if (!infoDict[entry.state]) {
			infoDict[entry.state] = {'incidents': 0, 'incident_rate': 0, 'population': 0 }
        };
        infoDict[entry.state].incidents = entry.incidents;
		infoDict[entry.state].incident_rate = Math.round(entry.incidents/entry.population*10000000, 1);
        infoDict[entry.state].population = Math.round(entry.population/100000)/10;
		infoDict['All'].incidents += entry.incidents;
		infoDict['All'].population += entry.population;	
    });
	// Calculate incide_rate for all states combined (used for panel for US)
	infoDict['All'].incident_rate = Math.round(infoDict['All'].incidents/infoDict['All'].population*10000000, 1);
	infoDict['All'].population = Math.round(infoDict['All'].population/100000)/10;

	// Return dictionary to update map and create incident rate chart
	return infoDict
}

// Update information panel and map when data is refreshed
function updatePanelandMap(infoDict, selectedState, selectedYear) {
	
	// Update heading for information panel
	if (selectedState == 'All') {
		infoState.text("United States");
	} else {
		infoState.text(selectedState);
	};
	
	// Display message when years is set to all (indicates that values are averages over all years)
	const message = d3.select("#info-message");
	if (selectedYear == "All") {
		message.classed("d-block", true);
		message.classed("d-none", false);
	} else {
		message.classed("d-block", false);
		message.classed("d-none", true);
	};
	
	// Update panel data
	infoInc.text(infoDict[selectedState].incidents);
	infoPop.text(infoDict[selectedState].population + "M");
	infoRate.text(infoDict[selectedState].incident_rate);

	// Update state data on map
	Object.keys(infoDict).forEach(state => {
		if (state != 'All') {
			const layer = stateLayer.getLayer(state);
			layer.feature.properties.incidents = infoDict[state].incidents;
			layer.feature.properties.incident_rate = infoDict[state].incident_rate;
			layer.feature.properties.population = infoDict[state].population;
			stateLayer.resetStyle(layer);
		};
	});

	// Update map appearance based on selected state
	updateMap(selectedState);
}

function createBiasChart(biasData, incidentData) {
	
	// Store incident years and totals
	const years = incidentData.map(item => item.year);
	const incidents = incidentData.map(item => item.incidents);

	// Create a dictionary with a trace for each bias
	const traceDict = {};
	const allDict = {}
	
	// Create traces for each bias category
	biasData.forEach(entry => {
    	if (!traceDict[entry.bias_category]) {
	    	traceDict[entry.bias_category] = {
        		x: [],
          		y: [],
				mode: 'lines',
				line: { color: biasColor[entry.bias_category], width: 3 },
          		name: entry.bias_category,
        	};
    	};	
    	traceDict[entry.bias_category].x.push(entry.year);
    	traceDict[entry.bias_category].y.push(entry.incidents);
	});

	// Create trace for all categories combined
	traceDict['All'] = {
		x: years,
		y: incidents,
		mode: 'lines',
		line: { color: biasColor['All'], width: 2 },
		name: 'All Categories'
	};

	// Extract traces and store in a data array
    const chartData = Object.values(traceDict);

	// Specify the layout options for the chart
    const layout = {
		xaxis: { showgrid: false },
      	yaxis: { title: 'Incidents', griddash: 'dot', gridcolor: 'rgba(255,255,255,.1)'},
		font: { color: 'white'},
		showlegend: false,
		paper_bgcolor: 'rgba(0,0,0,0)',
		plot_bgcolor: 'rgba(0,0,0,0)',
		height: 375,
		margin: {t: 25, r: 25, b: 35, l: 70}
    };

	// Ensure chart adjust size to accomodate Bootstap's responsive layout
	const config = {responsive: true}

    // Render the chart in the specified container
    Plotly.newPlot("biasChart", chartData, layout, config);
}

function createBiasPieChart(data, selectedYear) {
	
	// Create a dictionary with a trace for each bias
	const traceDict = {};
	data.forEach(entry => {
    	if (!traceDict[entry.bias_category]) {
	    	traceDict[entry.bias_category] = 0;
		};	
    	if (selectedYear == 'All' | selectedYear == entry.year) {
			traceDict[entry.bias_category] += entry.incidents;
		}
	});
	
	const biasCategories = Object.keys(traceDict);
	const incidents = Object.values(traceDict);
	const biasColors = biasCategories.map(category => biasColor[category])

	// Create trace for chart and store in a data array
	const chartData = [{
			values: incidents,
			marker: {
				colors: biasColors,
			},
			labels: biasCategories,
			type: 'pie',
			hole: .5
		}];

	// Specify the layout options for the chart
    const layout = {
     	font: { color: 'white'},
		showlegend: true,
		legend: { 'orientation': 'h'}, // , 'yanchor': 'auto'
		paper_bgcolor: 'rgba(0,0,0,0)',
		plot_bgcolor: 'rgba(0,0,0,.5)',
		height: 375,
		margin: {t: 25, r: 25, b: 100, l: 40}
    };

	// Ensure chart adjust size to accomodate Bootstap's responsive layout
	const config = {responsive: true}

    // Render the chart in the specified container
    Plotly.newPlot("biasPieChart", chartData, layout, config);
}

function createOffenseChart(data) {
	
	// Create a dictionary with chart data
	const chartDict = {};
    data.forEach(entry => { chartDict[entry.offense] = entry.incidents });
    
	// Extract lists for trace - sort and slice to get top 10 states with the highest incident rates
    const offenses = Object.keys(chartDict).sort((a, b) => chartDict[b] - chartDict[a]).slice(0, 10).reverse();
    const incidents = offenses.map(offense => chartDict[offense]);
    
	// Create trace for chart and store in a data array
    const chartData = [{
        type: 'bar',
        x: incidents,
        y: offenses,
        orientation: 'h',
		marker: { color: '#FFBF00' }
    }];

	// Specify the layout options for the chart
    const layout = {
		yaxis: {
			automargin: true,
			// Use transparent tick to add spacing between labels and axis
			ticks: 'outside',
			tickcolor: 'rgba(0,0,0,0)',
			ticklen: 5
		},
        xaxis: {
			title: { text: 'Incidents', standoff: 15 },
			griddash: 'dot',
			gridcolor: 'rgba(255,255,255,.1)',
			// Use transparent tick to add spacing between labels and axis
			ticks: 'outside',
			tickcolor: 'rgba(0,0,0,0)',
			ticklen: 3
		},
		font: { color: 'white'},
		paper_bgcolor: 'rgba(0,0,0,0)',
		plot_bgcolor: 'rgba(0,0,0,0)',
		margin: {t: 20, r: 25, b: 70, l: 25},
		height: 375
    };
    
	// Ensure chart adjust size to accomodate Bootstap's responsive layout
	const config = {responsive: true}

	// Render the chart in the specified container
    Plotly.newPlot("offenseChart", chartData, layout, config);
}

function createIncRateChart(chartDict) {

	// Remove all from dictionary
	delete chartDict['All'];

	// Extract lists for trace, sort and slice to get top 10 states with the highest incident rates
    const states = Object.keys(chartDict).sort((a, b) => chartDict[b].incident_rate - chartDict[a].incident_rate).slice(0, 10).reverse();
    const incident_rate = states.map(state => chartDict[state].incident_rate);
    const population = states.map(state => 'Population: ' + chartDict[state].population.toLocaleString() + 'M');
    
    const chartData = [{
      	x: incident_rate,
      	y: states,
      	text: population,
      	type: 'bar',
      	orientation: 'h',
		marker: { color: '#FFBF00' }
    }];
    
	// Specify the layout options for the chart
    const layout = {
      	yaxis: {
			automargin: true,
			// Use transparent tick to add spacing between labels and axis
			ticks: 'outside',
			tickcolor: 'rgba(0,0,0,0)',
			ticklen: 5
		},
      	xaxis: {
			title: { text: 'Incidents per 10M people', standoff: 18 },
			griddash: 'dot',
			gridcolor: 'rgba(255,255,255,.1)',
			ticks: 'outside',
			tickcolor: 'rgba(0,0,0,0)',
			ticklen: 3
		},
		font: { color: 'white'},
		paper_bgcolor: 'rgba(0,0,0,0)',
		plot_bgcolor: 'rgba(0,0,0,0)',
		height: 375,
		margin: {t: 20, r: 15, b: 70, l: 15}
		
    };
    
	// Ensure chart adjust size to accomodate Bootstap's responsive layout
	const config = {responsive: true}

    // Render the chart in the specified container
    Plotly.newPlot('chartIncRate', chartData, layout, config);

	// Return dictionary for updating map information
	return chartDict
    
  }