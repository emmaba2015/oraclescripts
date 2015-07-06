set head off
set pages 0
set long 9999999
spool tablespaces.sql
select 'select dbms_metadata.get_ddl(''TABLESPACE'',''' ||  tablespace_name || ''') from dual;' from dba_tablespaces;
spool off