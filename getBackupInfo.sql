set linesize 150
set pagesize 300
col session_key format 99999
col time_taken_display format a9
col OUTPUT_BYTES_DISPLAY format a12
col status format a10
select session_key, input_type, status, to_char(start_time,'yyyy-mm-dd hh24:mi') start_time,to_char(end_time,'yyyy-mm-dd hh24:mi') end_time, output_bytes_display, time_taken_display from v$rman_backup_job_details order by session_key asc;

