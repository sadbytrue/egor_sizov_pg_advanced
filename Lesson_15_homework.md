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

Создадим следующую триггерную функцию:

```
pract=# CREATE OR REPLACE FUNCTION pract_functions.sales_rewrite_trigger_function()
RETURNS trigger
AS
$$
BEGIN
--- Если триггер сработал для UPDATE или DELETE
IF TG_OP='UPDATE' OR TG_OP='DELETE' THEN
--- Отнимаем OLD.sales_qty*good_price по OLD.good_id
UPDATE pract_functions.good_sum_mart
SET sum_sale=sum_sale-
OLD.sales_qty*(SELECT good_price FROM pract_functions.goods WHERE goods.goods_id=OLD.good_id)
WHERE good_sum_mart.good_name=
(SELECT good_name FROM pract_functions.goods WHERE goods.goods_id=OLD.good_id);
END IF;
--- Если триггер сработал для UPDATE или INSERT
IF TG_OP='UPDATE' OR TG_OP='INSERT' THEN
--- Прибавляем NEW.sales_qty*good_price по NEW.good_id
INSERT INTO pract_functions.good_sum_mart (good_name, sum_sale)
VALUES (
(SELECT good_name FROM pract_functions.goods WHERE goods.goods_id=NEW.good_id),
NEW.sales_qty*(SELECT good_price FROM pract_functions.goods WHERE goods.goods_id=NEW.good_id))
ON CONFLICT (good_name) DO UPDATE
SET sum_sale=good_sum_mart.sum_sale+EXCLUDED.sum_sale;
END IF;
RETURN NULL;
END;
$$ LANGUAGE plpgsql;
CREATE FUNCTION
```

Внесем изменение в таблицу good_sum_mart - сделаем поле good_name PRIMARY KEY, чтобы работала конструкция INSERT ... DO UPDATE в нашей функции

```
pract=# DROP TABLE pract_functions.good_sum_mart;
DROP TABLE
pract=# CREATE TABLE pract_functions.good_sum_mart
(
good_name   varchar(63) PRIMARY KEY,
sum_sale numeric(16, 2) NOT NULL
);
CREATE TABLE
```

Создадим триггеры:

```
pract=# CREATE TRIGGER sales_insert_trigger
AFTER INSERT ON pract_functions.sales
FOR EACH ROW
EXECUTE PROCEDURE pract_functions.sales_rewrite_trigger_function();
CREATE TRIGGER
pract=# CREATE TRIGGER sales_update_trigger
AFTER UPDATE OF good_id, sales_qty ON pract_functions.sales
FOR EACH ROW
EXECUTE PROCEDURE pract_functions.sales_rewrite_trigger_function();
CREATE TRIGGER
pract=# CREATE TRIGGER sales_delete_trigger
AFTER DELETE ON pract_functions.sales
FOR EACH ROW
EXECUTE PROCEDURE pract_functions.sales_rewrite_trigger_function();
CREATE TRIGGER
```
*1.2. Тестирование работы триггеров при разных сценариях*

Сделаем DELETE * FROM sales, сделаем INSERT заново и сравним, что таблица good_sum_mart выдает результат такой же, как запрос SELECT из задания

```
pract=# DELETE FROM pract_functions.sales;
pract=# INSERT INTO sales (good_id, sales_qty) VALUES (1, 10), (1, 1), (1, 120), (2, 1);
INSERT 0 4
pract=# SELECT * FROM pract_functions.good_sum_mart;
        good_name         |   sum_sale
--------------------------+--------------
 Спички хозайственные     |        65.50
 Автомобиль Ferrari FXX K | 185000000.01
(2 rows)

pract=# SELECT G.good_name, sum(G.good_price * S.sales_qty)
pract-# FROM goods G
pract-# INNER JOIN sales S ON S.good_id = G.goods_id
pract-# GROUP BY G.good_name;
        good_name         |     sum
--------------------------+--------------
 Автомобиль Ferrari FXX K | 185000000.01
 Спички хозайственные     |        65.50
(2 rows)

```

Сделаем новый INSERT в sales

```
pract=# INSERT INTO sales (good_id, sales_qty) VALUES (1, 1);
INSERT 0 1
pract=# SELECT * FROM pract_functions.good_sum_mart;
        good_name         |   sum_sale
--------------------------+--------------
 Автомобиль Ferrari FXX K | 185000000.01
 Спички хозайственные     |        66.00
(2 rows)

pract=# SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;
        good_name         |     sum
--------------------------+--------------
 Автомобиль Ferrari FXX K | 185000000.01
 Спички хозайственные     |        66.00
(2 rows)

```

Сделаем DELETE новой строчки

```
pract=# SELECT * FROM sales;
 sales_id | good_id |          sales_time           | sales_qty
----------+---------+-------------------------------+-----------
       14 |       1 | 2024-01-02 18:51:59.486127+00 |        10
       15 |       1 | 2024-01-02 18:51:59.486127+00 |         1
       16 |       1 | 2024-01-02 18:51:59.486127+00 |       120
       17 |       2 | 2024-01-02 18:51:59.486127+00 |         1
       18 |       1 | 2024-01-02 18:55:42.479551+00 |         1
(5 rows)

pract=# DELETE FROM sales WHERE sales_id=18;
DELETE 1
pract=# SELECT * FROM pract_functions.good_sum_mart;
        good_name         |   sum_sale
--------------------------+--------------
 Автомобиль Ferrari FXX K | 185000000.01
 Спички хозайственные     |        65.50
(2 rows)

pract=# SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;
        good_name         |     sum
--------------------------+--------------
 Автомобиль Ferrari FXX K | 185000000.01
 Спички хозайственные     |        65.50
(2 rows)

```

Сделаем UPDATE sales_qty в одной строке

```
pract=# UPDATE sales SET sales_qty=2 WHERE sales_id=17;
UPDATE 1
pract=# SELECT * FROM pract_functions.good_sum_mart;
        good_name         |   sum_sale
--------------------------+--------------
 Спички хозайственные     |        65.50
 Автомобиль Ferrari FXX K | 370000000.02
(2 rows)

pract=# SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;
        good_name         |     sum
--------------------------+--------------
 Автомобиль Ferrari FXX K | 370000000.02
 Спички хозайственные     |        65.50
(2 rows)

```

Сделаем UPDATE good_id в той же строке

```
pract=# UPDATE sales SET good_id=1 WHERE sales_id=17;
UPDATE 1
pract=# SELECT * FROM pract_functions.good_sum_mart;
        good_name         | sum_sale
--------------------------+----------
 Автомобиль Ferrari FXX K |     0.00
 Спички хозайственные     |    66.50
(2 rows)

pract=# SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;
      good_name       |  sum
----------------------+-------
 Спички хозайственные | 66.50
(1 row)

```

В последнем случае в таблице для отчета остается строчка с sum_sale=0.00. Я опущу этот момент, но при необходимости функцию триггера можно доработать.

В общем, работает.

# 2.Задание со звездочкой *
*2.1. Чем такая схема (витрина+триггер) предпочтительнее отчета, создаваемого "по требованию" (кроме производительности)? Подсказка: В реальной жизни возможны изменения цен.*

Если good_price в таблице goods изменится, то SELECT запрос сделает JOIN новой цены и данные о сумме продаж станут некорректными, т.к. продавали товар в свое время по старой цене.
При INSERT новых продаж в sales таблица good_sum_mart лишена этого недостатка.
Однако при UPDATE или DELETE из sales при условии, что со времени продажи цена менялась, решение с триггерами также работает некорректно, т.к. взять информацию о цене товара, актуальную на момент продажи, в базе просто неоткуда.
Чтобы решить эту проблему, необходимо изменить архитектуру базы. Например, добавить версионирование в таблицу goods (поля ts и tt, в которых будут размещаться время начала и окончания актуальности цены товара соответсвенно)

Ниже продемонстрирую, о какой проблеме говорю:

Обновим цену в таблице goods, не трогая данные в sales. По бизнес-логике сумма продаж останется неизменной, однако SELECT запрос не выполнит требование.

```
pract=# SELECT * FROM pract_functions.good_sum_mart;
        good_name         | sum_sale
--------------------------+----------
 Автомобиль Ferrari FXX K |     0.00
 Спички хозайственные     |    66.50
(2 rows)

pract=# SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;
      good_name       |  sum
----------------------+-------
 Спички хозайственные | 66.50
(1 row)

pract=# UPDATE goods SET good_price=1 WHERE goods_id=1;
UPDATE 1
pract=# SELECT * FROM pract_functions.good_sum_mart;
        good_name         | sum_sale
--------------------------+----------
 Автомобиль Ferrari FXX K |     0.00
 Спички хозайственные     |    66.50
(2 rows)

pract=# SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;
      good_name       |  sum
----------------------+--------
 Спички хозайственные | 133.00
(1 row)

```

Теперь сделаем UPDATE количества проданного товара в таблице sales.
Для записи с sales_id=14 sales_qty = 5.
При цене в момент продажи коробка спичек в 0.50, общая сумма продаж должна уменьшиться на 2.50.
Но на самом деле она уменьшится на 5.00, т.к. при обновлении суммы продаж для расчета будет взята новая цена 1.00

```
pract=# SELECT * FROM sales;
 sales_id | good_id |          sales_time           | sales_qty
----------+---------+-------------------------------+-----------
       14 |       1 | 2024-01-02 18:51:59.486127+00 |        10
       15 |       1 | 2024-01-02 18:51:59.486127+00 |         1
       16 |       1 | 2024-01-02 18:51:59.486127+00 |       120
       17 |       1 | 2024-01-02 18:51:59.486127+00 |         1
(5 rows)

pract=# UPDATE sales SET sales_qty=5 WHERE sales_id=14;
UPDATE 1
pract=# SELECT * FROM pract_functions.good_sum_mart;
        good_name         | sum_sale
--------------------------+----------
 Автомобиль Ferrari FXX K |     0.00
 Спички хозайственные     |    61.50
(2 rows)

```
