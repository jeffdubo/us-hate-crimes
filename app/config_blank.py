# Be sure to rename this file to config.py before running app.py

# Set to true to use postgreSQL database, False to use sqlite database
postgreSQL_flag = True

# Be sure to update all of the variables to connect to your local postgreSQL database
db_username = 'postgres' # Change this if you've created a different user
db_password = '[your password]'
db_host = 'localhost' # Change this if you're accessing a hosted database
db_port = 5432
db_name = '[name of your database]'
db_options = '' # Use this variable to store any options needed to connect to a hosted database

# API Key for US Census Bureau
census_key = '921e59d6bcaa21630b4f53e74b7a522a3502b8cb'