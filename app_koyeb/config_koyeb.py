import os

# Set to true to use postgreSQL database, False to use sqlite database
db_flag = 'koyeb' # other options sqlite or postgresql

db_username = 'koyeb-adm'
db_password = os.environ.get('db_password')
db_host = 'ep-summer-mud-a4yjf3wb.us-east-1.pg.koyeb.app'
db_port = 5432
db_name = 'koyebdb'
db_options = '?options=endpoint%3Dep-summer-mud-a4yjf3wb'

# API Key for US Census Bureau
census_key = '921e59d6bcaa21630b4f53e74b7a522a3502b8cb'