--Разкоментируйте и выполните операторы drop/create schema при необходимости полной очистки подсистемы хранения
--drop schema if exists public cascade;
--create schema public;

--Установка расширения TIMESCALEDB
--Оператор должен быть первым в сессии после соединения с PostgreSQL
CREATE EXTENSION IF NOT EXISTS timescaledb;

--Установка расширения TABLEFUNC
CREATE EXTENSION IF NOT EXISTS tablefunc;

-- Удаление объектов базы данных
drop function if exists test.load_measurements(offset_interval interval);
drop view if exists test.parsed_messages_ordered;
drop view if exists test.parsed_messages;
drop table if exists test.messages;
drop function if exists public.get_time(body jsonb);
drop function if exists public.get_class(body jsonb);
drop function if exists public.get_mea_id(key text, ind smallint);
drop function if exists public.get_dev_id(topic text);
drop function if exists public.get_mea_community(key text);
drop function if exists public.get_mea_id(key text);
drop table if exists test.load_log;
drop table if exists public.measurements;
drop table if exists public.reg_devices;
drop table if exists public.reg_measurements;
-- Удаление объектов базы данных, созданных динамически (таблицы и последовательности схемы public)
do $$ 
declare
 dr record;
begin 
 for dr in select table_name, table_schema from INFORMATION_SCHEMA.TABLES where table_schema = 'public'
 loop
  RAISE NOTICE '%', format('drop table if exists %I.%I cascade;', dr.table_schema, dr.table_name);  
  EXECUTE format('drop table %I.%I cascade;', dr.table_schema, dr.table_name);
 end loop;

 for dr in select sequence_name, sequence_schema from INFORMATION_SCHEMA.SEQUENCES where sequence_schema = 'public'
 loop
  RAISE NOTICE '%', format('drop sequence if exists %I.%I;', dr.sequence_schema, dr.sequence_name);  
  EXECUTE format('drop sequence if exists %I.%I;', dr.sequence_schema, dr.sequence_name);
 end loop;
end $$;


--Cправочник устройств.
--Заполняется автоматически при вызове функции "get_dev_id()".
create table public.reg_devices (
 dev_id      smallserial,
 dev_topic   text not null,
 primary key (dev_id)
);

--Функция получения времени измерения
--TODO: При (body->>'StartDate')::timestamptz время съезжает на 3 часа (пока оставил по-старому)
--TODO: Формат "2025-06-11T10:01:14.000Z" для PostgreSQL по-умолчанию не зашел
--TODO: Текущий вариант удаляет "T" из середины и "000Z" с конца
--TODO: Надо разбираться
create or replace function public.get_time(body jsonb) RETURNS timestamptz AS $$
 --SELECT (body->>'StartDate')::timestamptz;
 SELECT regexp_replace(body->>'StartDate'::text, '(....-..-..)T(..:..:..).*' , '\1 \2')::timestamptz;
$$ LANGUAGE SQL;

--Функция получения ClassId измерения
create or replace function public.get_class(body jsonb) RETURNS text AS $$
    SELECT body->>'ClassId';
$$ LANGUAGE SQL;

--Функция авторегистрации и получения идентификатора датчика
create or replace function public.get_dev_id(topic text) RETURNS smallint
AS $$
DECLARE
 device_id   smallint;
BEGIN
 select dev_id into device_id from reg_devices where dev_topic = topic;
 if not found then 
  WITH inserted AS (
    INSERT INTO reg_devices(dev_topic)
    VALUES (topic)
    RETURNING dev_id
  )
  SELECT dev_id INTO device_id FROM inserted;
 end if;
 RETURN device_id;
END;
$$ LANGUAGE plpgsql;

--Функция получения вида измерения
create or replace function public.get_mea_community(key text) RETURNS text AS $$
    SELECT regexp_replace(key,'^(.+)([A-Z]$|[A-Z][\d]$|.[\d]_[\d]$|[A-Z]_[\d]$)','\1');
$$ LANGUAGE SQL;
