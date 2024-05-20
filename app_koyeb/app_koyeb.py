# Hate Crimes in the US
# Flask App

# Load dependencies
from flask import Flask, jsonify, render_template
from sqlalchemy import create_engine, MetaData, inspect, Table, Column, Integer, String, func, distinct, and_
from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import Session
from sqlalchemy.sql.expression import cast
import time
import os

# Get database information from config file
# Note: config.py must be created locally and is not stored in Github
from config_koyeb import db_username, db_password, db_host, db_port, db_name, db_options
db_password = os.environ.get('db_password')

app = Flask(__name__)

# Create a SQLAlchemy database engine
db_url = f'postgresql://{db_username}:{db_password}@{db_host}:{db_port}/{db_name}{db_options}'
engine = create_engine(db_url)

# Create MetaData object and reflect existing database
metadata = MetaData()
metadata.reflect(engine)

# Create table objects to set primary key for tables in sqlite database
# Sqlite tables were created with Pandas to_sql which does not support setting primary keys
Table(
    'state',
    metadata,
    Column('state_abbr', String, primary_key=True, nullable=False),
    autoload_with=engine,
    extend_existing=True
)

Table(
    'bias',
    metadata,
    Column('bias_id', Integer, primary_key=True, nullable=False),
    autoload_with=engine,
    extend_existing=True
)

# Set table objects to set primary key for views
Table(
    'year_view',
    metadata,
    Column('id', Integer, primary_key=True, nullable=False),
    autoload_with=engine
)

Table(
    'incident_view',
    metadata,
    Column('id', Integer, primary_key=True, nullable=False),
    autoload_with=engine
)

Table(
    'population_view',
    metadata,
    Column('id', Integer, primary_key=True, nullable=False),
    autoload_with=engine
)

# Create mappings
Base = automap_base(metadata=metadata)
Base.prepare(autoload_with=engine)

# Define variables for related tables
B = Base.classes.bias
S = Base.classes.state
Y = Base.classes.year_view
I = Base.classes.incident_view
P = Base.classes.population_view

print('Connected to database')

# Define static routes

# Launch site
@app.route('/') 
def index():
    return render_template('index.html')

# Get lists for select dropdowns to filter charts
@app.route('/api/lists')
def get_lists():
    try:
        session = Session(engine)
        
        # Year list
        year_results = session.query(Y.year).order_by(Y.year.desc()).all()
        year_list = [row.year for row in year_results]
        
        # State list
        state_results = session.query(S.state).order_by(S.state.asc()).all()
        state_list = [row.state for row in state_results]

        # Bias categories list
        bias_results = session.query(B.bias_category
            ).group_by(B.bias_category
            ).order_by(B.bias_category.asc()
            ).all()
        bias_list = [row.bias_category for row in bias_results]
      
        session.close()
        
        dataToReturn = {'states': state_list, 'years': year_list, 'bias': bias_list}
        
        return jsonify(dataToReturn)   
    
    except Exception as e:
        print("Error accessing the table:", str(e))
        return jsonify({"error": "Table access failed"}), 500

# Get data for bias charts
@app.route('/api/biasdata/<state>')
def get_data(state):
    
    # Call functions to get data for each chart
    inc_list = get_inc_data(state)
    bias_list = get_bias_data(state)

    # Create dictionary for return
    dataToReturn = {'incident': inc_list, 'bias': bias_list}   

    return jsonify(dataToReturn)

# Get data for offense chart
@app.route('/api/offensedata/<year>/<state>/<bias_category>')
def get_offense_data(year, state, bias_category):
    
    # Call function to get data for each chart
    offense_list = get_offense_data(year, state, bias_category)

    # Create dictionary for return
    dataToReturn = {'offense': offense_list}   

    return jsonify(dataToReturn)


# Get data for incident rate chart
@app.route('/api/ratedata/<year>/<bias_category>')
def get_rate_data(year, bias_category):
    
    # Call functions to get data for each chart
    rate_list = get_rate_data(year, bias_category)

    # Create dictionary for return
    dataToReturn = {'rate': rate_list}   

    return jsonify(dataToReturn)

# Define route functions

# Get query results for chart functions
def get_query_results(table, columns, filters, groups_orders):
    
    session = Session(engine)
    results = session.query(table).with_entities(*columns
        ).filter(*filters
        ).group_by(*groups_orders
        ).order_by(*groups_orders
        ).all()
    session.close()

    return results

# Get summary data for bias chart and convert to a list of dictionaries
def get_inc_data(state):

    start_time = time.time()
    
    # Initiatize query variables
    columns = []
    filters = []
    
    # Year - no filtering
    columns.append(I.incident_year)
    
    # State
    if state == 'All':
        columns.append(I._all)
    else:
        columns.append(I.state)
        filters.append(I.state == state)        
    
    # Bias category - no filtering
    columns.append(I._all)

    # Finalize query variables and run query
    groups_orders = columns.copy()
    columns.append(func.count(distinct(I.incident_id)).label('incidents'))
    results = get_query_results(I, columns, filters, groups_orders)
    
    # Create list of dictionaries
    keys = ['year', 'state', 'bias_category', 'incidents', 'population']
    data_list = [dict(zip(keys, row)) for row in results]

    print('Incident data: completed in %s seconds' % (time.time() - start_time))

    return data_list

# Get data for offense chart and convert to a list of dictionaries
def get_offense_data(year, state, bias_category):

    start_time = time.time()

    # Initiatize query variables
    columns = []
    filters = []
    
    # Year
    if year == 'All':
        columns.append(I._all)
    else:
        columns.append(I.incident_year)
        filters.append(I.incident_year == year)

    # State
    if state == 'All':
        columns.append(I._all)
    else:
        columns.append(I.state)
        filters.append(I.state == state)

    # Bias category
    if bias_category == 'All':
        columns.append(I._all)
    else:
        columns.append(I.bias_category)
        filters.append(I.bias_category == bias_category)

    # Finalize query variables and run query
    columns.append(I.offense)
    groups_orders = columns.copy()
    columns.append(func.count(distinct(I.incident_id)).label('incidents'))
    results = get_query_results(I, columns, filters, groups_orders)

    # Create list of dictionaries
    keys = ['year', 'state', 'bias_category', 'offense', 'incidents']
    data_list = [dict(zip(keys, row)) for row in results]

    print('Offense data: completed in %s seconds' % (time.time() - start_time))

    return data_list

# Get data for bias charts and convert to a list of dictionaries
def get_bias_data(state):
    
    start_time = time.time()

    # Initiatize query variables
    columns = []
    filters = []
    
    # Year - no filtering
    columns.append(I.incident_year)
   
    # State
    if state == 'All':
        columns.append(I._all)
    else:
        columns.append(I.state)
        filters.append(I.state == state)
    
    # Bias category - no filtering
    columns.append(I.bias_category)

    # Finalize query variables and run query
    groups_orders = columns.copy()
    columns.append(func.count(distinct(I.incident_id)).label('incidents'))
    results = get_query_results(I, columns, filters, groups_orders)

    # Create list of dictionaries
    keys = ['year', 'state', 'bias_category', 'incidents']
    data_list = [dict(zip(keys, row)) for row in results]

    print('Bias data: completed in %s seconds' % (time.time() - start_time))

    return data_list

# Get list of dictionaries for incident rate chart
def get_rate_data(year, bias_category):

    start_time = time.time()
    
    session = Session(engine)
    
    # Initiatize query variables
    columns = []
    columnsSub = []
    filters = []
    filtersSub = []
    joins = []
    
    # Year
    if year == 'All':
        columns.append(P._all)
        columnsSub.append(I.incident_year)
    else:
        columns.append(P.year)
        columnsSub.append(I.incident_year)
        filters.append(P.year == year)
        filtersSub.append(I.incident_year == year)
    
    # State - no filtering
    columns.append(P.state)
    columnsSub.append(I.state)  
    
    # Bias category
    if bias_category == 'All':
        columnsSub.append(I._all)
    else:
        columnsSub.append(I.bias_category)
        filtersSub.append(I.bias_category == bias_category)

    # Finalize query variables and run subquery
    groupsOrdersSub = columnsSub.copy()
    columnsSub.append(cast(func.count(distinct(I.incident_id)), Integer).label('incidents'))
    
    # Get incident count per state per year for main query
    subquery = session.query(I).with_entities(*columnsSub
        ).filter(*filtersSub
        ).group_by(*groupsOrdersSub).subquery()
    
    # Finalize query variables and run  mainquery
    if bias_category == 'All':
        columns.append(subquery.c._all)
    else:
        columns.append(subquery.c.bias_category)
    groupsOrders = columns.copy()
    columns.append(cast(func.round(func.avg(subquery.c.incidents), 0), Integer).label('incidents'))
    columns.append(cast(func.round(func.avg(P.population), 0), Integer).label('population'))
    if year != 'All':
        joins = [and_(subquery.c.incident_year == P.year, subquery.c.state == P.state)]
    else:
        joins = [and_(subquery.c.state == P.state)]
    
    # Get average incident count and population if year = 'All'
    results = session.query(P).with_entities(*columns
        ).join(subquery, *joins
        ).filter(*filters
        ).group_by(*groupsOrders
        ).order_by(*groupsOrders
        ).all()

    session.close()

    # Create list of dictionaries
    keys = ['year', 'state', 'bias_category', 'incidents', 'population']
    data_list = [dict(zip(keys, row)) for row in results]

    print('Incident rate data: completed in %s seconds' % (time.time() - start_time))

    return data_list
     
if __name__ == '__main__':
    app.run(debug=True)