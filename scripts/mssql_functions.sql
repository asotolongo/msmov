--funciones necesarias

CREATE SCHEMA mssql;


SET search_path = mssql, pg_catalog;

CREATE FUNCTION add_text(text1 text, text2 text) RETURNS text
    LANGUAGE sql
    AS $$select text1||text2 ;$$;


CREATE FUNCTION add_text(text1 character varying, text2 character varying) RETURNS text
    LANGUAGE sql
    AS $$select text1||text2 ;$$;


 CREATE FUNCTION add_text(text1 text, text2 ANYELEMENT) RETURNS text
    LANGUAGE sql
    AS $$select text1||text2::text ;$$;




CREATE FUNCTION add_text(text1 character varying, text2 ANYELEMENT) RETURNS text
    LANGUAGE sql
    AS $$select text1||text2::text ;$$; 




CREATE FUNCTION dateadd(part character varying, value integer, dat date) RETURNS timestamp without time zone
    LANGUAGE plpgsql
    AS $$ 
DECLARE 
result timestamp;
command text;
dat_char character varying;
dat1 timestamp;

BEGIN
dat_char:= dat::character varying||' 00:00:00 ';
dat1:=dat_char::timestamp;
command:='select '''||dat1::text||'''::timestamp + interval '''||value||' '||part||'''';
begin
execute command into result;
EXCEPTION
WHEN OTHERS THEN
        RAISE EXCEPTION 'Error, datepat no support, % ',part;
end;
return result;
END;
$$;




CREATE FUNCTION dateadd(part character varying, value integer, dat time without time zone) RETURNS timestamp without time zone
    LANGUAGE plpgsql
    AS $$ 
DECLARE 
result timestamp;
command text;
dat_char character varying;
dat1 timestamp;

BEGIN
dat_char:= '1900-01-01 '||dat::character varying;
dat1:=dat_char::timestamp;
command:='select '''||dat1::text||'''::timestamp + interval '''||value||' '||part||'''';
begin
execute command into result;
EXCEPTION
WHEN OTHERS THEN
        RAISE EXCEPTION 'Error, datepat no support, % ',part;
end;
return result;
END;
$$;




CREATE FUNCTION dateadd(part character varying, value integer, dat timestamp without time zone) RETURNS timestamp without time zone
    LANGUAGE plpgsql
    AS $$ 
DECLARE 
result timestamp;
command text;

BEGIN
command:='select '''||dat::text||'''::timestamp + interval '''||value||' '||part||'''';
begin
execute command into result;
EXCEPTION
WHEN OTHERS THEN
        RAISE EXCEPTION 'Error, datepat no support, % ',part;
end;
return result;
END;
$$;



CREATE FUNCTION datediff(part character varying, dat1 date, dat2 date) RETURNS integer
    LANGUAGE plpgsql
    AS $$ 
DECLARE 
result bigint;
dat_char character varying;
dat11 timestamp without time zone;
dat22 timestamp without time zone;
BEGIN
dat_char:= dat1::character varying||' 00:00:00 ';
dat11:=dat_char::timestamp;
dat_char:= dat2::character varying||' 00:00:00 ';
dat22:=dat_char::timestamp;

IF part='second' THEN
 result:=EXTRACT(epoch FROM dat22)-EXTRACT(epoch FROM dat11)  ;
 return abs(result);
END IF;

IF part='minute' THEN
 result:=ceil((EXTRACT(epoch FROM dat22)-EXTRACT(epoch FROM dat11))/60::real)  ;
 return abs(result);
END IF;

IF part='hour' THEN
 result:=ceil((EXTRACT(epoch FROM dat22)-EXTRACT(epoch FROM dat11))/3600)  ;
 return abs(result);
END IF;

IF part='day' THEN
 result:=dat22::date-dat11::date  ;
 return abs(result);
END IF;

IF part='month' THEN
 result:=ceil((dat22::date-dat11::date)/30::real)  ;
 return abs(result);
END IF;

IF part='year' THEN
 result:=ceil((dat22::date-dat11::date)/365::real)  ;
 return abs(result);
END IF;

RAISE EXCEPTION 'no support for % datepart', part;

END;
$$;



CREATE FUNCTION datediff(part character varying, dat1 time without time zone, dat2 time without time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$ 
DECLARE 
result bigint;
dat_char character varying;
dat11 time without time zone;
dat22 time without time zone;
BEGIN
dat_char:= '1900-01-01 '||dat1::character varying;
dat11:=dat_char::timestamp;
dat_char:= '1900-01-01 '||dat2::character varying;
dat22:=dat_char::timestamp;

IF part='second' THEN
 result:=EXTRACT(epoch FROM dat22)-EXTRACT(epoch FROM dat11)  ;
 return abs(result);
END IF;

IF part='minute' THEN
 result:=ceil((EXTRACT(epoch FROM dat22)-EXTRACT(epoch FROM dat11))/60::real)  ;
 return abs(result);
END IF;

IF part='hour' THEN
 result:=ceil((EXTRACT(epoch FROM dat22)-EXTRACT(epoch FROM dat11))/3600)  ;
 return abs(result);
END IF;

IF part='day' THEN
 return 0;
END IF;

IF part='month' THEN
 return 0;
END IF;

IF part='year' THEN
  return 0;
END IF;

RAISE EXCEPTION 'no support for % datepart', part;

END;
$$;




CREATE FUNCTION datediff(part character varying, dat1 timestamp without time zone, dat2 timestamp without time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$ 
DECLARE 
result bigint;

BEGIN

IF part='second' THEN
 result:=EXTRACT(epoch FROM dat2)-EXTRACT(epoch FROM dat1)  ;
 return abs(result);
END IF;

IF part='minute' THEN
 result:=ceil((EXTRACT(epoch FROM dat2)-EXTRACT(epoch FROM dat1))/60::real)  ;
 return abs(result);
END IF;

IF part='hour' THEN
 result:=ceil((EXTRACT(epoch FROM dat2)-EXTRACT(epoch FROM dat1))/3600)  ;
 return abs(result);
END IF;

IF part='day' THEN
 result:=dat2::date-dat1::date  ;
 return abs(result);
END IF;

IF part='month' THEN
 result:=ceil((dat2::date-dat1::date)/30::real)  ;
 return abs(result);
END IF;

IF part='year' THEN
 result:=ceil((dat2::date-dat1::date)/365::real)  ;
 return abs(result);
END IF;
RAISE EXCEPTION 'no support for % datepart', part;
END;
$$;



CREATE FUNCTION datefromparts(y integer, m integer, d integer) RETURNS date
    LANGUAGE sql
    AS $$select make_date(y, m, d)  ;$$;




CREATE FUNCTION datename(part character varying, dat date) RETURNS character varying
    LANGUAGE plpgsql
    AS $$ 
DECLARE 
result character varying;
dat_char character varying;
dat1 timestamp;
BEGIN
dat_char:= dat::character varying||' 00:00:00 ';
dat1:=dat_char::timestamp;
IF part='dayofyear' or part='dy'  THEN
 part:='doy';
END IF;
IF part='weekday' or part='dw' THEN
 result:=to_char(dat1, 'day')::character varying ;
 return result;
END IF;

IF part='second' THEN
 result:=(round(date_part ('second' , dat1 )))::character varying  ;
 return result;
END IF;

IF part='millisecond' THEN
 result:=floor((((date_part ('second' , dat1))::real-(round(date_part ('second' , dat1 ))::real))*1000)) ::character varying  ;
 return result;
END IF;

IF part='microsecond' THEN
 result:=floor((((date_part ('second' , dat1 ))::real-(floor(date_part ('second' , dat1 ))::real))*1000000)) ::character varying  ;
 return result;
END IF;


IF part='nanosecond' THEN
 result:=floor((((date_part ('second' , dat1 ))::real-(floor(date_part ('second' , dat1 ))::real))*1000000000)) ::character varying  ;
 return result;
END IF;

IF part='ISO_WEEK' THEN
part:='week';
END IF;



result:=date_part (part , dat1 )::character varying ;
return result;
END;
$$;



CREATE FUNCTION datename(part character varying, dat time without time zone) RETURNS character varying
    LANGUAGE plpgsql
    AS $$ 
DECLARE 
result character varying;
dat_char character varying;
dat1 timestamp;
BEGIN
dat_char:= '1900-01-01 '||dat::character varying;
dat1:=dat_char::timestamp;
IF part='dayofyear' or part='dy'  THEN
 part:='doy';
END IF;
IF part='weekday' or part='dw' THEN
 result:=to_char(dat1, 'day')::character varying ;
 return result;
END IF;

IF part='second' THEN
 result:=(round(date_part ('second' , dat1 )))::character varying  ;
 return result;
END IF;

IF part='millisecond' THEN
 result:=floor((((date_part ('second' , dat1))::real-(round(date_part ('second' , dat1 ))::real))*1000)) ::character varying  ;
 return result;
END IF;

IF part='microsecond' THEN
 result:=floor((((date_part ('second' , dat1 ))::real-(floor(date_part ('second' , dat1 ))::real))*1000000)) ::character varying  ;
 return result;
END IF;


IF part='nanosecond' THEN
 result:=floor((((date_part ('second' , dat1 ))::real-(floor(date_part ('second' , dat1 ))::real))*1000000000)) ::character varying  ;
 return result;
END IF;

IF part='ISO_WEEK' THEN
part:='week';
END IF;



result:=date_part (part , dat1 )::character varying ;
return result;
END;
$$;



CREATE FUNCTION datename(part character varying, dat timestamp without time zone) RETURNS character varying
    LANGUAGE plpgsql
    AS $$ 
DECLARE 
result character varying;
BEGIN
IF part='dayofyear' or part='dy'  THEN
 part:='doy';
END IF;
IF part='weekday' or part='dw' THEN
 result:=to_char(dat, 'day')::character varying ;
 return result;
END IF;

IF part='second' THEN
 result:=(round(date_part ('second' , dat )))::character varying  ;
 return result;
END IF;

IF part='millisecond' THEN
 result:=floor((((date_part ('second' , dat ))::real-(round(date_part ('second' , dat ))::real))*1000)) ::character varying  ;
 return result;
END IF;

IF part='microsecond' THEN
 result:=floor((((date_part ('second' , dat ))::real-(floor(date_part ('second' , dat ))::real))*1000000)) ::character varying  ;
 return result;
END IF;


IF part='nanosecond' THEN
 result:=floor((((date_part ('second' , dat ))::real-(floor(date_part ('second' , dat ))::real))*1000000000)) ::character varying  ;
 return result;
END IF;

IF part='ISO_WEEK' THEN
part:='week';
END IF;



result:=date_part (part , dat )::character varying ;
return result;
END;
$$;


CREATE FUNCTION datepart(part character varying, dat date) RETURNS character varying
    LANGUAGE plpgsql
    AS $$ 
DECLARE 
result character varying;
dat_char character varying;
dat1 date;
BEGIN
dat_char:= dat::character varying||' 00:00:00 ';
dat1:=dat_char::timestamp;
IF part='dayofyear' or part='dy'  THEN
 part:='doy';
END IF;
IF part='weekday' or part='dw' THEN
 result:=(date_part ('dow' , dat1 )+1)::character varying ;
 return result;
END IF;

IF part='second' THEN
 result:=(round(date_part ('second' , dat1 )))::character varying  ;
 return result;
END IF;

IF part='millisecond' THEN
 result:=floor((((date_part ('second' , dat1))::real-(round(date_part ('second' , dat1 ))::real))*1000)) ::character varying  ;
 return result;
END IF;

IF part='microsecond' THEN
 result:=floor((((date_part ('second' , dat1 ))::real-(floor(date_part ('second' , dat1 ))::real))*1000000)) ::character varying  ;
 return result;
END IF;


IF part='nanosecond' THEN
 result:=floor((((date_part ('second' , dat1 ))::real-(floor(date_part ('second' , dat1 ))::real))*1000000000)) ::character varying  ;
 return result;
END IF;

IF part='ISO_WEEK' THEN
part:='week';
END IF;



result:=date_part (part , dat1 )::character varying ;
return result;
END;
$$;



CREATE FUNCTION datepart(part character varying, dat time without time zone) RETURNS character varying
    LANGUAGE plpgsql
    AS $$ 
DECLARE 
result character varying;
dat_char character varying;
dat1 timestamp;
BEGIN
dat_char:= '1900-01-01 '||dat::character varying;
dat1:=dat_char::timestamp;
IF part='dayofyear' or part='dy'  THEN
 part:='doy';
END IF;
IF part='weekday' or part='dw' THEN
 result:=(date_part ('dow' , dat1 )+1)::character varying ;
 return result;
END IF;

IF part='second' THEN
 result:=(round(date_part ('second' , dat1 )))::character varying  ;
 return result;
END IF;

IF part='millisecond' THEN
 result:=floor((((date_part ('second' , dat1))::real-(round(date_part ('second' , dat1 ))::real))*1000)) ::character varying  ;
 return result;
END IF;

IF part='microsecond' THEN
 result:=floor((((date_part ('second' , dat1 ))::real-(floor(date_part ('second' , dat1 ))::real))*1000000)) ::character varying  ;
 return result;
END IF;


IF part='nanosecond' THEN
 result:=floor((((date_part ('second' , dat1 ))::real-(floor(date_part ('second' , dat1 ))::real))*1000000000)) ::character varying  ;
 return result;
END IF;

IF part='ISO_WEEK' THEN
part:='week';
END IF;



result:=date_part (part , dat1 )::character varying ;
return result;
END;
$$;




CREATE FUNCTION datepart(part character varying, dat timestamp without time zone) RETURNS character varying
    LANGUAGE plpgsql
    AS $$ 
DECLARE 
result character varying;

BEGIN

IF part='dayofyear' or part='dy'  THEN
 part:='doy';
END IF;
IF part='weekday' or part='dw' THEN
 result:=(date_part ('dow' , dat )+1)::character varying ;
 return result;
END IF;

IF part='second' THEN
 result:=(round(date_part ('second' , dat )))::character varying  ;
 return result;
END IF;

IF part='millisecond' THEN
 result:=floor((((date_part ('second' , dat))::real-(round(date_part ('second' , dat ))::real))*1000)) ::character varying  ;
 return result;
END IF;

IF part='microsecond' THEN
 result:=floor((((date_part ('second' , dat ))::real-(floor(date_part ('second' , dat ))::real))*1000000)) ::character varying  ;
 return result;
END IF;


IF part='nanosecond' THEN
 result:=floor((((date_part ('second' , dat ))::real-(floor(date_part ('second' , dat ))::real))*1000000000)) ::character varying  ;
 return result;
END IF;

IF part='ISO_WEEK' THEN
part:='week';
END IF;



result:=date_part (part , dat )::character varying ;
return result;
END;
$$;




CREATE FUNCTION datetimefromparts(y integer, m integer, d integer, h integer, mim integer, sec integer, mil integer) RETURNS timestamp without time zone
    LANGUAGE sql
    AS $$select make_timestamp(y, m, d, h , mim , (sec::text||'.'||mil::text)::double precision)  ;$$;




CREATE FUNCTION day(dat date) RETURNS integer
    LANGUAGE sql
    AS $$select extract ('day' from dat)::int  ;$$;




CREATE FUNCTION day(dat timestamp with time zone) RETURNS integer
    LANGUAGE sql
    AS $$select extract ('day' from dat)::int  ;$$;




CREATE FUNCTION getdate() RETURNS timestamp without time zone
    LANGUAGE sql
    AS $$select substring (current_timestamp::text from 0 for position('.' in current_timestamp::text))::timestamp ;$$;




CREATE FUNCTION getutcdate() RETURNS timestamp without time zone
    LANGUAGE sql
    AS $$ select substring((select now() at time zone 'utc')::text from 0 for position('.' in (select now() at time zone 'utc')::text))::timestamp ;$$;



CREATE FUNCTION month(dat date) RETURNS integer
    LANGUAGE sql
    AS $$select extract ('month' from dat)::int  ;$$;




CREATE FUNCTION month(dat timestamp with time zone) RETURNS integer
    LANGUAGE sql
    AS $$select extract ('month' from dat)::int  ;$$;



CREATE FUNCTION sysdatetime() RETURNS timestamp without time zone
    LANGUAGE sql
    AS $$select current_timestamp::timestamp without time zone ;$$;


CREATE FUNCTION sysdatetimeoffset() RETURNS timestamp with time zone
    LANGUAGE sql
    AS $$select current_timestamp ;$$;


CREATE FUNCTION sysutcdatetime() RETURNS timestamp without time zone
    LANGUAGE sql
    AS $$select now() at time zone 'utc';$$;


CREATE FUNCTION year(dat date) RETURNS integer
    LANGUAGE sql
    AS $$select extract ('year' from dat)::int  ;$$;


CREATE FUNCTION year(dat timestamp with time zone) RETURNS integer
    LANGUAGE sql
    AS $$select extract ('year' from dat)::int  ;$$;

CREATE FUNCTION newid() RETURNS uuid
    LANGUAGE sql
    AS $$select gen_random_uuid () ;$$;


 CREATE OPERATOR + (
  LEFTARG = text,
  RIGHTARG = text,
  PROCEDURE = mssql.add_text);


 CREATE OPERATOR + (
  LEFTARG = character varying,
  RIGHTARG = character varying,
  PROCEDURE = mssql.add_text);

 CREATE OPERATOR + (
  LEFTARG = text,
  RIGHTARG = ANYELEMENT,
  PROCEDURE = mssql.add_text);
 
 CREATE OPERATOR + (
  LEFTARG = character varying,
  RIGHTARG = ANYELEMENT,
  PROCEDURE = mssql.add_text);
--funciones necesarias
