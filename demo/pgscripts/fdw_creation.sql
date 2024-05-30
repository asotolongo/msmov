ALTER DATABASE pagila SET search_path = public,mssql, "$user";

CREATE EXTENSION tds_fdw ;


--sakila
CREATE SERVER                 
   server_mssql_sakila
   FOREIGN DATA WRAPPER tds_fdw
   OPTIONS( servername 'sqlserver',
   port '1433',
   database 'sakila',
   --msg_handler 'notice',  
   tds_version '7.4'   --https://www.freetds.org/userguide/ChoosingTdsProtocol.html  
);

CREATE USER MAPPING FOR public
        SERVER server_mssql_sakila
        OPTIONS (
       username 'sa',
       password 'P4ssw0rd.'
);

--CREATE SCHEMA sakila;
--IMPORT FOREIGN SCHEMA dbo  FROM SERVER server_mssql_sakila  INTO sakila OPTIONS (import_default 'true', import_not_null 'true');
