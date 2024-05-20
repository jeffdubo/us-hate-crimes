// Map creation and related functions
// Initial code based on Leaflet tutorial for Chlorapeth map

// Add hate crime and population info to stateData
var stateFeatures = statesData.features;
stateFeatures.forEach(state => {
    state.properties['incidents'] = -1;
    state.properties['incident_rate'] = -1;
    state.properties['population'] = -1;
    state.properties['status'] = -1;
});

// Store GeoJson map
var stateLayer;

var map = L.map('map', {zoomSnap: .1, attributionControl: false, zoomControl: false}).setView([37.8, -96], 3.9);

var tiles = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    opacity: 0
}).addTo(map);

// Intervals for incident rates
var incidentRates = [0, 50, 100, 200, 300, 500, 700]

// Get color based on incident rate 
function getColor(r) {
    return r > 700 ? '#800026' :
           r > 500 ? '#BD0026' :
           r > 300 ? '#E31A1C' :
           r > 200 ? '#FC4E2A' :
           r > 100 ? '#FD8D3C' :
           r > 50  ? '#FEB24C' :
           r >= 0  ? '#FED976' :
                     'rgba(0,0,0,.1)';
}
  
// Set fill color and styling for states based on their status
function style(feature) {
    status = feature.properties.status
    
    // No states are selected
    if (status == 0) {
        style = {
            fillColor: getColor(feature.properties.incident_rate),
            weight: 2,
            opacity: .7,
            color: 'black',
            fillOpacity: 1
        
        }
    
    // This state is selected
    } else if (status == 1) {
        style = {
            fillColor: '#FFBF00',
            weight: 2,
            opacity: 1,
            color: 'white',
            fillOpacity: 1
        }
    
    // This state is not selected and darkened  
    } else {
        style = {
            fillColor:  getColor(feature.properties.incident_rate),
            weight: 2,
            opacity: .5,
            color: 'black',
            fillOpacity: .4
        }
    };
    return style;
}

// Mouseover listener
function highlightFeature(e) {
    var layer = e.target;

    layer.setStyle({
        weight: 3,
        opacity: 1,
        color: 'white',
        fillOpacity: 1
    });
    
    layer.bringToFront();
    
    info.update(layer.feature.properties);
}

// Mouseout listener
function resetHighlight(e) {
    stateLayer.resetStyle(e.target);
    info.update();
}

// Loop through all states and restyle based on status
function updateAllStates(status) {
    for (const [key, e] of Object.entries(stateLayer._layers)) {
        e.feature.properties.status = status;
        stateLayer.resetStyle(e);
    };
};

// Function called by state event listener
function updateMap(selectedState) {
    var layer = stateLayer.getLayer(selectedState);
    if (selectedState == 'All') {
        updateAllStates(0);
    } else {
        updateAllStates(3);
        layer.feature.properties.status = 1;
        stateLayer.resetStyle(layer);		
    };
}

// Mouseclick listener
function updateState(e) {
    var layer = e.target;
    const selectState = d3.select("#selState");
    const status = layer.feature.properties.status;

    if (status == 1) {
        updateAllStates(0);
        selectState.node().value = 'All';
    } else {
        updateAllStates(3);
        layer.feature.properties.status = 1;
        stateLayer.resetStyle(e.target);
        selectState.node().value = layer.feature.properties.name;
    };
    refreshData(); 
}

// Add listeners to state layer
function onEachFeature(feature, layer) {
    layer.on({
        mouseover: highlightFeature,
        mouseout: resetHighlight,
        click: updateState,
    });
    layer._leaflet_id = feature.properties.name;
}

// Main function to create map
stateLayer = L.geoJson(statesData, {
        style: style,
        onEachFeature: onEachFeature
}).addTo(map);

// Create custom zoom buttons - these are styled in css
L.control.zoom({ position: 'topleft'}).addTo(map);

// Create information box when hovering over a state
var info = L.control();

info.onAdd = function (map) {
    this._div = L.DomUtil.create('div', 'map-info'); // create a div with a class "info"
    this.update();
    return this._div;
};

// Method to update the control based on feature properties passed
info.update = function (props) {
    this._div.innerHTML = (props ?
        '<b>' + props.name + '</b><br />' + props.incidents + ' incidents<br />' + props.incident_rate + ' per 10M population'
        : 'Hover over a state for more information');
};

info.addTo(map);

// Create legend
var legend = L.control({position: 'bottomright'});

legend.onAdd = function (map) {

    var div = L.DomUtil.create('div', 'map-info map-legend'),
        grades = incidentRates,
        labels = [];

    div.innerHTML = '<div id="map-legend-title">Incident Rate</div>';

    // Loop through our incident rate intervals and generate a label with a colored square for each interval
    for (var i = 0; i < grades.length; i++) {
        div.innerHTML +=
            '<i style="background:' + getColor(grades[i] + 1) + '"></i> ' +
            grades[i] + (grades[i + 1] ? '&ndash;' + grades[i + 1] + '<br>' : '+');
    }

    return div;
};

legend.addTo(map);

// Create instructions box for clicking on a state
var clickInfo = L.control({position: "bottomleft"});

clickInfo.onAdd = function (map) {
    this._div = L.DomUtil.create('div', 'map-click');
    this._div.innerHTML = ('Click on a state or use the filters to update the charts below.');
    return this._div;
};

clickInfo.addTo(map);

