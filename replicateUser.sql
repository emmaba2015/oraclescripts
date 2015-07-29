#Script para generar los DDL para crear un usuario exactamente igual que en la base de origen
DEFINE USER = &1
set head off
set pages 0
set long 9999999
spool userDDL.sql
SELECT DBMS_METADATA.GET_DDL('USER', &USER) || '/' DDL
FROM dual
UNION ALL
SELECT DBMS_METADATA.GET_GRANTED_DDL('ROLE_GRANT', &USER) || '/' DDL
FROM Dual
UNION ALL
SELECT DBMS_METADATA.GET_GRANTED_DDL('SYSTEM_GRANT', &USER) || '/' DDL
FROM Dual
UNION ALL
SELECT DBMS_METADATA.GET_GRANTED_DDL('OBJECT_GRANT', &USER) || '/' DDL
FROM Dual;
spool off
