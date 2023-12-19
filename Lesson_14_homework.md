# 0.Создание виртуальной машины и развертывание кластера PostgreSQL
*0.1. Создание виртуальной машины*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_42.png)
```
PS C:\Users\Egor> type C:\Users\Egor\.ssh\id_ed25519.pub | clip
PS C:\Users\Egor> ssh ssh-rsa@178.154.206.162
The authenticity of host '178.154.206.162 (178.154.206.162)' can't be established.
ECDSA key fingerprint is SHA256:pPjejF1dr5roeW8LiMn/4AXgoqLfnkC/NkV1jBkN2J8.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '178.154.206.162' (ECDSA) to the list of known hosts.
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-91-generic x86_64)
```
*0.2. Установка postgres*
```
ssh-rsa@lesson14:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@lesson14:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```
*0.3. Развертывание базы flights*
```
PS C:\Users\Egor> scp C:\Users\Egor\Downloads\demo-big-en\demo-big-en-20170815.sql ssh-rsa@178.154.206.162:/home/ssh-rsa
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
demo-big-en-20170815.sql                                                                                                                                                                                   100%  888MB   6.2MB/s   02:24
PS C:\Users\Egor> ssh ssh-rsa@178.154.206.162
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-91-generic x86_64)
ssh-rsa@lesson14:~$ ls
demo-big-en-20170815.sql
ssh-rsa@lesson14:~$ sudo chown -R postgres:postgres /home/ssh-rsa
ssh-rsa@lesson14:~$ sudo -u postgres psql -f demo-big-en-20170815.sql

ssh-rsa@lesson14:~$ sudo -u postgres psql
psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
Type "help" for help.

postgres=# \c demo;
You are now connected to database "demo" as user "postgres".
demo=# \dt
               List of relations
  Schema  |      Name       | Type  |  Owner
----------+-----------------+-------+----------
 bookings | aircrafts_data  | table | postgres
 bookings | airports_data   | table | postgres
 bookings | boarding_passes | table | postgres
 bookings | bookings        | table | postgres
 bookings | flights         | table | postgres
 bookings | seats           | table | postgres
 bookings | ticket_flights  | table | postgres
 bookings | tickets         | table | postgres
(8 rows)

demo=# SELECT relname, relpages, reltuples FROM pg_class WHERE relname IN ('aircrafts_data','airports_data','boarding_passes','bookings', 'flights', 'seats', 'ticket_flights', 'tickets');
     relname     | relpages |  reltuples
-----------------+----------+--------------
 ticket_flights  |    69933 | 8.391852e+06
 boarding_passes |    58279 | 7.925688e+06
 aircrafts_data  |        1 |            9
 flights         |     2624 |       214867
 airports_data   |        3 |          104
 seats           |        8 |         1339
 tickets         |    49415 | 2.949857e+06
 bookings        |    13447 |  2.11111e+06
(8 rows)
```

Самая большая таблица - ticket_flights, поэтому будем секционировать её

# 1.Секционирование таблицы
*1.1. Секционировать большую таблицу из демо базы flights*

Посмотрим на колонки таблицы

```
demo=# SELECT * FROM bookings.ticket_flights LIMIT 5;
   ticket_no   | flight_id | fare_conditions |  amount
---------------+-----------+-----------------+----------
 0005434184656 |     75694 | Economy         | 12200.00
 0005432919730 |     58820 | Economy         |  8900.00
 0005433400413 |     14926 | Economy         |  6700.00
 0005434120569 |    186261 | Economy         |  3200.00
 0005432382763 |    202948 | Economy         |  3300.00
(5 rows)

```

Секционируем её по fare_conditions. Предположим, что WHERE по этому полю может быть использовано при построении аналитических отчетов по выручке в разрезе класса обслуживания или в аэропорту при регистрации на соответсвующих классу обслуживанию стойках.

```
demo=# SELECT DISTINCT fare_conditions FROM bookings.ticket_flights;
 fare_conditions
-----------------
 Business
 Comfort
 Economy
(3 rows)

```

Возможны 3 варианта класса обслуживания. Секцию по умолчанию делать не будем, т.к. исходная таблица содержит CHECK на значение столбца fare_conditions:

```
CONSTRAINT ticket_flights_fare_conditions_check CHECK (((fare_conditions)::text = ANY (ARRAY[('Economy'::character varying)::text, ('Comfort'::character varying)::text, ('Business'::character varying)::text])))
```

Перед секционированием соберем план запроса и метрики его выполнения для трех запросов, чтобы сравнить с секционированным вариантом.

```
--- Запрашиваем все билеты класса Эконом
demo=# EXPLAIN ANALYZE  SELECT * FROM bookings.ticket_flights WHERE fare_conditions='Economy';
                                                         QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------
 Seq Scan on ticket_flights  (cost=0.00..174831.15 rows=7403012 width=32) (actual time=1.819..912.909 rows=7392231 loops=1)
   Filter: ((fare_conditions)::text = 'Economy'::text)
   Rows Removed by Filter: 999621
 Planning Time: 0.054 ms
 JIT:
   Functions: 2
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 0.170 ms, Inlining 0.000 ms, Optimization 0.131 ms, Emission 1.677 ms, Total 1.978 ms
 Execution Time: 1133.195 ms
(9 rows)

--- Запрашиваем билеты класса Эконом и Комфорт
demo=# EXPLAIN ANALYZE  SELECT * FROM bookings.ticket_flights WHERE fare_conditions='Comfort';
                                                               QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..128962.66 rows=143221 width=32) (actual time=297.601..729.924 rows=139965 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   ->  Parallel Seq Scan on ticket_flights  (cost=0.00..113640.56 rows=59675 width=32) (actual time=260.703..535.863 rows=46655 loops=3)
         Filter: ((fare_conditions)::text = 'Comfort'::text)
         Rows Removed by Filter: 2750629
 Planning Time: 0.062 ms
 JIT:
   Functions: 6
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 0.890 ms, Inlining 0.000 ms, Optimization 0.662 ms, Emission 18.179 ms, Total 19.731 ms
 Execution Time: 739.375 ms
(12 rows)

--- Запрашиваем класс, которого нет в таблице
demo=# EXPLAIN ANALYZE  SELECT * FROM bookings.ticket_flights WHERE fare_conditions='Test';
                                                           QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..114640.66 rows=1 width=32) (actual time=674.039..674.814 rows=0 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   ->  Parallel Seq Scan on ticket_flights  (cost=0.00..113640.56 rows=1 width=32) (actual time=628.275..628.276 rows=0 loops=3)
         Filter: ((fare_conditions)::text = 'Test'::text)
         Rows Removed by Filter: 2797284
 Planning Time: 0.067 ms
 JIT:
   Functions: 6
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 1.077 ms, Inlining 0.000 ms, Optimization 0.711 ms, Emission 18.723 ms, Total 20.511 ms
 Execution Time: 675.071 ms
(12 rows)
```

Выполняем секционирование:

```
---
--- Создаем секционированную таблицу
---
demo=# CREATE TABLE  bookings.ticket_flights_sec
(
    ticket_no character(13) NOT NULL,
    flight_id integer NOT NULL,
    fare_conditions character varying(10) NOT NULL,
    amount numeric(10,2) NOT NULL,
    CONSTRAINT ticket_flights_amount_check CHECK ((amount >= (0)::numeric)),
    CONSTRAINT ticket_flights_fare_conditions_check CHECK (((fare_conditions)::text = ANY (ARRAY[('Economy'::character varying)::text, ('Comfort'::character varying)::text, ('Business'::character varying)::text])))
) PARTITION BY LIST (fare_conditions);
CREATE TABLE
---
--- Создаем секции таблицы
---
demo=# CREATE TABLE bookings.ticket_flights_economy PARTITION OF bookings.ticket_flights_sec FOR VALUES IN ('Economy');
CREATE TABLE
demo=# CREATE TABLE bookings.ticket_flights_comfort PARTITION OF bookings.ticket_flights_sec FOR VALUES IN ('Comfort');
CREATE TABLE
demo=# CREATE TABLE bookings.ticket_flights_business PARTITION OF bookings.ticket_flights_sec FOR VALUES IN ('Business');
CREATE TABLE
---
--- Вставляем значения из исходной таблицы
---
demo=# INSERT INTO bookings.ticket_flights_sec SELECT * FROM  bookings.ticket_flights;
INSERT 0 8391852
---
--- Проверяем, что все все записи вставлены (должно быть 0 строк)
---
demo=# SELECT * FROM bookings.ticket_flights EXCEPT SELECT * FROM bookings.ticket_flights_sec;
 ticket_no | flight_id | fare_conditions | amount
-----------+-----------+-----------------+--------
(0 rows)
---
--- Удаляем исходную таблицу
---
demo=# DROP TABLE bookings.ticket_flights;
ERROR:  cannot drop table ticket_flights because other objects depend on it
DETAIL:  constraint boarding_passes_ticket_no_fkey on table boarding_passes depends on table ticket_flights
HINT:  Use DROP ... CASCADE to drop the dependent objects too.
--- Но перед этим удалим CONSTRAINT
demo=# ALTER TABLE bookings.boarding_passes  DROP CONSTRAINT boarding_passes_ticket_no_fkey;
ALTER TABLE
demo=# DROP TABLE bookings.ticket_flights;
DROP TABLE
---
--- Переименовываем секционированную таблицу
---
demo=# ALTER TABLE bookings.ticket_flights_sec RENAME TO ticket_flights;
ALTER TABLE
---
--- Восстанавливаем CONSTRAITs
---
demo=# ALTER TABLE bookings.ticket_flights
    ADD CONSTRAINT ticket_flights_flight_id_fkey FOREIGN KEY (flight_id) REFERENCES bookings.flights(flight_id);
ALTER TABLE
demo=# ALTER TABLE bookings.ticket_flights
    ADD CONSTRAINT ticket_flights_ticket_no_fkey FOREIGN KEY (ticket_no) REFERENCES bookings.tickets(ticket_no);
ALTER TABLE
demo=# ALTER TABLE ONLY ticket_flights
demo-# ADD CONSTRAINT ticket_flights_pkey PRIMARY KEY (ticket_no, flight_id);
ERROR:  unique constraint on partitioned table must include all partitioning columns
DETAIL:  PRIMARY KEY constraint on table "ticket_flights" lacks column "fare_conditions" which is part of the partition key.
--- Делаем PK на каждой отдельной секции
demo=# ALTER TABLE ONLY bookings.ticket_flights_economy ADD CONSTRAINT ticket_flights_pkey_economy PRIMARY KEY (ticket_no, flight_id);
ALTER TABLE
demo=# ALTER TABLE ONLY bookings.ticket_flights_comfort ADD CONSTRAINT ticket_flights_pkey_comfort PRIMARY KEY (ticket_no, flight_id);
ALTER TABLE
demo=# ALTER TABLE ONLY bookings.ticket_flights_business ADD CONSTRAINT ticket_flights_pkey_business PRIMARY KEY (ticket_no, flight_id);
ALTER TABLE
demo=# ALTER TABLE ONLY bookings.boarding_passes
demo-# ADD CONSTRAINT boarding_passes_ticket_no_fkey FOREIGN KEY (ticket_no, flight_id) REFERENCES bookings.ticket_flights(ticket_no, flight_id);
ERROR:  there is no unique constraint matching given keys for referenced table "ticket_flights"
--- Но все равно остается проблема с CONSTRAIT для таблицы, у который данный PK является FK. В данном моменте пожертвуем консистентностью данных между таблицами
```

Делаем запросы к ссекционированной таблице, сравниваем с исходными

