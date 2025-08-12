\set ECHO none
select 
 table_bytes,
 index_bytes,
 total_bytes, 
 total_seconds,
 total_rows,
 total_errors
from 
hypertable_detailed_size('measurements'),
(
select 
 sum(seconds) as total_seconds,
 sum(rows)    as total_rows,
 sum(errors)  as total_errors,
 hypertable_size('measurements') as "Total Size"
from 
( select seq,start,stop,extract('epoch' from stop)-extract('epoch' from start) as seconds,rows,errors from test.load_log )
);

