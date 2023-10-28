# 1.Создание виртуальной машины и кластера PostgreSQL
*1.1.Создать инстанс ВМ с 2 ядрами и 4 Гб ОЗУ и SSD 10GB*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_14.png)
```
PS C:\Users\Egor> type C:\Users\Egor\.ssh\id_ed25519.pub | clip
PS C:\Users\Egor> ssh ssh-rsa@158.160.40.60
The authenticity of host '158.160.40.60 (158.160.40.60)' can't be established.
ECDSA key fingerprint is SHA256:ZXlLeVO1BqdBhTrI+JQdL5mbXy51otQwJLMm0wqunKA.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '158.160.40.60' (ECDSA) to the list of known hosts.
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-87-generic x86_64)
```
*1.2.Установить на него PostgreSQL 15 с дефолтными настройками*
```
ssh-rsa@lesson6:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@lesson6:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log

ssh-rsa@lesson6:~$ sudo -u postgres psql
could not change directory to "/home/ssh-rsa": Permission denied
psql (15.4 (Ubuntu 15.4-2.pgdg22.04+1))
Type "help" for help.
```
# 2.Тестирование с помощью pgbench инстанса с дефолтными настройками
*2.1.Создать БД для тестов: выполнить pgbench -i postgres*
```
postgres=# CREATE DATABASE db_for_pgbench;
CREATE DATABASE

postgres=# \c db_for_pgbench
You are now connected to database "db_for_pgbench" as user "postgres".
db_for_pgbench=# ALTER ROLE postgres WITH PASSWORD '123';
ALTER ROLE

db_for_pgbench=# \q

ssh-rsa@lesson6:~$ pgbench -i -U postgres -h localhost -p 5432  db_for_pgbench
Password:
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.03 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 1.19 s (drop tables 0.00 s, create tables 0.01 s, client-side generate 0.87 s, vacuum 0.03 s, primary keys 0.28 s).
```
*2.2.Запустить pgbench -c8 -P 6 -T 60 -U postgres postgres*
```
ssh-rsa@lesson6:~$ pgbench -c8 -P 6 -T 60 -U postgres -h localhost -p 5432 db_for_pgbench
Password:
pgbench (15.4 (Ubuntu 15.4-2.pgdg22.04+1))
starting vacuum...end.
progress: 6.0 s, 756.7 tps, lat 10.371 ms stddev 5.930, 0 failed
progress: 12.0 s, 543.7 tps, lat 14.739 ms stddev 12.185, 0 failed
progress: 18.0 s, 645.2 tps, lat 12.345 ms stddev 12.072, 0 failed
progress: 24.0 s, 649.0 tps, lat 12.373 ms stddev 9.707, 0 failed
progress: 30.0 s, 756.2 tps, lat 10.583 ms stddev 7.478, 0 failed
progress: 36.0 s, 680.5 tps, lat 11.749 ms stddev 33.639, 0 failed
progress: 42.0 s, 729.8 tps, lat 10.965 ms stddev 7.007, 0 failed
progress: 48.0 s, 642.5 tps, lat 12.426 ms stddev 12.938, 0 failed
progress: 54.0 s, 510.2 tps, lat 15.715 ms stddev 15.447, 0 failed
progress: 60.0 s, 876.3 tps, lat 9.122 ms stddev 5.306, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 40748
number of failed transactions: 0 (0.000%)
latency average = 11.761 ms
latency stddev = 14.293 ms
initial connection time = 100.531 ms
tps = 680.052594 (without initial connection time)
```
# 3.Тестирование с помощью pgbench инстанса с кастомными настройками
*3.1.Применить параметры настройки PostgreSQL из прикрепленного к материалам занятия файла*
```
ssh-rsa@lesson6:~$ cd /etc/postgresql/15/main
ssh-rsa@lesson6:/etc/postgresql/15/main$ sudo -u  postgres nano postgresql.conf
ssh-rsa@lesson6:/etc/postgresql/15/main$

ssh-rsa@lesson6:/etc/postgresql/15/main$ sudo systemctl stop postgresql@15-main
ssh-rsa@lesson6:/etc/postgresql/15/main$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 down   postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log

ssh-rsa@lesson6:/etc/postgresql/15/main$ sudo pg_ctlcluster 15 main restart
ssh-rsa@lesson6:/etc/postgresql/15/main$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```
*3.2.Протестировать заново*
```
ssh-rsa@lesson6:/etc/postgresql/15/main$ cd
ssh-rsa@lesson6:~$ pgbench -i -U postgres -h localhost -p 5432  db_for_pgbench
Password:
dropping old tables...
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.03 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.25 s (drop tables 0.01 s, create tables 0.01 s, client-side generate 0.12 s, vacuum 0.05 s, primary keys 0.06 s).
ssh-rsa@lesson6:~$ pgbench -c8 -P 6 -T 60 -U postgres -h localhost -p 5432 db_for_pgbench
Password:
pgbench (15.4 (Ubuntu 15.4-2.pgdg22.04+1))
starting vacuum...end.
progress: 6.0 s, 599.2 tps, lat 13.115 ms stddev 10.347, 0 failed
progress: 12.0 s, 756.7 tps, lat 10.552 ms stddev 6.960, 0 failed
progress: 18.0 s, 758.8 tps, lat 10.565 ms stddev 11.876, 0 failed
progress: 24.0 s, 694.5 tps, lat 11.520 ms stddev 10.403, 0 failed
progress: 30.0 s, 520.8 tps, lat 15.335 ms stddev 15.993, 0 failed
progress: 36.0 s, 679.8 tps, lat 11.781 ms stddev 10.262, 0 failed
progress: 42.0 s, 752.8 tps, lat 10.616 ms stddev 7.259, 0 failed
progress: 48.0 s, 791.8 tps, lat 10.116 ms stddev 6.219, 0 failed
progress: 54.0 s, 772.8 tps, lat 10.348 ms stddev 6.884, 0 failed
progress: 60.0 s, 555.5 tps, lat 14.396 ms stddev 14.054, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 41305
number of failed transactions: 0 (0.000%)
latency average = 11.603 ms
latency stddev = 10.247 ms
initial connection time = 97.128 ms
tps = 689.301834 (without initial connection time)
```
*3.3.Что изменилось и почему?*

number of transactions actually processed: 40748 -> 41305

number of failed transactions: 0 (0.000%) -> 0 (0.000%)

latency average = 11.761 ms -> 11.603 ms

latency stddev = 14.293 ms -> 10.247 ms

initial connection time = 100.531 ms -> 97.128 ms

tps = 680.052594 (without initial connection time) -> 689.301834 (without initial connection time)

Среднее количество транзакций в секунду (tps) возросло на 9, т.к. были увеличены лимиты используемых мощностей, прежде всего объем shared_buffers

# 4.Тестирование autovacuum
*4.1.Создать таблицу с текстовым полем и заполнить случайными или сгенерированными данным в размере 1 млн строк*
```
postgres=# DROP DATABASE db_for_pgbench;
DROP DATABASE
postgres=# CREATE DATABASE autovacuum_test;
CREATE DATABASE
postgres=# \c autovacuum_test;
You are now connected to database "autovacuum_test" as user "postgres".

autovacuum_test=# CREATE TABLE test_table (id serial, data text );
CREATE TABLE
autovacuum_test=# INSERT INTO test_table(data) SELECT generate_series::text||'a'::text FROM (SELECT *  FROM generate_series(1,1000000)) generate_series_table;
INSERT 0 1000000
autovacuum_test=# SELECT * FROM test_table ORDER BY id LIMIT 10;
 id | data
----+------
  1 | 1a
  2 | 2a
  3 | 3a
  4 | 4a
  5 | 5a
  6 | 6a
  7 | 7a
  8 | 8a
  9 | 9a
 10 | 10a
(10 rows)
```
*4.2.Посмотреть размер файла с таблицей*
```
autovacuum_test=# SELECT pg_size_pretty(pg_total_relation_size('test_table'));
 pg_size_pretty
----------------
 42 MB
(1 row)
```
*4.3.Пять раз обновить все строчки и добавить к каждой строчке любой символ*
*4.4.Посмотреть количество мертвых строчек в таблице и когда последний раз приходил автовакуум*
```
autovacuum_test=# UPDATE test_table SET data=data||'b'::text;UPDATE test_table SET data=data||'c'::text;UPDATE test_table SET data=data||'d'::text;UPDATE test_table SET data=data||'d'::text;UPDATE test_table SET data=data||'f'::text;SELECT * FROM test_table ORDER BY id LIMIT 10;SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs WHERE relname = 'test_table';
UPDATE 1000000
UPDATE 1000000
UPDATE 1000000
UPDATE 1000000
UPDATE 1000000
 id |   data
----+----------
  1 | 1abcddf
  2 | 2abcddf
  3 | 3abcddf
  4 | 4abcddf
  5 | 5abcddf
  6 | 6abcddf
  7 | 7abcddf
  8 | 8abcddf
  9 | 9abcddf
 10 | 10abcddf
(10 rows)

  relname   | n_live_tup | n_dead_tup | ratio% |        last_autovacuum
------------+------------+------------+--------+-------------------------------
 test_table |    1000000 |    1999085 |    199 | 2023-10-28 14:18:17.335066+00
(1 row)

```
*4.5.Подождать некоторое время, проверяя, прошел ли автовакуум*
```
autovacuum_test=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs WHERE relname = 'test_table';
  relname   | n_live_tup | n_dead_tup | ratio% |        last_autovacuum
------------+------------+------------+--------+-------------------------------
 test_table |    1000000 |          0 |      0 | 2023-10-28 14:19:16.994656+00
(1 row)
```
*4.6.Пять раз обновить все строчки и добавить к каждой строчке любой символ*
*4.7.Посмотреть размер файла с таблицей*
```
autovacuum_test=# UPDATE test_table SET data=data||'g'::text;UPDATE test_table SET data=data||'e'::text;UPDATE test_table SET data=data||'f'::text;UPDATE test_table SET data=data||'h'::text;UPDATE test_table SET data=data||'j'::text;SELECT * FROM test_table ORDER BY id LIMIT 10;SELECT pg_size_pretty(pg_total_relation_size('test_table'));
UPDATE 1000000
UPDATE 1000000
UPDATE 1000000
UPDATE 1000000
UPDATE 1000000
 id |     data
----+---------------
  1 | 1abcddfgefhj
  2 | 2abcddfgefhj
  3 | 3abcddfgefhj
  4 | 4abcddfgefhj
  5 | 5abcddfgefhj
  6 | 6abcddfgefhj
  7 | 7abcddfgefhj
  8 | 8abcddfgefhj
  9 | 9abcddfgefhj
 10 | 10abcddfgefhj
(10 rows)

 pg_size_pretty
----------------
 249 MB
(1 row)
```
*4.8.Отключить Автовакуум на конкретной таблице*
```
autovacuum_test=# ALTER TABLE test_table SET (autovacuum_enabled = off);
ALTER TABLE
```
*4.9.Десять раз обновить все строчки и добавить к каждой строчке любой символ*
*4.10.Посмотреть размер файла с таблицей*
```
autovacuum_test=# UPDATE test_table SET data=data||'b'::text;UPDATE test_table SET data=data||'c'::text;UPDATE test_table SET data=data||'d'::text;UPDATE test_table SET data=data||'d'::text;UPDATE test_table SET data=data||'f'::text;UPDATE test_table SET data=data||'g'::text;UPDATE test_table SET data=data||'e'::text;UPDATE test_table SET data=data||'f'::text;UPDATE test_table SET data=data||'h'::text;UPDATE test_table SET data=data||'j'::text;SELECT * FROM test_table ORDER BY id LIMIT 10;SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs WHERE relname = 'test_table';SELECT pg_size_pretty(pg_total_relation_size('test_table'));
UPDATE 1000000
UPDATE 1000000
UPDATE 1000000
UPDATE 1000000
UPDATE 1000000
UPDATE 1000000
UPDATE 1000000
UPDATE 1000000
UPDATE 1000000
UPDATE 1000000
 id |          data
----+-------------------------
  1 | 1abcddfgefhjbcddfgefhj
  2 | 2abcddfgefhjbcddfgefhj
  3 | 3abcddfgefhjbcddfgefhj
  4 | 4abcddfgefhjbcddfgefhj
  5 | 5abcddfgefhjbcddfgefhj
  6 | 6abcddfgefhjbcddfgefhj
  7 | 7abcddfgefhjbcddfgefhj
  8 | 8abcddfgefhjbcddfgefhj
  9 | 9abcddfgefhjbcddfgefhj
 10 | 10abcddfgefhjbcddfgefhj
(10 rows)

  relname   | n_live_tup | n_dead_tup | ratio% |        last_autovacuum
------------+------------+------------+--------+-------------------------------
 test_table |    1000000 |    9995870 |    999 | 2023-10-28 14:23:17.621321+00
(1 row)

 pg_size_pretty
----------------
 608 MB
(1 row)
```
*4.11.Объясните полученный результат*





*4.12.Не забудьте включить автовакуум*
```
autovacuum_test=# ALTER TABLE test_table SET (autovacuum_enabled = on);
ALTER TABLE
```
# 5.Задание со *
*5.1.Написать анонимную процедуру, в которой в цикле 10 раз обновятся все строчки в искомой таблице. Не забыть вывести номер шага цикла*
```

```
