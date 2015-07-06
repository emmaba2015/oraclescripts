DEFINE ORA_DB = &1
set linesize 150
Set pagesize 150 
set feedback off
set verify off
  
COL username HEADING 'Usuario' format A15
COL account_status HEADING 'Estado' format A16
COL lock_date HEADING 'Fecha|Bloqueo' JUSTIFY LEFT
COL expiry_date HEADING 'Fecha|Expiracion' format A10
COL default_tablespace HEADING 'Tablespace por|Defecto' format A15
COL created HEADING 'Creado'

spool Reporte_&ORA_DB\.txt
--Titulo del Reporte
PROMPT ----------------------------------------------------;
PROMPT RELEVAMIENTO BASE DE DATOS &ORA_DB;
PROMPT ----------------------------------------------------;

PROMPT#################################################################;
PROMPT Informacion de instancia 
PROMPT#################################################################;

column HOST_NAME format A10
select INSTANCE_NAME, HOST_NAME, VERSION, STARTUP_TIME, STATUS, ARCHIVER from v$instance;
column NAME format A10
column VALUE format A60
select NAME, VALUE from v$parameter where name='spfile';


PROMPT--Versión de Motor
select * from v$version;

PROMPT--Información de la base de datos
select DBID, NAME, CREATED, LOG_MODE from v$database;

PROMPT--Usuarios Conectados.
select count(*) from v$session where type <> 'BACKGROUND';

PROMPT--Usuarios Conectados activos
select count(*) from v$session where type <> 'BACKGROUND' and status = 'ACTIVE';

PROMPT--Cantidad de Usuarios Creados a nivel de base de datos
SELECT count(*) as "Cantidad Usuarios" FROM dba_users;

PROMPT#################################################################;
PROMPT Tablespaces y archivos
PROMPT#################################################################;

PROMPT--Archivos de Control
col name format A40
select * from v$controlfile;


PROMPT--Espacio total, ocupado y libre por datafile

set linesize 150
COLUMN file_name format A60
COLUMN free_space_mb format 999999.90
COLUMN allocated_mb format 999999.90
COLUMN used_mb format 999999.90

SELECT SUBSTR (df.NAME, 1, 60) file_name, df.bytes / 1024 / 1024 allocated_mb,
((df.bytes / 1024 / 1024) - NVL (SUM (dfs.bytes) / 1024 / 1024, 0))
used_mb,
NVL (SUM (dfs.bytes) / 1024 / 1024, 0) free_space_mb
FROM v$datafile df, dba_free_space dfs
WHERE df.file# = dfs.file_id(+)
GROUP BY dfs.file_id, df.NAME, df.file#, df.bytes
UNION ALL
select file_name, bytes/1024/1024 allocated_mb,user_bytes/1024/1024 used_mb,
((bytes/1024/1024) - (user_bytes/1024/1024)) free_space_mb
from dba_temp_files;
) 

PROMPT--Datafiles si son autoextensibles, tamaño actual, tamaño de maximo crecimiento
Select tablespace_name, file_name, autoextensible,bytes/(1024*1024) as TamMB,maxbytes/(1024*1024) as MaxMBCrec, 
(MAXBYTES-BYTES)/(1024*1024) as EspacioLibre,INCREMENT_BY from DBA_DATA_FILES order by tablespace_name, file_name;

PROMPT--Datafiles si el temfile es autoextensible, tamaño actual, tamaño de maximo crecimiento
Select tablespace_name, file_name, autoextensible,bytes/(1024*1024) as TamMB,maxbytes/(1024*1024) as MaxMBCrec, 
(MAXBYTES-BYTES)/(1024*1024) as EspacioLibre from dba_temp_files order by tablespace_name, file_name;


PROMPT--Tamaño de bloque y espacio definido en Tablespaces
select t.name, avg(block_size), Sum(bytes)/1048576 As MB from v$tablespace t, v$datafile d where d.ts#=t.ts# group by(t.name);

PROMPT--Para auditar espacio en tablespaces
SELECT definido.tablespace tablespace, definido.total total, TRUNC(NVL(usado.total,0),2) ocupado, TRUNC(NVL(usado.total*100/definido.total,0),2) "PORCENTAJE OCUP"
FROM (SELECT t.name AS tablespace, Sum(bytes)/1048576 AS total
FROM v$tablespace t, v$datafile d
WHERE d.ts#=t.ts#
GROUP BY (t.name)) definido,
(SELECT tablespace_name tablespace, sum(bytes)/1048576 AS total
FROM dba_segments
GROUP BY (tablespace_name)) usado
WHERE definido.tablespace=usado.tablespace(+);

PROMPT--Tablespace Temporal
select * from v$tempfile;

select tablespace_name, contents from dba_tablespaces where contents = 'TEMPORARY';

PROMPT--Tamaño físico del tablespace Temporal

--Si hay varios
--select tablespace_name, sum(bytes)/(1024*1024) Tammb from dba_temp_files group by tablespace_name;
--Si hay solo uno
select TABLESPACE_NAME, FILE_NAME, BYTES/(1024 * 1024) Tammb from dba_temp_files;


PROMPT--Tamaño ocupado en el Temporal
select ss.tablespace_name,sum((ss.used_blocks*ts.blocksize))/(1024*1024) EspUsadoMb 
from gv$sort_segment ss, sys.ts$ ts  
where ss.tablespace_name = ts.name 
group by ss.tablespace_name;

PROMPT--Redo Log Groups y miembros
col member format A35
select group#, status,member from v$logfile order by 1;

PROMPT--Redo Log Groups
select group#, sequence#, bytes/1048576 TamMb , members, status, archived,  to_char(FIRST_TIME, 'dd-mon-yy HH:MI:SS') from v$log;

select * from v$log;

PROMPT--Maximo numero de secuencia
select max(sequence#) from v$log_history where thread# = (select max(thread#) from v$log_history);


PROMPT#################################################################;
PROMPT Memoria
PROMPT#################################################################;

select name, value/1048576 as Mb from v$parameter where name in ('sga_max_size', 'pga_aggregate_target', 'db_cache_size', 'shared_pool_size','sga_target') order by name;

PROMPT--SGA Libre:
select pool, bytes MemLibre from v$sgastat where name = 'free memory';

PROMPT--SGA Ocupada. El numero sin valor es la suma de:fixed_sga,buffer_cache,log_buffer,shashared_io_pool
select pool, sum(bytes) MenOcupada from v$sgastat where name <> 'free memory' group by (pool);

PROMPT -- Muestra los ultimos redimensionamientos de SGA (Antiguos)
select * from v$sga_resize_ops;

PROMPT -- Muestra los redimensionamientos de SGA en progreso (Actualmente)
select * from V$SGA_CURRENT_RESIZE_OPS;

PROMPT--Espacio Ocupado por los pooles que se administran dinamicamente. 
select sum(current_size)/(1024*1024) from v$sga_dynamic_components;

PROMPT --Memoria dinamica en uso 
select * from v$sga_dynamic_free_memory;

PROMPT--Si se usa ASMM - Automatic Shared Memory Managment
col COMPONENT format A35
col LAST_OPER_TYPE format A15
col parameter format A20
select COMPONENT, CURRENT_SIZE, MIN_SIZE, MAX_SIZE,OPER_COUNT,LAST_OPER_TYPE, TO_CHAR(LAST_OPER_TIME, 'DD/MM/YYYY  HH24:MI:SS') from 
v$sga_dynamic_components;

PROMPT --PGA
PROMPT--Valor debería ser automatico si se utiliza la pga_aggregate_target
col name format a25
select name, value from v$parameter where name like 'workarea_size%';



PROMPT --Maximo de PGA utilizada por procesos
select max(pga_used_mem), max(pga_alloc_mem), max(pga_max_mem) from v$process;
select max(pga_used_mem)/(1024*1024) Used_Mb, max(pga_alloc_mem)/(1024*1024) alloc_Mb , max(pga_max_mem)/(1024*1024) max_mem_Mb from v$process;
SELECT username, program, pga_used_mem, pga_alloc_mem, pga_max_mem FROM v$process;



PROMPT#################################################################;
PROMPT MEDICIONES RELACIONADAS CON PERFORMANCE
PROMPT#################################################################;

PROMPT--Cantidad de espacio en megas cacheados para el Tablespace TMP
select tablespace_name, sum(bytes_cached)/(1024*1024) Tammb from v$temp_extent_pool group by tablespace_name;


PROMPT -- Consumo de Recursos (Vista resource_limit)
select * from v$resource_limit;

PROMPT--MEDICIONES RELACIONADAS CON PERFORMANCE

COLUMN sid FORMAT 99999
COLUMN serial# FORMAT 99999
COLUMN opname FORMAT A40
COLUMN %_comp FORMAT 999,999
set linesize 170

PROMPT--Operaciones que tienen una duración mayor a 6 segundos. 
SELECT sid, serial#, username, opname,target_desc, TO_CHAR(start_time, 'DD/MM/YYYY  HH24:MI:SS') AS "START", (sofar/totalwork)*100 AS "%_COMP", SQL_ADDRESS  FROM v$session_longops order by start_time;


PROMPT Predice el numero de lecturas fisicas para el tamaño de cache correspondiente a cada registro. 
PROMPT "physical read factor," es la tasa de lecturas estimadas por las lecturas actuales

SELECT size_for_estimate,size_factor,estd_physical_read_factor, estd_physical_reads
FROM V$DB_CACHE_ADVICE
WHERE name          = 'DEFAULT'
and block_size    = (select value from v$parameter where name = 'db_block_size')
AND advice_status = 'ON';

PROMPT
PROMPT Usuarios que tienen asignado como Temporary TBS un TBS que no es el temporal;

select u.username, t.tablespace_name 
from dba_users u, dba_tablespaces t 
where u.temporary_tablespace = t.tablespace_name
and t.contents <> 'TEMPORARY';

PROMPT
PROMPT Muestra un detalle del uso de tbs temporal por usuario y esta mejorada para tener el tamaño usado en bytes

select b.TABLESPACE, b.SEGFILE#, b.SEGBLK#, b.SEGTYPE,(b.BLOCKS * d.block_size) as TamBytes , a.sid, a.serial#, a.username, a.osuser, a.status 
from v$session a, v$sort_usage b, v$tablespace c, v$tempfile d
where
a.saddr = b.session_addr and
b.tablespace = c.name and
c.TS# = d.TS#;


PROMPT--Estadiscas acumuladas desde el inicio de la instancia. 
colum VALUE format 999999999999
col name format a37
select name, value from v$pgastat;

PROMPT --Consejero de PGA
PROMPT --Predice cómo el porcentaje de aciertos de caché y las estadisticas mostradas por la vista de rendimiento V $ PGASTAT
PROMPT se verían afectados si seambia el valor del parámetro PGA_AGGREGATE_TARGET.

select * from v$pga_target_advice order by pga_target_for_estimate;


PROMPT --Histograma de PGA
SELECT optimal_count, round(optimal_count*100/total,2) optimal_perc,
       onepass_count, round(onepass_count*100/total,2) onepass_perc,
       multipass_count, round(multipass_count*100/total,2) multipass_perc
FROM
 (SELECT decode(sum(total_executions),0,1,sum(total_executions)) total,
      sum(optimal_executions) optimal_count,
      sum(onepass_executions) onepass_count,
      sum(multipasses_executions) multipass_count
       FROM v$sql_workarea_histogram
       WHERE low_optimal_size > 64*1024);


PROMPT --Valor de la estadistica IOSEEKTIM IOTFRSPEED: IOSEEKTIM millisegundos, IOTFRSPEED bytes
col PVAL2 format a25
select * from aux_stats$;


PROMPT#################################################################;
PROMPT Relevamiento de Parametros de Inicio
PROMPT#################################################################;

col UPDATE_COMMENT format a20
col DESCRIPTION format a25
col DISPLAY_VALUE format a25
col NAME format a15
col DISPLAY_VALUE format a7
PROMPT -- db_file_multi%
select * from v$parameter where name like 'db_file_multi%';
PROMPT
PROMPT --db_block
select * from v$parameter where name like 'db_block%';
PROMPT
PROMPT -- optimizer_index_cost_adj
select * from v$parameter where name like 'optimizer_index_cost_adj';
PROMPT
PROMPT --optimizer
select * from v$parameter where name like 'optimizer%';
PROMPT
PROMPT --cursor
select * from v$parameter where name like 'cursor%';

PROMPT#################################################################;
PROMPT Maximo numero de secuencia de los archive logs
PROMPT#################################################################;

select max (sequence#) from v$log_history where RESETLOGS_CHANGE# = (select max(RESETLOGS_CHANGE#) from v$log_history);

PROMPT#################################################################;
PROMPT GETBACKUPINFO
PROMPT#################################################################;

set linesize 150
set pagesize 300
col session_key format 99999
col time_taken_display format a9
col OUTPUT_BYTES_DISPLAY format a12
col status format a10
select session_key, input_type, status, to_char(start_time,'yyyy-mm-dd hh24:mi') start_time,to_char(end_time,'yyyy-mm-dd hh24:mi') end_time, output_bytes_display, time_taken_display from v$rman_backup_job_details order by session_key asc;

spool off
exit

