--Представление для загрузки тестовых данных
create or replace view test.parsed_messages as
select
 time as load_time, 
 get_time(body) as real_time,
 get_class(body) as class_id,
 get_dev_id(topic) as dev_id,
-- get_mea_id((r).key) as mea_id,
 (r).key as mea_key,
 get_mea_community((r).key) as mea_community,
 regexp_replace((r).value::text,'"','','g')::numeric as value
from
 (select time, topic, body, jsonb_each(body) as r from test.messages)
where 
 jsonb_typeof((r).value) in ('string','number') and (r).key not in ('ClassId','StartDate');

--Представление для загрузки тестовых данных с номером канала измерения (номер щупа)
create or replace view test.parsed_messages_ordered as
select
 parsed_messages.*,
 ROW_NUMBER() OVER( PARTITION BY load_time, dev_id, mea_community ) - 1 as mea_channel
from 
 test.parsed_messages;

--Функция преобразования и загрузки данных в подсистему хранения с разными таблицами
drop function if exists test.load_measurements(offset_interval interval);
create or replace function test.load_measurements(offset_interval interval default (interval '0 days')) RETURNS text
AS $$
DECLARE
 dr test.parsed_messages_ordered%rowtype;
 start_time  timestamp with time zone;
 stop_time   timestamp with time zone;
 row_counter integer := 0;
 err_counter integer := 0;
 ins_result  integer := 0;
BEGIN
 start_time := clock_timestamp();
 FOR dr IN SELECT * FROM test.parsed_messages_ordered
  LOOP
   DECLARE
   BEGIN
     select mea_insert(dr.mea_community, dr.real_time + offset_interval, dr.dev_id, dr.mea_channel::smallint, dr.value::real) into ins_result;
     if ins_result = 0 
     then
      row_counter := row_counter + 1;
     else
      err_counter := err_counter + 1;
     end if;
   EXCEPTION WHEN OTHERS
    THEN
     err_counter := err_counter + 1;
   END;
  END LOOP;
 stop_time := clock_timestamp();
 insert into test.load_log (start, stop, rows, errors) values (start_time, stop_time, row_counter, err_counter);
 RETURN 'Inserted: '||row_counter||', Errors: '||err_counter||'.';
END;
$$ LANGUAGE plpgsql;
