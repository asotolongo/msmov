## msmov

`msmov` is a PostgreSQL module to facilitate migration from MSSQL to PostgreSQL using Foreign Data Wrapper `tds_fdw`, this module is composed of two components (schemas) :

* msmov function:  Functions to perform the migration from MSSQL (schema msmov)
* mssql function and operators:  Functions and operators with MSSQL compatibility (schema mssql)

The migration can be performed by SQL commands directly from the  PostgreSQL database.

`msmov` can make an estimation for the migration and show the main characteristics and components of your original MSSQL database, `msmov` will migrate : TABLES, CONSTRAINTS, INDEXES, PKS, FKS, UNIQUES, CHECKS CONSTRAINTS,  SEQUENCES, SYNONYMS, VIEWS (TRIGGERS, FUNCTIONS, PROCEDURES, JOBS don't be migrate directly but you can get the code).

This strategy(using FDW) to perform the migration from MSSQL to PostgreSQL has several advantages:

* Simplicity: Facilitates access to remote data without the need for additional external tools.

* Control: With everything being inside PostgreSQL, you have granular control over data migration and transformation operations, given to you the option to create SQL scripts as you need, and if you kown/use SQL you will love this strategy


### PREREQUISITES:
Previous install msmov module you must install and configure the FDW [`tds_fdw`](https://github.com/tds-fdw/tds_fdw):


```
CREATE EXTENSION tds_fdw;


CREATE SERVER                 
   server_mssql
   FOREIGN DATA WRAPPER tds_fdw
   OPTIONS( servername 'sqlserver',
   port '1433',
   database 'name_of_your_mssql_database',
   --msg_handler 'notice',  
   tds_version '7.4'   --https://www.freetds.org/userguide/ChoosingTdsProtocol.html  
);

CREATE USER MAPPING FOR public
        SERVER server_mssql
        OPTIONS (
       username 'msmsql_user', --require permission to read the mssql catalog(sys and information_schema) and read access for users data tables (fixed role db_datareader)
       password 'msmsql_user_password'
);


```

MSSQL msmsql_user require permission to read the mssql catalog(sys and information_schema) and read access for users data tables (fixed database role db_datareader)

In PostgreSQL, the user required  privileges to create PostgreSQL schemas



It recommendable add `mssql` to your database's `search_path`, to add the functions and operators from mssql schema,  for example:


```
ALTER DATABASE pgdatabase SET search_path = public,mssql, "$user";
```

Load in your database the scripts from [mssql](scripts/mssql_functions.sql) and [msmov](scripts/create_msmov.sql)

### Main functions and tables

Inside the `msmov` schema you can find the following functions:

* msmov.estimation_analysis ('name_of_foreign_server'): Function to get an analysis and cost estimation, it is mandatory to use this function first because it initializes some required objects inside `msmov` schema. 

* msmov.create_ftables('schema_to_migrate','server_name_of_foreign_server','tables_to_exclude'): Function to migrate the tables from the schema `schema_to_migrate`  , `name_of_foreign_server` is the name of your foreign server, `tables_to_exclude` means the tables to exclude from the migration (comma separate list), `tables_to_exclude` by default is NULL. Internally create the foreign tables inside the schema named: `_schema_to_migrate` in addition a schema with the same name (`schema_to_migrate`) of origin database is created in PostgreSQL.

* msmov.create_tables_from_ft('schema_to_migrate'): Create physical tables in schema `schema_to_migrate` from the foreign tables.


* msmov.import_data_one_table('schema_to_migrate',"TABLE_NAME"): Function to migrate data for a table, if your tables are big we recommend using another tool (that uses `COPY`, such as: [pgloader](https://github.com/dimitri/pgloader)) to migrate data because this function uses the `INSERT` command and this can be slow in some cases. It is recommended to parallelize this process in different scripts to improve the speed of data migration.


* msmov.create_ftpkey('schema_to_migrate','server_name_of_foreign_server') : Function to migrate the PKs from the schema `schema_to_migrate`  , `name_of_foreign_server` is the name of your foreign server.  Internally create the foreign table with the information about PKs inside the schema named: `_schema_to_migrate`.


* msmov.create_ftukey('schema_to_migrate','server_name_of_foreign_server'):  Similar to `create_ftpkey` function but with the information related to `UNIQUE` constrainst. 

* msmov.create_ftfkey('schema_to_migrate','server_name_of_foreign_server'):  Similar to `create_ftpkey` function but with the information related to `FOREIGN KEY` constrainst. 


* msmov.create_ftckey('schema_to_migrate','server_name_of_foreign_server'):  Similar to `create_ftpkey` function but with the information related to `CHECK` constrainst. 


* msmov.create_ftindex('schema_to_migrate','server_name_of_foreign_server'):  Similar to `create_ftpkey` function but with the information related to `INDEXES`. 


* msmov.create_ftviews('schema_to_migrate','server_name_of_foreign_server'): Similar to `create_ftpkey` function but with the information related to `VIEWS`. 

* msmov.create_ftsequences('schema_to_migrate','server_name_of_foreign_server'): Similar to `create_ftpkey` function but with the information related to `SEQUENCES`. 

* msmov.create_ftsynonyms('schema_to_migrate','server_name_of_foreign_server'): Similar to `create_ftpkey` function but with the information related to `synonyms`.

* msmov.import_pk_tables('schema_to_migrate'):  Create physical PKs for tables in schema `schema_to_migrate`. 

* msmov.import_uk_tables('schema_to_migrate'):  Similar `import_pk_tables` but with the information related to `UNIQUES` constrainst. 

* msmov.import_fk_tables('schema_to_migrate'):  Similar `import_pk_tables` but with the information related to `FOREIGN KEY` constrainst. 

* msmov.import_ck_tables('schema_to_migrate'): Similar `import_pk_tables` but with the information related to `CHECK` constrainst. 

* msmov.import_index_tables('schema_to_migrate'): Similar `import_pk_tables` but with the information related to `INDEXES`. 

* msmov.import_views('schema_to_migrate'): Similar `import_pk_tables` but with the information related to `VIEWS`. 

* msmov.import_sequences('schema_to_migrate'): Similar `import_pk_tables` but with the information related to `SEQUENCES`. 

* msmov.import_synonyms: ('schema_to_migrate'): Similar `import_pk_tables` but with the information related to `SYNONYMS`. 

Inside the `msmov`` schema you can find the following tables:


* msmov.data_imported_table: store the information related to rows migrated using the function: `import_data_one_table`
* msmov.error_table: store the information related to errors returned using the msmov for migrating
* msmov.mssql_columns_type_change: store the rules of data type changes, the changes will apply when execute the function `msmov.create_tables_from_ft`

### Use
```
--ESTIMATION and initialitation
SELECT * FROM msmov.estimation_analysis ('server_mssql'); 
SELECT sum(cost) FROM msmov.estimation_analysis ('server_mssql'); 

-- GENERATE USERS AND ROLES MEMBERSHIPS, review the output manually, some clauses can be not compatible 
 SELECT * FROM msmov.generate_users_and_member_roles() 

--IMPORT TABLES
SELECT  msmov.create_ftables('dbo','server_mssql',(select string_agg("TABLE_NAME",',') FROM msmov.mssql_views)); 
--CHANGE TYPE OF COLUMNS
INSERT INTO msmov.mssql_columns_type_change (sch,tab,col,typ) VALUES ('dbo','country','country','varchar(100)');
SELECT msmov.create_tables_from_ft('dbo');


--IMPORT DATA
SELECT msmov.import_data_one_table('dbo',"TABLE_NAME") from msmov.mssql_tables ;-- you can perform this in different scripts by passing the tables required for parallelizing this process


--PK
SELECT msmov.create_ftpkey('dbo','server_mssql');
SELECT msmov.import_pk_tables('dbo');

--UNIQUES
SELECT msmov.create_ftukey('dbo' ,'server_mssql');
SELECT msmov.import_uk_tables('dbo'); 

--FK
SELECT msmov.create_ftfkey('dbo' ,'server_mssql');
SELECT msmov.import_fk_tables('dbo');

--Checks
SELECT msmov.create_ftckey('dbo' ,'server_mssql');
SELECT msmov.import_ck_tables('dbo');

--Indexes
SELECT msmov.create_ftindex('dbo' ,'server_mssql');
SELECT msmov.import_index_tables('dbo') ;

--Views
SELECT msmov.create_ftviews('dbo' ,'server_mssql');
SELECT msmov.import_views('dbo');

--Sequences
SELECT msmov.create_ftsequences('dbo' ,'server_mssql'); 
SELECT msmov.import_sequences('dbo'); 

--Synonyms
SELECT msmov.create_ftsynonyms('dbo' ,'server_mssql_sakila'); 
SELECT msmov.import_synonyms('dbo'); 


-- GENERATE USERS GRANTS, review the output manually, some clauses can be not compatible 
 SELECT * FROM msmov.generate_grants() 

--Stasts update
ANALYZE VERBOSE;

--Data imported
SELECT * from msmov.data_imported_table;
--ERRORS
SELECT * from msmov.error_table;

--clean objects
drop schema _dbo cascade ;
drop schema msmov cascade ;
```

### Demo

[Migration demo](demo/README.md) (origin database MSSQL 2019, target database: PostgreSQL 15)

### Compatibility 
This module was tested with  MSSQL version:  2014, 2016, 2017,2019  and the following [data types are allowed](https://github.com/tds-fdw/tds_fdw/blob/master/src/tds_fdw.c#L3126-L3530
function=tdsImportSqlServerSchema)

* bit
* smallint
* tinyint
* int
* bigint
* decimal
* numeric
* money
* smallmoney
* float
* real
* date
* datetime
* datetime2
* smalldatetime
* timestamp
* datetimeoffset
* time
* char
* nchar
* varchar
* nvarchar
* text
* ntext
* binary
* varbinary
* image
* xml

_NOTE: MSSQL 2012 can work, but not tested_

## Errors tips

* DATE issue  due to locale setting differences:
 Sometimes you can face issues with date/datetime format during the data migration, you can solve it using following:

    * Changing temporally the data type

      ```
      --change data type to text
      --using the msmov option to change the data type 
      INSERT INTO msmov.mssql_columns_type_change (sch,tab,col,typ) VALUES ('dbo','name_of_table','rental_date','text');
      --or use the ALTER TABLE clause directly
      ALTER TABLE _dbo."name_of_table" ALTER COLUMN data TYPE text ;
      ALTER TABLE dbo."name_of_table" ALTER COLUMN data TYPE text ;
      --migrate data
      --change data type ujsing a transformation
      ALTER TABLE dbo."name_of_table" ALTER COLUMN data TYPE date using (to_date(data,'Mon DD YYYY HH12:MI:SS:AM') );

      ```

    * Changing locale for freeTDS 
    Edit the file `/etc/freetds/freetds.conf` adding the following:
      ```
      [default]
      date format = %b %e %Y %I:%M:%S.%z%p
      ```

* Characters conversions and buffer Issues  

For example: 
```
* HV00L-DB-Library error: DB #: 2404, DB Msg: Buffer overflow converting characters from client into server's character set, OS #: 0, OS Msg: Success, Level:
* HV00L-DB-Library error: DB #: 2403, DB Msg: Some character(s) could not be converted into client's character set.  Unconverted bytes were changed to question marks ('?'), OS #: 0, OS Msg: Success, Level: 4-
* HV00L-DB-Library error: DB #: 20018, DB Msg: General SQL Server error: Check messages from the SQL Server, OS #: -1, OS Msg: , Level: 16-
```

These issues are related with the following issues reported in TDS_FDW extension:

* https://github.com/tds-fdw/tds_fdw/issues/103
* https://github.com/tds-fdw/tds_fdw/issues/351
* https://github.com/tds-fdw/tds_fdw/issues/289
* https://github.com/tds-fdw/tds_fdw/issues/136

To solve it you can use another tool(for example  [pgloader](https://github.com/dimitri/pgloader)) to migrate the data of the tables related to these errors


## License
Permission to use, copy, modify, and distribute this software and its documentation for any purpose, without fee, and without a written agreement is hereby granted, provided that the above copyright notice and this paragraph and the following two paragraphs appear in all copies.
IN NO EVENT SHALL THE AUTHORS BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
THE AUTHORS SPECIFICALLY DISCLAIM ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE AUTHORS HAVE NO OBLIGATIONS TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.


## Authors: 

This module is an open project. Feel free to join us and improve this module. To find out how you can get involved, please contact us or write us:

* Anthony Sotolongo: 
asotolongo@gmail.com