# 0.Создание виртуальной машины и развертывание кластера PostgreSQL
*0.1. Создание виртуальной машины*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_32.png)
```
PS C:\Users\Egor> type C:\Users\Egor\.ssh\id_ed25519.pub | clip
PS C:\Users\Egor> ssh ssh-rsa@158.160.111.168
The authenticity of host '158.160.111.168 (158.160.111.168)' can't be established.
ECDSA key fingerprint is SHA256:BGxIOpqD0ARENJ+sDyzOY7XHn5bF3S+Csr1LG5lqhbo.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '158.160.111.168' (ECDSA) to the list of known hosts.
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-89-generic x86_64)
```
*0.2. Установка PostgreSQL*
```
ssh-rsa@lesson12:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@lesson12:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```
# 1.Работа с индексами
*1.1. Создание тестовой БД и таблицы*
```
ssh-rsa@lesson12:~$ sudo -u postgres psql
could not change directory to "/home/ssh-rsa": Permission denied
psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
Type "help" for help.

postgres=# create database test_db;
CREATE DATABASE
postgres=# \c test_db
You are now connected to database "test_db" as user "postgres".
test_db=# CREATE TABLE test_table (id uuid, int_value integer, char_value character varying);
CREATE TABLE
test_db=# INSERT INTO public.test_table(id,int_value, char_value) SELECT gen_random_uuid(), generate_series, generate_series::character varying||'a'  FROM generate_series(1,1000);
INSERT 0 1000
test_db-# SELECT * FROM test_table WHERE id='6b7b4718-762e-444a-994c-320048fd0f2a';
                          QUERY PLAN
---------------------------------------------------------------
 Seq Scan on test_table  (cost=0.00..20.50 rows=1 width=24)
   Filter: (id = '6b7b4718-762e-444a-994c-320048fd0f2a'::uuid)
(2 rows)

```
*1.2. Создать индекс к какой-либо из таблиц вашей БД*
```
test_db=# CREATE INDEX id_index ON test_table (id);
CREATE INDEX
```
*1.3. Прислать текстом результат команды explain, в которой используется данный индекс*
```
test_db=# EXPLAIN
SELECT * FROM test_table WHERE id='6b7b4718-762e-444a-994c-320048fd0f2a';
                                 QUERY PLAN
----------------------------------------------------------------------------
 Index Scan using id_index on test_table  (cost=0.28..8.29 rows=1 width=24)
   Index Cond: (id = '6b7b4718-762e-444a-994c-320048fd0f2a'::uuid)
(2 rows)
```
*1.4. Реализовать индекс для полнотекстового поиска*
```
test_db=# CREATE TABLE authors_characteristics (id uuid, characteristic text);
test_db=# INSERT INTO public.authors_characteristics (id, characteristic) SELECT gen_random_uuid(), concat_ws(' ', (array['Tom', 'Semen', 'Hirosy', 'Jacob'])[(random() * 4)::int], 'is the', (array['greate', 'good', 'bad'])[(random() * 4)
::int], (array['American', 'British', 'Russian', 'Japaneese'])[(random() * 5)::int],'writer') FROM generate_series(1,1000);
INSERT 0 1000
test_db=# SELECT * FROM authors_characteristics LIMIT 10;
                  id                  |           characteristic
--------------------------------------+------------------------------------
 b873f57a-3e3a-4e4a-a86c-c47bf5d008d8 | is the good American writer
 606a1d0e-d679-4da1-bd15-cabab65d1f2c | Semen is the writer
 96892b0c-3367-439f-9254-7d1a62efde62 | Semen is the Russian writer
 97da5018-e832-4c6f-97b3-b2760cd4d88f | Tom is the greate Japaneese writer
 fb70a1ef-90b3-4636-8f62-929d6358aa2b | Tom is the good American writer
 1cb09f28-c7ce-421f-a675-ce19d90f59d8 | Semen is the good Russian writer
 d6db7035-85af-4096-a2bb-78ceacc4d2d8 | is the greate American writer
 35ea97bd-820b-428a-9f87-cd3ac818ceee | Hirosy is the bad Russian writer
 766ddc46-b2d5-4a78-99c8-35db6883d11c | Semen is the good writer
 803fcc78-8066-4cb5-9194-2bbf733ef861 | Tom is the good Russian writer
(10 rows)

test_db=# ALTER TABLE authors_characteristics ADD COLUMN characteristic_tsvector tsvector;
ALTER TABLE
test_db=# UPDATE authors_characteristics SET characteristic_tsvector=characteristic::tsvector;
UPDATE 1000
test_db=# SELECT * FROM authors_characteristics LIMIT 10;
                  id                  |           characteristic           |            characteristic_tsvector
--------------------------------------+------------------------------------+------------------------------------------------
 b873f57a-3e3a-4e4a-a86c-c47bf5d008d8 | is the good American writer        | 'American' 'good' 'is' 'the' 'writer'
 606a1d0e-d679-4da1-bd15-cabab65d1f2c | Semen is the writer                | 'Semen' 'is' 'the' 'writer'
 96892b0c-3367-439f-9254-7d1a62efde62 | Semen is the Russian writer        | 'Russian' 'Semen' 'is' 'the' 'writer'
 97da5018-e832-4c6f-97b3-b2760cd4d88f | Tom is the greate Japaneese writer | 'Japaneese' 'Tom' 'greate' 'is' 'the' 'writer'
 fb70a1ef-90b3-4636-8f62-929d6358aa2b | Tom is the good American writer    | 'American' 'Tom' 'good' 'is' 'the' 'writer'
 1cb09f28-c7ce-421f-a675-ce19d90f59d8 | Semen is the good Russian writer   | 'Russian' 'Semen' 'good' 'is' 'the' 'writer'
 d6db7035-85af-4096-a2bb-78ceacc4d2d8 | is the greate American writer      | 'American' 'greate' 'is' 'the' 'writer'
 35ea97bd-820b-428a-9f87-cd3ac818ceee | Hirosy is the bad Russian writer   | 'Hirosy' 'Russian' 'bad' 'is' 'the' 'writer'
 766ddc46-b2d5-4a78-99c8-35db6883d11c | Semen is the good writer           | 'Semen' 'good' 'is' 'the' 'writer'
 803fcc78-8066-4cb5-9194-2bbf733ef861 | Tom is the good Russian writer     | 'Russian' 'Tom' 'good' 'is' 'the' 'writer'
(10 rows)

test_db=# EXPLAIN SELECT * FROM authors_characteristics WHERE characteristic_tsvector @@ to_tsquery('greate');
                                QUERY PLAN
--------------------------------------------------------------------------
 Seq Scan on authors_characteristics  (cost=0.00..288.50 rows=5 width=96)
   Filter: (characteristic_tsvector @@ to_tsquery('greate'::text))
(2 rows)

test_db=# CREATE INDEX authors_characteristics_index ON authors_characteristics USING GIN (characteristic_tsvector);
CREATE INDEX
test_db=# ANALYZE authors_characteristics;
ANALYZE
test_db=# EXPLAIN SELECT * FROM authors_characteristics WHERE characteristic_tsvector @@ to_tsquery('greate');
                                         QUERY PLAN
--------------------------------------------------------------------------------------------
 Bitmap Heap Scan on authors_characteristics  (cost=8.29..23.02 rows=5 width=96)
   Recheck Cond: (characteristic_tsvector @@ to_tsquery('greate'::text))
   ->  Bitmap Index Scan on authors_characteristics_index  (cost=0.00..8.29 rows=5 width=0)
         Index Cond: (characteristic_tsvector @@ to_tsquery('greate'::text))
(4 rows)

```
*1.5. Реализовать индекс на часть таблицы или индекс на поле с функцией*
```

```
*1.6. Создать индекс на несколько полей*
```

```
