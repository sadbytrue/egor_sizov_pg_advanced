# 0.Создание виртуальной машины и развертывание кластера PostgreSQL
*0.1. Создание виртуальной машины*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_41.png)
```
PS C:\Users\Egor> type C:\Users\Egor\.ssh\id_ed25519.pub | clip
PS C:\Users\Egor> ssh ssh-rsa@158.160.125.175
The authenticity of host '158.160.125.175 (158.160.125.175)' can't be established.
ECDSA key fingerprint is SHA256:43TJDA4VhjenqN/tOJmjSlkZvAm1tjQmGr3+npHfRac.
Are you sure you want to continue connecting (yes/no)? y
Please type 'yes' or 'no': yes
Warning: Permanently added '158.160.125.175' (ECDSA) to the list of known hosts.
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-89-generic x86_64)
```
*0.2. Установка postgres*
```
ssh-rsa@lesson13:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@lesson13:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
ssh-rsa@lesson13:~$ sudo -u postgres psql
could not change directory to "/home/ssh-rsa": Permission denied
psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
Type "help" for help.
```
# 1.Структура тестовой БД
*1.1. К работе приложить структуру таблиц, для которых выполнялись соединения*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/123%20(1).png)

```
postgres=# CREATE DATABASE contacts;
CREATE DATABASE
postgres=# \c contacts
You are now connected to database "contacts" as user "postgres".
contacts=# CREATE TABLE contractors (id integer, name text, phone_id integer);
CREATE TABLE
contacts=# CREATE TABLE customers (id integer, name text, phone_id integer);
CREATE TABLE
contacts=# CREATE TABLE phones (id integer, phone integer);
CREATE TABLE
contacts=# INSERT INTO phones (id, phone) VALUES (1, 2314567), (2, 1239876), (3, 4567813);
INSERT 0 3
contacts=# INSERT INTO contractors (id, name, phone_id) VALUES (1, 'Ivanov', 1), (2, 'Sidorov', 2), (3, 'Petrov', null);
INSERT 0 3
contacts=# INSERT INTO customers (id, name, phone_id) VALUES (1, 'Semenov', 1), (2, 'Vasilev', 3), (3, 'Dmitriev', null);
INSERT 0 3
```
# 2.Написание запросов с различными типами соединений
*2.1. Реализовать прямое соединение двух или более таблиц*

Получаем список заказчиков с телефонами, исключая заказчиков без номера телефона в базе

```
contacts=# SELECT customers.id AS customer_id, customers.name AS customer_name, phone_id, phone FROM customers JOIN phones ON customers.phone_id=phones.id;
 customer_id | customer_name | phone_id |  phone
-------------+---------------+----------+---------
           1 | Semenov       |        1 | 2314567
           2 | Vasilev       |        3 | 4567813
(2 rows)

```
*2.2. Реализовать левостороннее (или правостороннее) соединение двух или более таблиц*

Получаем список всех заказчиков с телефонами, в т.ч. заказчиков без номера телефона в базе

```
contacts=# SELECT customers.id AS customer_id, customers.name AS customer_name, phone_id, phone FROM customers LEFT JOIN phones ON customers.phone_id=phones.id;
 customer_id | customer_name | phone_id |  phone
-------------+---------------+----------+---------
           1 | Semenov       |        1 | 2314567
           2 | Vasilev       |        3 | 4567813
           3 | Dmitriev      |          |
(3 rows)

```
*1.3. Реализовать кросс соединение двух или более таблиц*

Получаем декартовое произведение таблиц заказчиков и телефонов. Т.е. все возможные сочетания строк таблиц

```
contacts=# SELECT customers.id AS customer_id, customers.name AS customer_name, phones.id AS phone_id, phone FROM customers CROSS JOIN phones;
 customer_id | customer_name | phone_id |  phone
-------------+---------------+----------+---------
           1 | Semenov       |        1 | 2314567
           2 | Vasilev       |        1 | 2314567
           3 | Dmitriev      |        1 | 2314567
           1 | Semenov       |        2 | 1239876
           2 | Vasilev       |        2 | 1239876
           3 | Dmitriev      |        2 | 1239876
           1 | Semenov       |        3 | 4567813
           2 | Vasilev       |        3 | 4567813
           3 | Dmitriev      |        3 | 4567813
(9 rows)

```
*1.4. Реализовать полное соединение двух или более таблиц*

Получим всех заказчиков и телефоны, учитывая пересечения между ними

```
contacts=# SELECT customers.id AS customer_id, customers.name AS customer_name, phones.id, phone FROM customers FULL JOIN phones ON customers.phone_id=phones.id;
 customer_id | customer_name | id |  phone
-------------+---------------+----+---------
           1 | Semenov       |  1 | 2314567
             |               |  2 | 1239876
           2 | Vasilev       |  3 | 4567813
           3 | Dmitriev      |    |
(4 rows)

```
*1.5. Реализовать запрос, в котором будут использованы разные типы соединений*

Получаем информацию о заказчиках с телефонами, а также поставщиках, если их телефон совпадает с телефоном заказчика

```
contacts=# SELECT phones.id AS phone_id, phone, customers.id AS customer_id, customers.name AS customer_name, contractors.id AS contractor_id, contractors.name AS contractor_name FROM customers JOIN phones ON customers.phone_id=phones.id
 LEFT JOIN contractors ON contractors.phone_id=phones.id;
 phone_id |  phone  | customer_id | customer_name | contractor_id | contractor_name
----------+---------+-------------+---------------+---------------+-----------------
        1 | 2314567 |           1 | Semenov       |             1 | Ivanov
        3 | 4567813 |           2 | Vasilev       |               |
(2 rows)

```
# 3.Задание со *
*3.1. Придумайте 3 своих метрики на основе показанных представлений, отправьте их через ЛК, а так же поделитесь с коллегами*
