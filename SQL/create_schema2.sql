--Функция сохранения результата измерения.
--Таблица и Гипертаблица создаются динамически.
drop function if exists mea_insert(p_mea_community text, p_time timestamptz, p_dev_id smallint, p_channel smallint, p_value real);
create or replace function mea_insert(p_mea_community text, p_time timestamptz, p_dev_id smallint, p_channel smallint, p_value real) RETURNS smallint
AS $$
DECLARE
 step smallint := 0;
 err_message text    := '';
BEGIN
 SELECT 1 INTO step FROM information_schema.tables WHERE table_schema='public' and table_name = p_mea_community;
 if not found then
  BEGIN
   EXECUTE format('create table %I (time timestamptz not null, dev_id smallint not null, channel smallint not null default 0, value real not null default 0);', p_mea_community);
   step := 1;
  EXCEPTION WHEN OTHERS 
   THEN 
    raise notice '%', step || ': ' || sqlerrm;
    RETURN -1;
  END;
 end if;
 SELECT 2 INTO step FROM timescaledb_information.hypertables WHERE hypertable_schema='public' and hypertable_name = p_mea_community;
 if not found then
  BEGIN
   EXECUTE format('select create_hypertable( %L, by_range( %L, INTERVAL %L ));', format('%I', p_mea_community), 'time', '1 month');
   step := 2;
  EXCEPTION WHEN OTHERS
   THEN 
    raise notice '%', step || ': ' || sqlerrm;
    RETURN -2;
  END;
 end if;
  BEGIN
   EXECUTE format('insert into %I values (%L,%L,%L,%L);', p_mea_community, p_time, p_dev_id, p_channel, p_value );
   step := 3;
  EXCEPTION WHEN OTHERS
   THEN 
    raise notice '%', step || ': ' || sqlerrm;
    RETURN 1;
  END;
 RETURN 0;
END;
$$ LANGUAGE plpgsql;
