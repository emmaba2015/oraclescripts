#DBA_REGISTRY displays information about all components in the database that are loaded into the component registry. The component registry tracks components that can be separately loaded into the Oracle Database. When a SQL script loads the PL/SQL packages and other database objects for a component into the database, the script uses the DBMS_REGISTRY package to record the component name, status, and version. If scripts are used to upgrade/downgrade the dictionary elements for the component, then those scripts also use the DBMS_REGISTRY package to provide status and version information.
col ACTION format a15
col NAMESPACE format a15
col version format a10
col COMMENTS format a42
col BUNDLE_SERIES format a20
col action_time format a30
select * from sys.registry$history;

SELECT comp_name, version, status FROM dba_registry;