--Разкоментируйте и выполните операторы drop/create schema при необходимости полной очистки подсистемы тестирования
--drop schema if exists test cascade;
--create schema test;

create schema if not exists test;


--Таблица для хранения тестовых сообщений, содержащих события измерений с реальных датчиков (полученных по протоколу MQTT)
create table test.messages (
    "time" timestamp with time zone DEFAULT now() NOT NULL,
    topic text NOT NULL,
    body jsonb NOT NULL
);


--Таблица-журнал операций для оценки времени загрузки
create table test.load_log (
    seq    smallserial,
    start  timestamp with time zone DEFAULT now() NOT NULL,
    stop   timestamp with time zone DEFAULT now() NOT NULL,
    rows   integer DEFAULT 0,
    errors integer DEFAULT 0
);

\copy test.messages( "time", topic, body ) FROM '../SQL/messages.csv' DELIMITER ',' CSV HEADER;
