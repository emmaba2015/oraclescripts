#Script para limpiar una base en caso de que falle algun procedimiento de import
select
trim(case
     when object_type = 'TABLE' then 'drop ' || object_type
          || ' ' || owner || '.' || object_name ||' cascade constraints'
     when object_type = 'PACKAGE BODY' then 'prompt PACKAGE BODY'||object_name
     when object_type = 'INDEX' then 'prompt INDEXES'||object_name
     when object_type = 'DATABASE LINK' then 'drop ' || object_type
          || ' ' || object_name
     else 'drop ' || object_type || ' ' || owner || '.' || object_name
     end || ';')
from dba_objects
where owner not in ('SYS', 'SYSTEM', 'SYSAUX', 'SYSMAN');