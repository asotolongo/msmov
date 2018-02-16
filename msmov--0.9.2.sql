CREATE SCHEMA msmov;


SET search_path = msmov, pg_catalog;

--
-- TOC entry 364 (class 1255 OID 30190)
-- Name: clean_ft_schema(text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION clean_ft_schema(source_schema text) RETURNS void
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
            
                command:= 'DROP  schema _'||$1||' CASCADE' ;
		EXECUTE command;
		
		
	
		EXCEPTION
			WHEN OTHERS THEN
                        RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
			RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
    
 
	
     END;	
     $_$;


--
-- TOC entry 341 (class 1255 OID 31030)
-- Name: conver_to_lower(text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION conver_to_lower(p_esquema text) RETURNS void
    LANGUAGE plpgsql
    AS $_$
declare
tablas record ;
columnas character varying;
cambiar_columna text;
cambiar_tabla text;
begin
  --tables of schema
 for tablas in select table_schema as esquema, table_name as tabla,'"'|| table_schema||'"."'||table_name||'"' as completo from information_schema.tables where
  table_schema =lower($1) and table_type='BASE TABLE' loop
  raise notice 'change in table: %',tablas.completo;
  --change column name by table 
   --get table's columns

    for columnas in  select '"'||column_name||'"' from information_schema.columns where table_schema=tablas.esquema and table_name=tablas.tabla loop
     --change column
      cambiar_columna := 'ALTER TABLE ';
      cambiar_columna:=cambiar_columna || tablas.completo ||' RENAME column '|| columnas ||' TO '|| lower(columnas);
      BEGIN
      EXECUTE  cambiar_columna;
      EXCEPTION
         WHEN duplicate_column THEN
           RAISE NOTICE 'Column %  of table % alredy in lower ',columnas,tablas.completo;
         WHEN syntax_error THEN
           RAISE NOTICE 'In Table %   sintax error',tablas.completo ;
      end;
    end loop;
    
    cambiar_tabla := 'ALTER TABLE ';
    cambiar_tabla:=cambiar_tabla || tablas.completo ||' RENAME to '|| lower(tablas.tabla);
    --change  table name
    BEGIN
    EXECUTE  cambiar_tabla;
    EXCEPTION
         WHEN duplicate_table THEN
           RAISE NOTICE 'Table %  alredy in lower',tablas.completo ;
         WHEN syntax_error THEN
           RAISE NOTICE 'In Table %  sintax error',tablas.completo ;
    end;


 end loop;

end;

$_$;


--
-- TOC entry 369 (class 1255 OID 28133)
-- Name: create_ftables_import(text, text, text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION create_ftables_import(source_schema text, target_schema text, fdw_name text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
        BEGIN    
                
		
	

		command:= 'IMPORT FOREIGN SCHEMA "'||$1|| '" FROM SERVER '||$3|| ' INTO _'||$2 || ' OPTIONS (import_default ''true'', import_not_null ''true'');';
		EXECUTE command;
		EXCEPTION
			WHEN OTHERS THEN
                        RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
			RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
    
 
	END;
       --limpiando tablas del sistema
       command := 'DROP FOREIGN TABLE IF EXISTS _'||$2||'.sysdiagrams';
       EXECUTE command;

       SELECT count(*) into cnt from information_schema.foreign_table_options  WHERE option_name='schema_name' and option_value=$1;
       RAISE NOTICE 'Create  % FOREIGN tables in schema _%, corresponding to tables from MSSQL schema %', cnt,$2,$1;
       RETURN cnt;
     END;	
     $_$;


--
-- TOC entry 372 (class 1255 OID 28702)
-- Name: create_ftckey(text, text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION create_ftckey(source_schema text, fdw_name text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
        BEGIN    
                command:= 'drop FOREIGN TABLE IF EXISTS _'||$1||'._c_keys';
                EXECUTE command;
		command:= 'CREATE  FOREIGN TABLE _'||$1||'._c_keys(tab text, cname text, clause text  ) server '|| $2 ||' options ( query ''select U.TABLE_NAME tab ,  C.CONSTRAINT_NAME cname ,C.CHECK_CLAUSE clause from INFORMATION_SCHEMA.CHECK_CONSTRAINTS as C
INNER JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE as U 
      ON C.CONSTRAINT_NAME=U.CONSTRAINT_NAME
WHERE  U.TABLE_NAME <>''''sysdiagrams'''' AND  C.constraint_schema='''''||$1||'''''
      '')';
		EXECUTE command;
		EXCEPTION
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
                        RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
    
 
	END;
       RETURN 1;
     END;	
     $_$;


--
-- TOC entry 3367 (class 0 OID 0)
-- Dependencies: 372
-- Name: FUNCTION create_ftckey(source_schema text, fdw_name text); Type: COMMENT; Schema: msmov; Owner: -
--

COMMENT ON FUNCTION create_ftckey(source_schema text, fdw_name text) IS 'create FOREIGN TABLE  _schema._identity_column for identity columns ';


--
-- TOC entry 351 (class 1255 OID 28758)
-- Name: create_ftdefault(text, text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION create_ftdefault(p_schema text, fdw_name text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
        BEGIN
                command:= 'drop FOREIGN TABLE IF EXISTS _'||$1||'._default';
                EXECUTE command;
                command:= 'CREATE  FOREIGN TABLE _'||$1||'._default(tab text, col text,dtype text, len smallint,pre int, def varchar,nullable varchar) server '|| $2 ||' options ( QUERY ''

SELECT CAST(a.name as text) as tab,
b.name as col,
c.name as dtype,
b.length as len,
b.xscale as pre,
CASE
WHEN b.cdefault > 0 THEN d.text
ELSE NULL
END as def,
CASE
WHEN b.isnullable = 0 THEN ''''No''''
ELSE ''''Yes''''
END as nullable
FROM sysobjects a
INNER JOIN syscolumns b
ON a.id = b.id
inner join sys.tables st 
on st.object_id=b.id
inner join sys.schemas ss
on ss.schema_id=st.schema_id
INNER JOIN systypes c
ON b.xtype = c.xtype
LEFT JOIN syscomments d
ON b.cdefault = d.id
WHERE a.xtype = ''''u''''
AND a.name <>''''sysdiagrams''''

AND a.name <> ''''dtproperties''''
AND b.cdefault > 0
and ss.name='''''||$1||'''''
ORDER BY a.name,b.colorder  '')';
		EXECUTE command;
		EXCEPTION
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
                        RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
    
 
	END;
       RETURN 1;
     END;	
     $_$;


--
-- TOC entry 374 (class 1255 OID 28628)
-- Name: create_ftfkey(text, text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION create_ftfkey(source_schema text, fdw_name text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
        BEGIN   
                command:= 'drop FOREIGN TABLE IF EXISTS _'||$1||'.f_keys';
                EXECUTE command;
		command:= 'CREATE  FOREIGN TABLE _'||$1||'._f_keys(tab character varying,fkname character varying,col character varying,tab_ref_schema character varying,
	tab_ref character varying,tab_ref_col character varying,m character varying,upt character varying,del character varying ) server '|| $2 ||' options ( query ''
       SELECT TC.table_name as tab, TC.CONSTRAINT_NAME fkname,KU.COLUMN_NAME col, T.table_schema tab_ref_schema,  T.TABLE_NAME tab_ref,  T.COLUMN_NAME tab_ref_col,
R.MATCH_OPTION m,R.UPDATE_RULE upt,R.DELETE_RULE del
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS TC
INNER JOIN
    INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KU
          ON TC.CONSTRAINT_TYPE = ''''FOREIGN KEY'''' AND
             TC.CONSTRAINT_NAME = KU.CONSTRAINT_NAME 
INNER JOIN 
    INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS as R
          ON R.CONSTRAINT_NAME=TC.CONSTRAINT_NAME
INNER JOIN 
    INFORMATION_SCHEMA.KEY_COLUMN_USAGE as T
    ON R.UNIQUE_CONSTRAINT_NAME=T.CONSTRAINT_NAME
       WHERE KU.table_name<>''''sysdiagrams'''' AND TC.table_schema='''''||$1||'''''
ORDER BY KU.TABLE_NAME, KU.ORDINAL_POSITION
	'')';
		EXECUTE command;
		EXCEPTION
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
                        RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
    
 
	END;
       RETURN 1;
     END;	
     $_$;


--
-- TOC entry 3368 (class 0 OID 0)
-- Dependencies: 374
-- Name: FUNCTION create_ftfkey(source_schema text, fdw_name text); Type: COMMENT; Schema: msmov; Owner: -
--

COMMENT ON FUNCTION create_ftfkey(source_schema text, fdw_name text) IS 'create FOREIGN TABLE  _schema.f_keys for FK constraint ';


--
-- TOC entry 349 (class 1255 OID 46427)
-- Name: create_ftidentitycolumn(text, text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION create_ftidentitycolumn(source_schema text, fdw_name text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
        BEGIN    
                command:= 'drop FOREIGN TABLE IF EXISTS _'||$1||'._identity_column';
                EXECUTE command;
		command:= 'CREATE  FOREIGN TABLE _'||$1||'._identity_column(tab text, col text  ) server '|| $2 ||' options ( query ''select TABLE_NAME as tab,COLUMN_NAME as col
from INFORMATION_SCHEMA.COLUMNS
where COLUMNPROPERTY(object_id(TABLE_SCHEMA+''''.''''+TABLE_NAME), COLUMN_NAME, ''''IsIdentity'''') = 1 and 
TABLE_NAME not in (select name from sys.views) and table_name <>''''sysdiagrams'''' and table_schema ='''''||$1||'''''
order by TABLE_NAME 
      '')';
		EXECUTE command;
		EXCEPTION
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
                        RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
    
 
	END;
       RETURN 1;
     END;	
     $_$;


--
-- TOC entry 407 (class 1255 OID 29524)
-- Name: create_ftindex(text, text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION create_ftindex(source_schema text, fdw_name text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
        BEGIN
                command:= 'drop FOREIGN TABLE IF EXISTS _'||$1||'._indexs';
                EXECUTE command;
                command:= 'CREATE  FOREIGN TABLE _'||$1||'._indexs(tab character varying,iname character varying,col character varying,filter int,
	filter_def character varying ) server '|| $2 ||' options ( query ''SELECT 
      t.name tab,
     ind.name iname,
     col.name col,
     ind.has_filter filter,
     ind.filter_definition filter_def
FROM 
     sys.indexes ind 
INNER JOIN 
     sys.index_columns ic ON  ind.object_id = ic.object_id and ind.index_id = ic.index_id 
INNER JOIN 
     sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id 
INNER JOIN 
     sys.tables t ON ind.object_id = t.object_id 
INNER JOIN sys.schemas sch    on t.schema_id= sch.schema_id
WHERE 
     ind.is_primary_key = 0 
     AND ind.is_unique = 0 
     AND ind.is_unique_constraint = 0 
     AND t.is_ms_shipped = 0 
     AND sch.name='''''||$1||'''''
ORDER BY 
     t.name, ind.name, ind.index_id, ic.index_column_id'')';
		EXECUTE command;
		EXCEPTION
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
                        RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
    
 
	END;
       RETURN 1;
     END;	
     $_$;


--
-- TOC entry 350 (class 1255 OID 28753)
-- Name: create_ftnull(text, text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION create_ftnull(p_schema text, fdw_name text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
        BEGIN
                command:= 'drop FOREIGN TABLE IF EXISTS _'||$1||'._null';
                EXECUTE command;
                command:= 'CREATE  FOREIGN TABLE _'||$1||'._null(tab text, col text,dtype text, len smallint,pre int, def varchar,nullable varchar) server '|| $2 ||' options ( QUERY ''

SELECT CAST(a.name as text) as tab,
b.name as col,
c.name as dtype,
b.length as len,
b.xscale as pre,
CASE
WHEN b.cdefault > 0 THEN d.text
ELSE NULL
END as def,
CASE
WHEN b.isnullable = 0 THEN ''''No''''
ELSE ''''Yes''''
END as nullable
FROM sysobjects a
INNER JOIN syscolumns b
ON a.id = b.id
inner join sys.tables st 
on st.object_id=b.id
inner join sys.schemas ss
on ss.schema_id=st.schema_id
INNER JOIN systypes c
ON b.xtype = c.xtype
LEFT JOIN syscomments d
ON b.cdefault = d.id
WHERE a.xtype = ''''u''''
AND a.name <>''''sysdiagrams''''

AND a.name <> ''''dtproperties''''
AND b.isnullable = 0 
and ss.name='''''||$1||'''''
ORDER BY a.name,b.colorder  '')';
		EXECUTE command;
		EXCEPTION
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
                        RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
    
 
	END;
       RETURN 1;
     END;	
     $_$;


--
-- TOC entry 384 (class 1255 OID 28445)
-- Name: create_ftpkey(text, text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION create_ftpkey(p_schema text, fdw_name text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
        BEGIN
                command:= 'drop FOREIGN TABLE IF EXISTS _'||$1||'._p_keys';
                EXECUTE command;
                command:= 'CREATE  FOREIGN TABLE _'||$1||'._p_keys(tab text, pk text  ) server '|| $2 ||' options ( QUERY ''SELECT KU.table_name as tab,column_name as pk
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS TC
INNER JOIN     INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KU
          ON TC.CONSTRAINT_TYPE = ''''PRIMARY KEY'''' AND
             TC.CONSTRAINT_NAME = KU.CONSTRAINT_NAME 
AND KU.table_name<>''''sysdiagrams''''
AND TC.table_schema='''''||$1||'''''
ORDER BY KU.TABLE_NAME, KU.ORDINAL_POSITION'')';
		EXECUTE command;
		EXCEPTION
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
                        RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
    
 
	END;
       RETURN 1;
     END;	
     $_$;


--
-- TOC entry 371 (class 1255 OID 28713)
-- Name: create_ftukey(text, text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION create_ftukey(source_schema text, fdw_name text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
        BEGIN
                command:= 'drop FOREIGN TABLE IF EXISTS _'||$1||'._u_keys';
                EXECUTE command;
		command:= 'CREATE  FOREIGN TABLE _'||$1||'._u_keys(tab text, uname text, col text  ) server '|| $2 ||' options ( query ''SELECT KU.table_name as tab,ku.CONSTRAINT_NAME uname,column_name as col
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS TC
INNER JOIN     INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KU
          ON TC.CONSTRAINT_TYPE = ''''UNIQUE'''' AND
             TC.CONSTRAINT_NAME = KU.CONSTRAINT_NAME 
AND KU.table_name<>''''sysdiagrams''''
WHERE TC.table_schema='''''||$1||'''''
ORDER BY KU.TABLE_NAME, KU.ORDINAL_POSITION'')';
		EXECUTE command;
		EXCEPTION
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
                        RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
    
 
	END;
       RETURN 1;
     END;	
     $_$;


--
-- TOC entry 3369 (class 0 OID 0)
-- Dependencies: 371
-- Name: FUNCTION create_ftukey(source_schema text, fdw_name text); Type: COMMENT; Schema: msmov; Owner: -
--

COMMENT ON FUNCTION create_ftukey(source_schema text, fdw_name text) IS 'create FOREIGN TABLE  _schema.c_keys for UNIQUE constraint ';


--
-- TOC entry 354 (class 1255 OID 35259)
-- Name: create_ftuniqueindex(text, text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION create_ftuniqueindex(source_schema text, fdw_name text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
        BEGIN
                command:= 'drop FOREIGN TABLE IF EXISTS _'||$1||'._unique_indexs';
                EXECUTE command;
                command:= 'CREATE  FOREIGN TABLE _'||$1||'._unique_indexs(tab character varying,iname character varying,col character varying,filter int,
	filter_def character varying ) server '|| $2 ||' options ( query ''SELECT distinct
      t.name tab,
     ind.name iname,
     col.name col,
     ind.has_filter filter,
     ind.filter_definition filter_def
FROM 
     sys.indexes ind 
INNER JOIN 
     sys.index_columns ic ON  ind.object_id = ic.object_id and ind.index_id = ic.index_id 
INNER JOIN 
     sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id 
INNER JOIN 
     sys.tables t ON ind.object_id = t.object_id 
     INNER JOIN sys.schemas sch    on t.schema_id= sch.schema_id
WHERE 
     
      ind.is_unique <> 0  and  t.name<>''''sysdiagrams''''
      AND sch.name='''''||$1||'''''
    
ORDER BY 
     t.name, ind.name'')';
		EXECUTE command;
		EXCEPTION
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
                        RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
    
 
	END;
       RETURN 1;
     END;	
     $_$;


--
-- TOC entry 397 (class 1255 OID 29575)
-- Name: create_ftviews(text, text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION create_ftviews(source_schema text, fdw_name text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
        BEGIN
                command:= 'drop FOREIGN TABLE IF EXISTS _'||$1||'._views';
                EXECUTE command;
                command:= 'CREATE  FOREIGN TABLE _'||$1||'._views(tab character varying,  ddl character varying  ) server '|| $2 ||' options ( query ''
                SELECT table_name tab, VIEW_DEFINITION ddl FROM INFORMATION_SCHEMA.VIEWS where table_schema='''''||$1||''''' '')';
		EXECUTE command;
		EXCEPTION
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
                        RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
    
 
	END;
       RETURN 1;
     END;	
     $_$;


--
-- TOC entry 3370 (class 0 OID 0)
-- Dependencies: 397
-- Name: FUNCTION create_ftviews(source_schema text, fdw_name text); Type: COMMENT; Schema: msmov; Owner: -
--

COMMENT ON FUNCTION create_ftviews(source_schema text, fdw_name text) IS 'Create  FOREIGN TABLE _schema._views with detail of views';


--
-- TOC entry 347 (class 1255 OID 28241)
-- Name: create_tables_from_ft(text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION create_tables_from_ft(p_schema text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     tab text;
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
        FOR tab IN SELECT foreign_table_name FROM Information_schema.foreign_tables where foreign_table_schema='_'||lower($1) LOOP
                RAISE NOTICE 'CREATING  TABLE: %.%',$1,tab; 
                command:= 'DROP TABLE  IF EXISTS '||$1||'."'||tab||'" CASCADE';
                EXECUTE command;
		command:= 'CREATE TABLE  '||$1||'."'||tab||'" (LIKE _'||$1||'."'||tab||'")';
		BEGIN
		EXECUTE command;
		EXCEPTION
			WHEN SQLSTATE '42P07' THEN
			RAISE NOTICE '%', command;
			GET STACKED DIAGNOSTICS men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
			INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
			RAISE NOTICE 'Table %  exist ',$1||'.'||tab;
			cnt:=cnt-1;
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
			RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
                        cnt:=cnt-1;
		END;
		cnt:=cnt+1;	 

       END LOOP; 
       RAISE NOTICE 'TOTAL TABLES CREATED: %',cnt; 
       RETURN cnt;
     END;	
     $_$;


--
-- TOC entry 382 (class 1255 OID 56887)
-- Name: disable_indexs(boolean, character varying); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION disable_indexs(a boolean, schema_name character varying) RETURNS void
    LANGUAGE plpgsql
    AS $_$
declare 
act character varying;
r record;
cnt int:=0;
begin
    if(a is true) then
        act = 'disable';
        drop table if exists msmov.index_tmp  ;
        create table msmov.index_tmp  as (         select nspname,relname,pg_get_indexdef(indexrelid) definicion from pg_index join pg_class on  (pg_index.indexrelid=pg_class.oid)
                join pg_namespace ns  on (pg_class.relnamespace = ns.oid)

                where  indisprimary=false  and indisunique=false  and nspname in (lower($2)));
        for r in select * from msmov.index_tmp
    loop
        cnt:=cnt+1;
        raise notice 'Droping index DROP INDEX %."%" ', r.nspname, r.relname;
        execute 'DROP INDEX ' || r.nspname||'."'|| r.relname||'"' ;
    end loop;
        
    else
        act = 'enable';
        for r in select * from msmov.index_tmp
    loop
        cnt:=cnt+1;
        raise notice 'Creating index   %', r.definicion;
        execute r.definicion ;

    end loop;
    drop table if exists msmov.index_tmp  ;
    
    end if;

    raise notice 'Count of indexs: %',cnt;
end;
$_$;


--
-- TOC entry 403 (class 1255 OID 56884)
-- Name: disable_triggers(boolean, character varying); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION disable_triggers(a boolean, schema_name character varying) RETURNS void
    LANGUAGE plpgsql
    AS $_$
declare 
act character varying;
r record;
cnt int:=0;
begin
    if(a is true) then
        act = 'disable';
    else
        act = 'enable';
    end if;

    for r in select c.relname from pg_namespace n
        join pg_class c on c.relnamespace = n.oid and c.relhastriggers = true
        where n.nspname in (lower($2))
    loop
        cnt:=cnt+1;
        raise notice 'ALTER TABLE %.% % trigger all', $2, r.relname, act;
        execute 'ALTER TABLE '||$2||'."'||r.relname|| '" '||act|| ' trigger all';
    end loop;
    raise notice 'number of triggers: %',cnt;
end;
$_$;


--
-- TOC entry 370 (class 1255 OID 28706)
-- Name: import_ck_tables(text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION import_ck_tables(target_schema text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     tab record;
     tmp text;
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
        command := 'SELECT * FROM _'||$1||'._c_keys  ';
        FOR tab IN EXECUTE command  LOOP
                        tmp:='ALTER TABLE '||$1||'."'||tab.tab||'" ADD CONSTRAINT '||tab.cname||' CHECK '||replace(replace(tab.clause,'[','"'),']','"');
                        command :=  tmp;
			BEGIN
                        RAISE NOTICE 'IMPORTING CHECK IN TABLE %', tab.tab;
			EXECUTE command;
			EXCEPTION
				WHEN OTHERS THEN
				RAISE NOTICE 'command: %', command;
				GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                                cnt:=cnt-1;
                                INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
				RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;

			END;
			cnt:=cnt+1;

       END LOOP; 
       RAISE NOTICE 'TOTAL CHECKS CONSTRAINTS  IMPORTED: %',cnt; 
       RETURN cnt;
     END;	
     $_$;


--
-- TOC entry 346 (class 1255 OID 28305)
-- Name: import_data_alltables(text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION import_data_alltables(p_schema text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     tab text;
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     total bigint;
     BEGIN
        FOR tab IN SELECT foreign_table_name FROM Information_schema.foreign_tables where foreign_table_schema='_'||lower($1) and foreign_table_name not in ('_c_keys','_default','_f_keys','_identity_column','_indexs','_null','_p_keys','_u_keys','_unique_indexs','_views')  LOOP
                RAISE NOTICE 'DELETING DATA FROM TABLE: %.%',$1,tab;  
                --command := 'TRUNCATE '|| $1||'."'||tab||'"'; 
                command := 'DELETE FROM '|| $1||'."'||tab||'"';  
                EXECUTE command;
                RAISE NOTICE 'IMPORTING DATA IN TABLE: %.%',$1,tab; 
		command:= 'INSERT INTO '|| $1||'."'||tab||'" SELECT *  FROM _'||$1||'."'||tab||'"';
		BEGIN
		EXECUTE command;
                command:= 'SELECT count(*)  FROM '||$1||'."'||tab||'"';
                EXECUTE command into total ;
                RAISE NOTICE 'TABLE DATA: %, % ROWS',$1||'.'||tab, total;
                INSERT INTO msmov.data_imported_table (id,date_time,tab, cnt) VALUES ($1,statement_timestamp()::timestamp without time zone ,$1||'.'||tab, total);
		EXCEPTION
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,statement_timestamp()::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
			RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
			cnt:=cnt-1;
			--RAISE EXCEPTION 'Error %, %,% ',sqlerror,men,mendetail;
		END;
		cnt:=cnt+1;	 

       END LOOP; 
       RAISE NOTICE 'TOTAL DATA TABLE IMPORTED: %',cnt; 
       RETURN cnt;
     END;	
     $_$;


--
-- TOC entry 385 (class 1255 OID 31874)
-- Name: import_data_alltables_by_portion(text, integer); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION import_data_alltables_by_portion(from_schema text, portion integer DEFAULT 500000) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     tab text;
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     total int :=0;
     part int:=0;
     BEGIN
        FOR tab IN SELECT foreign_table_name FROM Information_schema.foreign_tables where foreign_table_schema='_'||lower($1) and foreign_table_name not in ('_c_keys','_default','_f_keys','_identity_column','_indexs','_null','_p_keys','_u_keys','_unique_indexs','_views')  LOOP
                RAISE NOTICE 'DELETING DATA FROM TABLE: %.%',$1,tab;  
                command := 'DELETE FROM  '|| $1||'."'||tab||'"'; 
                EXECUTE command;
                --by portion
                RAISE NOTICE 'IMPORTING DATA IN TABLE: %.%',$1,tab; 
                command:= 'SELECT count(*)  FROM _'||$1||'."'||tab||'"';
                EXECUTE command into total ;
                part := ceiling(total::real/$2);
                --1 by 1                 
                FOR j IN 0..part-1 LOOP
  
			command:= 'INSERT INTO '|| lower($1)||'."'||tab||'" SELECT *  FROM _'||$1||'."'||tab||'" LIMIT '||$2::text||' OFFSET '||(j*$2)::text;
			RAISE NOTICE 'IMPORTING DATA % IN TABLE %',$2*j ,lower($1)||'.'||tab;
			BEGIN
			EXECUTE command;
			EXCEPTION
				WHEN OTHERS THEN
                                RAISE NOTICE 'command: %', command;
				GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                                INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
				RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
				--RAISE EXCEPTION 'Error %, %,% ',sqlerror,men,mendetail;
			END;
		END LOOP;

		cnt:=cnt+1;	
		RAISE NOTICE 'TOTAL DATA IMPORTED  IN TABLE %: %',lower($1)||'.'||tab,total;
                INSERT INTO msmov.data_imported_table (id,date_time,tab, cnt) VALUES ($1,current_timestamp::timestamp without time zone ,$1||'.'||tab, total);
 

       END LOOP; 
       RAISE NOTICE 'TOTAL DATA TABLE IMPORTED: %',cnt; 
       RETURN cnt;
     END;	
     $_$;


--
-- TOC entry 3371 (class 0 OID 0)
-- Dependencies: 385
-- Name: FUNCTION import_data_alltables_by_portion(from_schema text, portion integer); Type: COMMENT; Schema: msmov; Owner: -
--

COMMENT ON FUNCTION import_data_alltables_by_portion(from_schema text, portion integer) IS 'import data from all tables by step portion';


--
-- TOC entry 361 (class 1255 OID 28766)
-- Name: import_default_tables(text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION import_default_tables(p_schema text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     tab record;
     tmp text;
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
        command := 'SELECT  tab, col,def FROM _'||$1||'._default ';
        FOR tab IN EXECUTE command  LOOP
                RAISE NOTICE 'IMPORTING DEFAULT  IN TABLE %', tab.tab; 
                command := 'ALTER TABLE '||$1||'."'||tab.tab||'" ALTER COLUMN "'|| tab.col ||'" SET DEFAULT '||tab.def;
                BEGIN
                EXECUTE command;
		EXCEPTION
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        cnt:=cnt-1;
			RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
		END;
		cnt:=cnt+1;	 

       END LOOP; 
       RAISE NOTICE 'TOTAL DEFAULT  IMPORTED: %',cnt; 
       RETURN cnt;
     END;	
     $_$;


--
-- TOC entry 376 (class 1255 OID 28636)
-- Name: import_fk_tables(text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION import_fk_tables(target_schema text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     tab record;
     tmp text;
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     tpy text :='NO ACTION';
     BEGIN
        command := 'SELECT * FROM _'||$1||'._f_keys';
        FOR tab IN EXECUTE command  LOOP
                tmp:='ALTER TABLE '||$1||'."'||tab.tab||'" ADD CONSTRAINT "'||tab.fkname||'" FOREIGN KEY ("'||tab.col||'") REFERENCES '||tab.tab_ref_schema||'."'||tab.tab_ref||'" ("'||tab.tab_ref_col||'") MATCH '||tab.m||' ON UPDATE '||tab.upt||' ON DELETE '||tab.del ;
                command :=  tmp;
                              
                --RAISE NOTICE '%', command; 
                BEGIN
                  RAISE NOTICE 'IMPORTING FK IN TABLE %', tab.tab;
                  EXECUTE command;
		  EXCEPTION
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        cnt:=cnt-1;
			RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);



		END;
		cnt:=cnt+1;	 

       END LOOP; 
       RAISE NOTICE 'TOTAL FKS  IMPORTED: %',cnt; 
       RETURN cnt;
     END;	
     $_$;


--
-- TOC entry 357 (class 1255 OID 46432)
-- Name: import_identity_column(text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION import_identity_column(p_schema text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     tab record;
     tmp text;
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     seq_name text;
     BEGIN
        command := 'SELECT  tab, col FROM _'||$1||'._identity_column ';
        FOR tab IN EXECUTE command  LOOP
                RAISE NOTICE 'IMPORTING INDENTITY COLUMN  IN TABLE %', tab.tab; 
                seq_name := $1||'.'||tab.tab||'_'||tab.col||'_seq';
                --drop sequence
                command := 'DROP SEQUENCE  IF EXISTS '|| seq_name ||' CASCADE';
                EXECUTE command;
                --create sequence
                command := 'CREATE SEQUENCE '||seq_name;
                EXECUTE command;
                command := 'ALTER TABLE '||$1||'."'||tab.tab||'" ALTER COLUMN "'|| tab.col ||'" SET DEFAULT nextval('''||seq_name||''')';
                EXECUTE command;
                BEGIN
                EXECUTE command;
		EXCEPTION
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        cnt:=cnt-1;
			RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
		END;
		cnt:=cnt+1;	 

       END LOOP; 
       RAISE NOTICE 'TOTAL INDENTITY COLUMN  IMPORTED: %',cnt; 
       RETURN cnt;
     END;	
     $_$;


--
-- TOC entry 387 (class 1255 OID 29528)
-- Name: import_indexs_tables(text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION import_indexs_tables(target_schema text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     tab record;
     tmp text;
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
        command := 'SELECT tab,iname,string_agg(''"''||col||''"'','','') as col,filter,filter_def FROM _'||$1||'._indexs group by 1,2,4,5';
        FOR tab IN EXECUTE command  LOOP
                command := 'CREATE INDEX "idx_'||tab.tab||'_'||tab.iname||'" ON '||$1||'."'||tab.tab||'" ('||tab.col||')';
                IF tab.filter=1 THEN
                 command:=command|| 'WHERE '||replace(replace(tab.filter_def,'[','"'),']','"');
                END IF;
                RAISE NOTICE 'IMPORTING INDEX % IN TABLE %',tab.iname, tab.tab; 
                BEGIN
                EXECUTE command;
		EXCEPTION
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        cnt:=cnt-1;
			RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
		END;
		cnt:=cnt+1;	 

       END LOOP; 
       RAISE NOTICE 'TOTAL INDEX IMPORTED: %',cnt; 
       RETURN cnt;
     END;	
     $_$;


--
-- TOC entry 3372 (class 0 OID 0)
-- Dependencies: 387
-- Name: FUNCTION import_indexs_tables(target_schema text); Type: COMMENT; Schema: msmov; Owner: -
--

COMMENT ON FUNCTION import_indexs_tables(target_schema text) IS 'Import UNIQUE INDEX   using  _schema._unique_indexs';


--
-- TOC entry 381 (class 1255 OID 28765)
-- Name: import_null_tables(text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION import_null_tables(p_schema text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     tab record;
     tmp text;
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
        command := 'SELECT  tab, col FROM _'||$1||'._null ';
        FOR tab IN EXECUTE command  LOOP
                RAISE NOTICE 'IMPORTING NOT NULL  IN TABLE %', tab.tab; 
                command := 'ALTER TABLE '||$1||'."'||tab.tab||'" ALTER COLUMN "'|| tab.col ||'" SET NOT NULL';
                BEGIN
                EXECUTE command;
		EXCEPTION
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        cnt:=cnt-1;
			RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
		END;
		cnt:=cnt+1;	 

       END LOOP; 
       RAISE NOTICE 'TOTAL NOT NULL  IMPORTED: %',cnt; 
       RETURN cnt;
     END;	
     $_$;


--
-- TOC entry 380 (class 1255 OID 28600)
-- Name: import_pk_tables(text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION import_pk_tables(p_schema text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     tab record;
     tmp text;
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
        command := 'SELECT  tab, string_agg(''"''||pk||''"'','','') as pk FROM _'||$1||'._p_keys where tab not in (''sysdiagrams'') group by 1';
        FOR tab IN EXECUTE command  LOOP
                RAISE NOTICE 'IMPORTING PRIMARY KEY IN TABLE %', tab.tab; 
                command := 'ALTER TABLE '||$1||'."'||tab.tab||'" ADD PRIMARY KEY ('|| tab.pk ||')';
                BEGIN
                EXECUTE command;
		EXCEPTION
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        cnt:=cnt-1;
			RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
		END;
		cnt:=cnt+1;	 

       END LOOP; 
       RAISE NOTICE 'TOTAL PKS  IMPORTED: %',cnt; 
       RETURN cnt;
     END;	
     $_$;


--
-- TOC entry 3373 (class 0 OID 0)
-- Dependencies: 380
-- Name: FUNCTION import_pk_tables(p_schema text); Type: COMMENT; Schema: msmov; Owner: -
--

COMMENT ON FUNCTION import_pk_tables(p_schema text) IS 'Import PK constraint  using  _schema.pf_keys';


--
-- TOC entry 358 (class 1255 OID 28717)
-- Name: import_uk_tables(text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION import_uk_tables(target_schema text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     tab record;
     tmp text;
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
        command := 'SELECT tab,uname, string_agg(''"''||col||''"'','','') as col FROM _'||$1||'._u_keys where tab not in (''sysdiagrams'') group by 1,2';
        FOR tab IN EXECUTE command  LOOP
                tmp:= 'ALTER TABLE '||$1||'."'||tab.tab||'" ADD CONSTRAINT '||tab.uname||' UNIQUE ('||tab.col||')';
         
                command :=  tmp;
                BEGIN
                RAISE NOTICE 'IMPORTING UNIQUE KEY IN TABLE %', tab.tab;
                EXECUTE command;
		EXCEPTION
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        cnt:=cnt-1;
			RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);


		END;
		cnt:=cnt+1;	 

       END LOOP; 
       RAISE NOTICE 'TOTAL UNIQUES  IMPORTED: %',cnt; 
       RETURN cnt;
     END;	
     $_$;


--
-- TOC entry 3374 (class 0 OID 0)
-- Dependencies: 358
-- Name: FUNCTION import_uk_tables(target_schema text); Type: COMMENT; Schema: msmov; Owner: -
--

COMMENT ON FUNCTION import_uk_tables(target_schema text) IS 'Import unique constraint  using  _schema.u_keys';


--
-- TOC entry 360 (class 1255 OID 35264)
-- Name: import_unique_indexs_tables(text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION import_unique_indexs_tables(target_schema text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     tab record;
     tmp text;
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
        command := 'SELECT tab,iname,string_agg(''"''||col||''"'','','') as col,filter,filter_def FROM _'||$1||'._unique_indexs group by 1,2,4,5';
        FOR tab IN EXECUTE command  LOOP
                command := 'CREATE UNIQUE INDEX idx_'||tab.iname||' ON '||$1||'."'||tab.tab||'" ('||tab.col||')';
                IF tab.filter=1 THEN
                 command:=command|| 'WHERE '||replace(replace(tab.filter_def,'[','"'),']','"');
                END IF;
                RAISE NOTICE 'IMPORTING UNIQUE INDEX % IN TABLE %',tab.iname, tab.tab; 
                BEGIN
                EXECUTE command;
		EXCEPTION
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        cnt:=cnt-1;
			RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
		END;
		cnt:=cnt+1;	 

       END LOOP; 
       RAISE NOTICE 'TOTAL UNIQUE INDEX IMPORTED: %',cnt; 
       RETURN cnt;
     END;	
     $_$;


--
-- TOC entry 401 (class 1255 OID 29579)
-- Name: import_views(text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION import_views(target_schema text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     tab record;
     tmp text;
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
        command := 'SELECT * FROM _'||$1||'._views';
        FOR tab IN EXECUTE command  LOOP
                RAISE NOTICE 'IMPORTING VIEW: %', tab.tab;
                command := 'set search_path ='||lower($1) ; 
                EXECUTE command;
                
                command := replace(replace(tab.ddl,'[','"'),']','"');  
                
                BEGIN
                EXECUTE command;
		EXCEPTION
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        cnt:=cnt-1;
			RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
		END;
		cnt:=cnt+1;	 

       END LOOP; 
       RAISE NOTICE 'TOTAL VIEWS  IMPORTED: %',cnt; 
       command := 'set search_path to DEFAULT' ;
       EXECUTE command;
       RETURN cnt;
     END;	
     $_$;


--
-- TOC entry 3375 (class 0 OID 0)
-- Dependencies: 401
-- Name: FUNCTION import_views(target_schema text); Type: COMMENT; Schema: msmov; Owner: -
--

COMMENT ON FUNCTION import_views(target_schema text) IS 'Import views using  _schema._views';


--
-- TOC entry 391 (class 1255 OID 70989)
-- Name: migrate(text, text, boolean, boolean); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION migrate(source_schema text, fdw_name text, dat boolean DEFAULT true, lower boolean DEFAULT false) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
            
        RAISE NOTICE 'Begining migration from schema % sql server to  schema %  postgres ',$1,lower($1);
        
        command:= 'DELETE  FROM msmov.error_table' ;
	EXECUTE command;
	command:= 'DELETE  FROM msmov.data_imported_table' ;
	EXECUTE command;
        
        command:= 'DROP SCHEMA IF EXISTS _'||$1||' CASCADE' ;
	EXECUTE command;
        IF $1<>'public' THEN
	command:= 'DROP SCHEMA IF EXISTS '||$1||' CASCADE' ;
	EXECUTE command;
        END IF;
        command:= 'CREATE SCHEMA _'||$1 ;
	EXECUTE command;
        IF $1<>'public' THEN 
	command:= 'CREATE SCHEMA '||$1 ;
	EXECUTE command;
	END IF;
        
        RAISE NOTICE 'Migrating tables ';
        --schema
        PERFORM msmov.create_ftables_import($1,$1,$2);
        PERFORM  msmov.create_tables_from_ft($1);

        IF $3=true THEN 
        RAISE NOTICE 'Migrating data  '; 
        --data
        PERFORM  msmov.import_data_alltables($1);

        END If;

        RAISE NOTICE 'Migrating identity column '; 
        --identity column 
        PERFORM msmov.create_ftidentitycolumn($1,$2);
        PERFORM msmov.import_identity_column($1);
        --set  sequences
        IF $3=true THEN 
        PERFORM msmov.set_value_identity_column($1);
        END If;
        

        RAISE NOTICE 'Migrating constraints '; 
	--constraint
	--pk
	PERFORM msmov.create_ftpkey ($1,$2);
	PERFORM msmov.import_pk_tables($1);
	--fk
	PERFORM msmov.create_ftfkey($1,$2);
	PERFORM msmov.import_fk_tables ($1);
	--check
	PERFORM msmov.create_ftckey($1,$2);
	PERFORM msmov.import_ck_tables($1);
	--unique
	PERFORM msmov.create_ftukey($1,$2);
	PERFORM msmov.import_uk_tables($1);
	--null 
	PERFORM  msmov.create_ftnull ($1,$2);
	PERFORM msmov.import_null_tables($1);

	--default
	PERFORM  msmov.create_ftdefault ($1,$2);
	PERFORM msmov.import_default_tables($1);

        RAISE NOTICE 'Migrating indexs '; 
	--indexs
	PERFORM msmov.create_ftindex($1,$2);
	PERFORM msmov.import_indexs_tables($1);

	--unique index
	PERFORM msmov.create_ftuniqueindex($1,$2);
	PERFORM msmov.import_unique_indexs_tables($1);


	RAISE NOTICE 'Migrating views '; 


	--views
	PERFORM msmov.create_ftviews ($1,$2);
	PERFORM msmov.import_views($1);

         IF $4=true THEN
         --convert to lower
        RAISE NOTICE 'Converting to lower'; 
        PERFORM msmov.conver_to_lower($1);
          
        END IF;

        IF $3=true THEN  
        RAISE NOTICE 'cleaning objects ';         
        PERFORM msmov.clean_ft_schema($1);

        RAISE NOTICE 'Update statistics';         
        ANALYZE ;
        END IF;

        
        
                
	RETURN 1;

    
     EXCEPTION
			WHEN OTHERS THEN
                        
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,'ERROR',sqlerror||'-'||men||'-'||mendetail);
			RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
			RETURN 0;
	
       
     END;	
     $_$;


--
-- TOC entry 389 (class 1255 OID 71931)
-- Name: migrate_by_portion(text, text, boolean, boolean, integer); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION migrate_by_portion(source_schema text, fdw_name text, dat boolean DEFAULT true, lower boolean DEFAULT false, portion integer DEFAULT 500000) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
            
        RAISE NOTICE 'Begining migration from schema % sql server to  schema %  postgres ',$1,lower($1);

        command:= 'DELETE  FROM msmov.error_table' ;
	EXECUTE command;
	command:= 'DELETE  FROM msmov.data_imported_table' ;
	EXECUTE command;
        
        command:= 'DROP SCHEMA IF EXISTS _'||$1||' CASCADE' ;
	EXECUTE command;
        IF $1<>'public' THEN
	command:= 'DROP SCHEMA IF EXISTS '||$1||' CASCADE' ;
	EXECUTE command;
        END IF;
        command:= 'CREATE SCHEMA _'||$1 ;
	EXECUTE command;
        IF $1<>'public' THEN 
	command:= 'CREATE SCHEMA '||$1 ;
	EXECUTE command;
	END IF;
        RAISE NOTICE 'Migrating tables ';
        --schema
        PERFORM msmov.create_ftables_import($1,$1,$2);
        PERFORM  msmov.create_tables_from_ft($1);

        IF $3=true THEN 
        RAISE NOTICE 'Migrating data  ';  
        --data
        PERFORM  msmov.import_data_alltables_by_portion($1,$5);

        END If;

        RAISE NOTICE 'Migrating identity column ';  
        --identity column 
        PERFORM msmov.create_ftidentitycolumn($1,$2);
        PERFORM msmov.import_identity_column($1);
        --set  sequences
        IF $3=true THEN 
        PERFORM msmov.set_value_identity_column($1);
        END IF;

        RAISE NOTICE 'Migrating constraints '; 
	--constraint
	--pk
	PERFORM msmov.create_ftpkey ($1,$2);
	PERFORM msmov.import_pk_tables($1);
	--fk
	PERFORM msmov.create_ftfkey($1,$2);
	PERFORM msmov.import_fk_tables ($1);
	--check
	PERFORM msmov.create_ftckey($1,$2);
	PERFORM msmov.import_ck_tables($1);
	--unique
	PERFORM msmov.create_ftukey($1,$2);
	PERFORM msmov.import_uk_tables($1);
	--null 
	PERFORM  msmov.create_ftnull ($1,$2);
	PERFORM msmov.import_null_tables($1);

	--default
	PERFORM  msmov.create_ftdefault ($1,$2);
	PERFORM msmov.import_default_tables($1);

        RAISE NOTICE 'Migrating indexs '; 
	--indexs
	PERFORM msmov.create_ftindex($1,$2);
	PERFORM msmov.import_indexs_tables($1);
         
        --unique indexs
	PERFORM msmov.create_ftuniqueindex($1,$2);
	PERFORM msmov.import_unique_indexs_tables($1);

	RAISE NOTICE 'Migrating views '; 


	--vistas
	PERFORM msmov.create_ftviews ($1,$2);
	PERFORM msmov.import_views($1);

         IF $4=true THEN
         --Converting to lower
        RAISE NOTICE 'Converting to lower'; 
        PERFORM msmov.conver_to_lower($1);
          
        END IF;

        IF $3=true THEN 
        RAISE NOTICE 'cleaning objects';         
        PERFORM msmov.clean_ft_schema($1);
        

        RAISE NOTICE 'Update statistics';         
        ANALYZE ;
        END IF;
                
	RETURN 1;

    
     EXCEPTION
			WHEN OTHERS THEN
                        
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,'ERROR',sqlerror||'-'||men||'-'||mendetail);
			RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
			RETURN 0;
	
       
     END;	
     $_$;


--
-- TOC entry 392 (class 1255 OID 73398)
-- Name: migrate_data(text, text, boolean); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION migrate_data(source_schema text, fdw_name text, lower boolean DEFAULT false) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
            
        RAISE NOTICE 'Begining migration only data from schema % sql server to  schema %  postgres ',$1,$1;
        --disable contraints and index
        PERFORM  msmov.disable_triggers(true,$1);
        PERFORM  msmov.disable_indexs(true,$1);

        --data
        PERFORM  msmov.import_data_alltables($1);

       
        
         --enable contraints and index
        PERFORM  msmov.disable_triggers(false,$1);
        PERFORM  msmov.disable_indexs(false,$1);
         
        RAISE NOTICE 'cleaning objects ';         
        PERFORM msmov.clean_ft_schema($1);

        RAISE NOTICE 'Update statistics';         
        ANALYZE ;
        IF $3 = true THEN
        PERFORM msmov.conver_to_lower($1);    
        END IF;    
	RETURN 1;

    
     EXCEPTION
			WHEN OTHERS THEN
                        
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,'ERROR',sqlerror||'-'||men||'-'||mendetail);
			RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
			RETURN 0;
	
       
     END;	
     $_$;


--
-- TOC entry 375 (class 1255 OID 73400)
-- Name: migrate_data_by_portion(text, text, integer, boolean); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION migrate_data_by_portion(source_schema text, fdw_name text, portion integer DEFAULT 500000, lower boolean DEFAULT false) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     BEGIN
            
        RAISE NOTICE 'Begining migration only data from schema % sql server to  schema %  postgres ',$1,$1;
        --disable contraints and index
        PERFORM  msmov.disable_triggers(true,$1);
        PERFORM  msmov.disable_indexs(true,$1);

        --data
        PERFORM  msmov.import_data_alltables_by_portion($1,$3);

       
        
         --enable contraints and index
        PERFORM  msmov.disable_triggers(false,$1);
        PERFORM  msmov.disable_indexs(false,$1);
         
        RAISE NOTICE 'cleaning objects ';         
        PERFORM msmov.clean_ft_schema($1);

        RAISE NOTICE 'Update statistics';         
        ANALYZE ;

        IF $4=true THEN
        PERFORM msmov.conver_to_lower($1); 
        END IF;        
	RETURN 1;

    
     EXCEPTION
			WHEN OTHERS THEN
                        
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,'ERROR',sqlerror||'-'||men||'-'||mendetail);
			RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
			RETURN 0;
	
       
     END;	
     $_$;


--
-- TOC entry 345 (class 1255 OID 47693)
-- Name: set_value_identity_column(text); Type: FUNCTION; Schema: msmov; Owner: -
--

CREATE FUNCTION set_value_identity_column(p_schema text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
     DECLARE
     tab record;
     tmp text;
     command text;
     men text;   
     mendetail text;
     sqlerror text;
     cnt int :=0;
     seq_name text;
     max_value bigint;
     BEGIN
        command := 'SELECT  tab, col FROM _'||$1||'._identity_column ';
        FOR tab IN EXECUTE command  LOOP
                 
                --create sequence
                seq_name := $1||'.'||tab.tab||'_'||tab.col||'_seq';
                command := 'SELECT max("'||tab.col||'") FROM '||$1||'."'||tab.tab||'"';
                EXECUTE command into max_value;
                IF max_value is not null THEN
                RAISE NOTICE 'SETTING SEQUENCE VALUE %', tab.tab;
                command := 'SELECT setval('''||seq_name||''','||max_value::text||')';
                --EXECUTE command;
                BEGIN
                EXECUTE command;
		EXCEPTION
			WHEN OTHERS THEN
			RAISE NOTICE 'command: %', command;
			GET STACKED DIAGNOSTICS  men = MESSAGE_TEXT,mendetail = PG_EXCEPTION_DETAIL,sqlerror=RETURNED_SQLSTATE;
                        cnt:=cnt-1;
			RAISE NOTICE 'Error %, %,% ',sqlerror,men,mendetail;
                        INSERT INTO msmov.error_table (id,date_time,command,error) VALUES ($1,current_timestamp::timestamp without time zone ,command,sqlerror||'-'||men||'-'||mendetail);
		END;
		cnt:=cnt+1;
		end if;	 

       END LOOP; 
       RAISE NOTICE 'TOTAL SEQUENCES SET : %',cnt; 
       RETURN cnt;
     END;	
     $_$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 207 (class 1259 OID 28299)
-- Name: data_imported_table; Type: TABLE; Schema: msmov; Owner: -
--

CREATE TABLE data_imported_table (
    id text,
    date_time timestamp without time zone,
    tab text,
    cnt integer
);


--
-- TOC entry 206 (class 1259 OID 28127)
-- Name: error_table; Type: TABLE; Schema: msmov; Owner: -
--

CREATE TABLE error_table (
    id text,
    date_time timestamp without time zone,
    command text,
    error text
);


--
-- TOC entry 3376 (class 0 OID 0)
-- Dependencies: 206
-- Name: TABLE error_table; Type: COMMENT; Schema: msmov; Owner: -
--

COMMENT ON TABLE error_table IS 'store error from migration process';


-- Completed on 2018-02-16 16:22:51 -03

--
-- PostgreSQL database dump complete
--

SET search_path to DEFAULT;


