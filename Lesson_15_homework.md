# 0.Создание виртуальной машины и развертывание кластера PostgreSQL
*0.1. Создание виртуальной машины*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_43.png)
```
PS C:\Users\Egor> type C:\Users\Egor\.ssh\id_ed25519.pub | clip
PS C:\Users\Egor> ssh ssh-rsa@130.193.36.118
The authenticity of host '130.193.36.118 (130.193.36.118)' can't be established.
ECDSA key fingerprint is SHA256:FaWpebCjlD07v8wVKN8alG3rw+4c0JF0Baf4xsZqXDk.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '130.193.36.118' (ECDSA) to the list of known hosts.
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-91-generic x86_64)
```
*0.2. Установка postgres*
```
ssh-rsa@lesson15:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@lesson15:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```
*0.3. Развертывание базы, сздание и наполнение таблиц*
```
ssh-rsa@lesson15:~$ sudo -u postgres psql
could not change directory to "/home/ssh-rsa": Permission denied
psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
Type "help" for help.

postgres=# CREATE DATABASE pract;
CREATE DATABASE
postgres=# \c pract;
You are now connected to database "pract" as user "postgres".
pract=# DROP SCHEMA IF EXISTS pract_functions CASCADE;
NOTICE:  drop cascades to table pract_functions.goods
DROP SCHEMA
pract=# CREATE SCHEMA pract_functions;
CREATE SCHEMA
pract=# SET search_path = pract_functions, publ;
SET
pract=# CREATE TABLE goods
pract-# (
pract(#     goods_id    integer PRIMARY KEY,
pract(#     good_name   varchar(63) NOT NULL,
pract(#     good_price  numeric(12, 2) NOT NULL CHECK (good_price > 0.0)
pract(# );
CREATE TABLE
pract=# INSERT INTO goods (goods_id, good_name, good_price) VALUES (1, 'Спички хозайственные', .50), (2, 'Автомобиль Ferrari FXX K', 185000000.01);
INSERT 0 2
pract=# CREATE TABLE goods
(
    goods_id    integpract-# (
pract(#     goods_id    integer PRIMARY KEY,
pract(#     good_name   varchar(63) NOT NULL,
pract(#     good_price  numeric(12, 2) NOT NULL CHECK (good_price > 0.0)
pract(# );
ERROR:  relation "goods" already exists
pract=# CREATE TABLE sales
pract-# (
pract(#     sales_id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
pract(#     good_id     integer REFERENCES goods (goods_id),
pract(#     sales_time  timestamp with time zone DEFAULT now(),
pract(#     sales_qty   integer CHECK (sales_qty > 0)
pract(# );
CREATE TABLE
pract=# INSERT INTO sales (good_id, sales_qty) VALUES (1, 10), (1, 1), (1, 120), (2, 1);
INSERT 0 4
pract=# CREATE TABLE good_sum_mart
(
good_name   varchar(63) NOT NULL,
sum_sale numeric(16, 2) NOT NULL
);
CREATE TABLE
```
# 1.Создание триггера для поддержки данных в витрине в актуальном состоянии
*1.1. В БД создана структура, описывающая товары (таблица goods) и продажи (таблица sales).
Есть запрос для генерации отчета – сумма продаж по каждому товару.
БД была денормализована, создана таблица (витрина), структура которой повторяет структуру отчета.
Создать триггер на таблице продаж, для поддержки данных в витрине в актуальном состоянии (вычисляющий при каждой продаже сумму и записывающий её в витрину)
Подсказка: не забыть, что кроме INSERT есть еще UPDATE и DELETE*
```

```
*1.2. Тестирование работы триггеров при разных сценариях*
```

```
# 2.Задание со звездочкой *
*2.1. Чем такая схема (витрина+триггер) предпочтительнее отчета, создаваемого "по требованию" (кроме производительности)? Подсказка: В реальной жизни возможны изменения цен.*
```

```
