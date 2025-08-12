--Справочник результатов измерений.
--Заполняется автоматически при вызове функции "get_mea_id()".
create table public.reg_measurements (
 mea_id      smallserial,
 mea_key     text not null,
 mea_channel smallint,
 primary key (mea_id)
);

--Основная таблица для хранения результатов измерений.
--Атрибут "номер канала" не используется при хранении (будет сгенерирован динамически через представление).
create table public.measurements (
"time"   timestamp with time zone NOT NULL,
 dev_id  smallint NOT NULL,
 mea_id  smallint NOT NULL,
 value   real     DEFAULT 0 NOT NULL,
 foreign key (dev_id) references reg_devices(dev_id),
 foreign key (mea_id) references reg_measurements(mea_id)
);

-- Преобразование основной таблицы в ГИПЕРТАБЛИЦУ TIMESCALEDB
SELECT create_hypertable('measurements',by_range('time', INTERVAL '1 month'));


-- Функция авторегистрации и получения идентификатора измерения для результатов типа STRING и NUMBER
create or replace function public.get_mea_id(key text) RETURNS smallint
AS $$
DECLARE
 measure_id smallint;
BEGIN
 select mea_id into measure_id from reg_measurements where mea_key = key;
 if not found then 
 WITH inserted AS (
   INSERT INTO reg_measurements(mea_key)
   VALUES (key)
   RETURNING mea_id
 )
 SELECT mea_id INTO measure_id FROM inserted;
 end if;
 RETURN measure_id;
END;
$$ LANGUAGE plpgsql;

-- Функция авторегистрации и получения идентификатора измерения для результатов типа ARRAY
-- Задействуется перегрузка функций 
create or replace function public.get_mea_id(key text, ind smallint) RETURNS smallint
AS $$
DECLARE
 measure_id smallint;
BEGIN
 select mea_id into measure_id from reg_measurements where mea_key = key and mea_channel = ind;
 if not found then 
 WITH inserted AS (
   INSERT INTO reg_measurements(mea_key, mea_channel)
   VALUES (key, ind)
   RETURNING mea_id
 )
 SELECT mea_id INTO measure_id FROM inserted;
 end if;
 RETURN measure_id;
END;
$$ LANGUAGE plpgsql;
