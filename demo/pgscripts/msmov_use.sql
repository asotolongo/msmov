--ESTIMATION and initialitation
SELECT * FROM msmov.estimation_analysis ('server_mssql_sakila'); 
SELECT sum(cost) FROM msmov.estimation_analysis ('server_mssql_sakila'); 

-- GENERATE USERS AND ROLES MEMBERSHIPS, review the output manually, some clauses can be not compatible 
 SELECT * FROM msmov.generate_users_and_member_roles();

--IMPORT TABLES
SELECT  msmov.create_ftables('dbo','server_mssql_sakila',(SELECT string_agg("TABLE_NAME",',') FROM msmov.mssql_views)); 
--CHANGE TYPE OF COLUMNS
INSERT INTO msmov.mssql_columns_type_change (sch,tab,col,typ) VALUES ('dbo','country','country','varchar(100)');
INSERT INTO msmov.mssql_columns_type_change (sch,tab,col,typ) VALUES ('dbo','country','country_id','int4');
INSERT INTO msmov.mssql_columns_type_change (sch,tab,col,typ) VALUES ('dbo','city','country_id','int4');

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

--Synonyms
SELECT msmov.create_ftsynonyms('dbo' ,'server_mssql_sakila'); 
SELECT msmov.import_synonyms('dbo'); 

-- GENERATE USERS GRANTS, review the output manually, some clauses can be not compatible 
 SELECT distinct * FROM msmov.generate_grants();

--Stasts update
ANALYZE VERBOSE;

--data imported
SELECT * FROM msmov.data_imported_table;
--ERRORES
SELECT * FROM msmov.error_table;

--clean
DROP SCHEMA _dbo cascade ;
DROP SCHEMA msmov cascade ;




