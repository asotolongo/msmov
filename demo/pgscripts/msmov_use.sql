--ESTIMATION and initialitation
SELECT * FROM msmov.estimation_analysis ('server_mssql_sakila'); 
SELECT sum(cost) FROM msmov.estimation_analysis ('server_mssql_sakila'); 

--IMPORT TABLES
SELECT  msmov.create_ftables('dbo','server_mssql_sakila',(SELECT string_agg("TABLE_NAME",',') FROM msmov.mssql_views)); 
SELECT msmov.create_tables_from_ft('dbo');



--IMPORT DATA
SELECT msmov.import_data_one_table('dbo',"TABLE_NAME") FROM msmov.mssql_tables ;




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
--Stasts update
ANALYZE VERBOSE;

--data imported
SELECT * FROM msmov.data_imported_table;
--ERRORES
SELECT * FROM msmov.error_table;

--clean
DROP SCHEMA _dbo cascade ;
DROP SCHEMA msmov cascade ;




