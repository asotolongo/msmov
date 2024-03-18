This demo is to test the msmov module to migrate from MSSQL to PostgreSQL, using the demo database named: sakila

the version of database origin and target in this demo

MSSQL: 2019
PostgreSQL: 15

* Initialize the docker-compose  lab
```
sh init.sh
```
* Migration.

Connect to container database and perform the migration process using SQL`s command only

`docker-compose exec pg15 /bin/bash -c "su - postgres -c 'psql -d pagila'`

```
--Estimation and Initialitation
SELECT * FROM msmov.estimation_analysis ('server_mssql_sakila'); 
SELECT sum(cost) FROM msmov.estimation_analysis ('server_mssql_sakila'); 

--IMPORT TABLES
SELECT  msmov.create_ftables('dbo','server_mssql_sakila',(select string_agg("TABLE_NAME",',') FROM msmov.mssql_views)); 
SELECT msmov.create_tables_from_ft('dbo');



--IMPORT DATA
SELECT "TABLE_NAME",msmov.import_data_one_table('dbo',"TABLE_NAME") from msmov.mssql_tables ;




--PK
SELECT msmov.create_ftpkey('dbo','server_mssql_sakila');
SELECT msmov.import_pk_tables('dbo');

--UNIQUES
SELECT msmov.create_ftukey('dbo' ,'server_mssql_sakila');
SELECT msmov.import_uk_tables('dbo'); 

--FK
SELECT msmov.create_ftfkey('dbo' ,'server_mssql_sakila');
SELECT msmov.import_fk_tables('dbo');

--Checks
SELECT msmov.create_ftckey('dbo' ,'server_mssql_sakila');
SELECT msmov.import_ck_tables('dbo');

--Indexes
SELECT msmov.create_ftindex('dbo' ,'server_mssql_sakila');
SELECT msmov.import_index_tables('dbo') ;

--Views
SELECT msmov.create_ftviews('dbo' ,'server_mssql_sakila');
SELECT msmov.import_views('dbo');

--Sequences
SELECT msmov.create_ftsequences('dbo' ,'server_mssql_sakila'); 
SELECT msmov.import_sequences('dbo'); 
--Stats update
ANALYZE VERBOSE;

--data imported
SELECT * from msmov.data_imported_table;
--ERRORS
SELECT * from msmov.error_table;

--clean
drop schema _dbo cascade ;
drop schema msmov cascade ;





```

* Stop and destroy the docker-compose  lab
```
sh clean.sh
```



