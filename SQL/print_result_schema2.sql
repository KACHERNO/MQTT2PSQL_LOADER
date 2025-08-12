\set ECHO none

select 
 table_bytes,
 index_bytes,
 total_bytes, 
 total_seconds,
 total_rows,
 total_errors
from
(
select 
 sum(seconds) as total_seconds,
 sum(rows)    as total_rows,
 sum(errors)  as total_errors
from ( select seq,start,stop,extract('epoch' from stop)-extract('epoch' from start) as seconds,rows,errors from test.load_log )
)
,
(
select 
 sum(table_bytes) as table_bytes, 
 sum(index_bytes) as index_bytes,
 sum(total_bytes) as total_bytes
from
(
select 
 (hypertable_detailed_size(format('%I',hypertable_name))).table_bytes,
 (hypertable_detailed_size(format('%I',hypertable_name))).index_bytes,
 (hypertable_detailed_size(format('%I',hypertable_name))).total_bytes
from
 timescaledb_information.hypertables)
);
