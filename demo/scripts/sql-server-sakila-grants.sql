USE [sakila]
GO

-- Step 1: Create Login
CREATE LOGIN mylogin
WITH PASSWORD = 'Mypassw0rd.';
CREATE LOGIN mylogin2
WITH PASSWORD = 'Mypassw0rd.';

-- Step 2: Create User

CREATE USER mylogin FOR LOGIN mylogin;
GO

CREATE USER mylogin2 FOR LOGIN mylogin2;
GO

GRANT SELECT ON dbo.actor  TO mylogin;
GO
GRANT SELECT ON my_schema.data_tab  TO mylogin;
GO
GRANT SELECT ON dbo.city  TO public; --to public
GO
GRANT EXECUTE ON dbo.get_actor_by_name TO mylogin; --procedure
GO
ALTER ROLE db_datareader ADD MEMBER mylogin; --member
GO
ALTER ROLE db_datareader ADD MEMBER mylogin2; --member
GO

--my_schema, commented
-- CREATE SCHEMA my_schema;
-- GO

-- CREATE TABLE my_schema.data_tab (
-- 	col1 int  ,
-- 	col2 varchar(100) NULL,
-- 	PRIMARY KEY (col1)
-- );
-- GO
-- insert into my_schema.data_tab values (1,'uno'),(2,'dos'),(3,'tres'),(4,'cuatro');
-- GO

-- CREATE SYNONYM my for my_schema.data_tab;
-- CREATE SYNONYM my_schema.my for my_schema.data_tab;
-- GO