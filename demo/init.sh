#!/bin/bash
set -e

[ -z $(docker-compose ps -q ) ] && docker-compose up -d

###install postgres stuff
docker-compose exec pg15 /bin/bash -c  "apt-get update && apt-get install -y libsybdb5 freetds-dev freetds-common postgresql-15-tds-fdw" 

###install mssql stuff
docker-compose exec sqlserver  /bin/bash -c "apt-get update && apt install -y curl && curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | tee /etc/apt/sources.list.d/msprod.list && apt-get update && apt-get -y install mssql-tools unixodbc-dev "
docker-compose exec sqlserver  /bin/bash -c "echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile && echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc"

###CREATE DATABASE
docker-compose exec sqlserver /bin/bash -c "/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'P4ssw0rd.' -i /scripts/create_database.sql"


docker-compose exec sqlserver /bin/bash -c "/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'P4ssw0rd.' -i /scripts/sql-server-sakila-schema.sql"
docker-compose exec sqlserver /bin/bash -c "/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'P4ssw0rd.' -i /scripts/sql-server-sakila-insert-data.sql"


###create extension and import schema from sqlserver in  postgres 
docker-compose exec pg15 /bin/bash -c  "apt-get update && apt-get install -y libsybdb5 freetds-dev freetds-common postgresql-15-tds-fdw" 
docker-compose exec pg15 /bin/bash -c "su - postgres -c 'psql  -c "\""create database pagila;"\"" '"
docker-compose exec pg15 /bin/bash -c "su - postgres -c 'psql -d pagila -f  /pgscripts/mssql_functions.sql'"
docker-compose exec pg15 /bin/bash -c "su - postgres -c 'psql -d pagila -f  /pgscripts/fdw_creation.sql'"
docker-compose exec pg15 /bin/bash -c "su - postgres -c 'psql -d pagila -f  /pgscripts/create_msmov.sql'"





