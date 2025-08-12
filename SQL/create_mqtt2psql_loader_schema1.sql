-- Таблица для хранения событий для mqtt2psql_loader
create table events (
    "time"  timestamp with time zone DEFAULT now() NOT NULL,
    topic   text NOT NULL,
    payload jsonb NOT NULL
);

-- Преобразование таблицы для хранения событий в гипертаблицу TimeScaleDB
SELECT create_hypertable('events',by_range('time', INTERVAL '7 days'));

--DROP TRIGGER IF EXISTS after_insert_event ON events;
--DROP FUNCTION IF EXISTS event_after_insert();

--Функция (триггерная) переноса результатов измерений в подсистему хранения с единой таблицей
--Загружаются результаты типа 'string', 'number' и 'array'
CREATE OR REPLACE FUNCTION event_after_insert()
RETURNS TRIGGER AS $$
BEGIN
 INSERT INTO measurements ( time, dev_id, mea_id, value )
 SELECT  
  get_time(payload) as real_time,
  get_dev_id(topic) as dev_id,
  get_mea_id((r).key) as mea_id,
  regexp_replace((r).value::text,'"','','g')::real as value
 FROM
 (select NEW.topic, NEW.payload, jsonb_each(NEW.payload) as r)
 WHERE
  jsonb_typeof((r).value) in ('string','number') 
 AND 
 (r).key not in ('ClassId','StartDate')
 UNION
 SELECT  
  real_time,
  dev_id,
  get_mea_id (mea_key, (row_number() over (PARTITION BY real_time, dev_id) - 1)::smallint ) as mea_id,
  regexp_replace(val::text,'"','','g')::real as value
 FROM 
 ( 
  SELECT get_time(payload) as real_time, get_dev_id(topic) as dev_id, (r).key as mea_key, jsonb_array_elements((r).value) as val
  FROM (select NEW.topic, NEW.payload, jsonb_each(NEW.payload) as r)
  WHERE jsonb_typeof((r).value) in ('array') AND (r).key not in ('ClassId','StartDate')
 )
 ;
 --
 RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер для таблицы событий
CREATE TRIGGER after_insert_event
AFTER INSERT ON events
FOR EACH ROW
EXECUTE FUNCTION event_after_insert();
