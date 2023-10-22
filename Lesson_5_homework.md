# 1.Создание виртуальной машины и кластера PostgreSQL
*1.1.Cоздайте новый кластер PostgresSQL 14*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_9.png)
```
PS C:\Users\Egor> type C:\Users\Egor\.ssh\id_ed25519.pub | clip
PS C:\Users\Egor> ssh ssh-rsa@158.160.37.78
The authenticity of host '158.160.37.78 (158.160.37.78)' can't be established.
ECDSA key fingerprint is SHA256:XFW6NW2Q5FmG/kXURvo75GRXGgYN3ud+JZnmxDTZkPg.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '158.160.37.78' (ECDSA) to the list of known hosts.
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-86-generic x86_64)
```
```
ssh-rsa@lesson5:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15
```
# 2.Создание логических объектов под пользователем postgresql
*2.1.Зайдите в созданный кластер под пользователем postgres*
```
ssh-rsa@lesson5:~$ sudo -u postgres psql
could not change directory to "/home/ssh-rsa": Permission denied
psql (15.4 (Ubuntu 15.4-2.pgdg22.04+1))
Type "help" for help.

postgres=#
```
*2.2.Создайте новую базу данных testdb*
```
postgres=# CREATE DATABASE testdb;
CREATE DATABASE
```
*2.3.Зайдите в созданную базу данных под пользователем postgres*
```
postgres=# \c testdb;
You are now connected to database "testdb" as user "postgres".
```
*2.4.Создайте новую схему testnm*
```
testdb=# CREATE SCHEMA testnm;
CREATE SCHEMA
```
*2.5.Создайте новую таблицу t1 с одной колонкой c1 типа integer*
```
testdb=# CREATE TABLE testnm.t1 (c1 integer);
CREATE TABLE
```
*2.6.Вставьте строку со значением c1=1*
```
testdb=# INSERT INTO testnm.t1 (c1) VALUES (1);
INSERT 0 1
```
# 3.Создание роли readonly и пользователя testread
*3.1.Создайте новую роль readonly*
```
testdb=# CREATE ROLE readonly NOLOGIN;
CREATE ROLE
```
*3.2.Дайте новой роли право на подключение к базе данных testdb*
```
testdb=# GRANT CONNECT ON DATABASE testdb TO readonly;
GRANT
```
*3.3.Дайте новой роли право на использование схемы testnm*
```
testdb=# GRANT USAGE ON SCHEMA testnm TO readonly;
GRANT
```
*3.4.Дайте новой роли право на select для всех таблиц схемы testnm*
```
testdb=# GRANT SELECT ON ALL TABLES IN SCHEMA testnm TO readonly;
GRANT
```
*3.5.Создайте пользователя testread с паролем test123*
```
testdb=# CREATE USER testread  WITH PASSWORD 'test123';
CREATE ROLE
```
*3.6.Дайте роль readonly пользователю testread*
```
testdb=# GRANT readonly TO testread;
GRANT ROLE
```
# 4.Проверка прав пользователя testread из донастройка
*4.1.Зайдите под пользователем testread в базу данных testdb*
```
postgres=# \c testdb testread localhost 5432;
Password for user testread:
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
You are now connected to database "testdb" as user "testread" on host "localhost" (address "::1") at port "5432".
```
*4.2.Сделайте select * from testnm.t1;*
```
testdb=> SELECT * FROM testnm.t1;
 c1
----
  1
(1 row)
```
*4.3.Получилось?*

Да.

*4.4.Есть идеи почему? Если нет - смотрите шпаргалку*

Потому что роли 'readonly' даны права на использование схемы testnm и SELECT к таблице t1.

*4.5.Теперь попробуйте выполнить команду create table t2(c1 integer); insert into t2 values (2);*
```
testdb=> create table t2 (c1 integer);
ERROR:  permission denied for schema public
LINE 1: create table t2 (c1 integer);

```
*4.6.А как так? Нам же никто прав на создание таблиц и insert в них под ролью readonly?*
В Postgresql 15 ожидаемого поведения не наблюдается. Проверим на 14.

*4.7.Есть идеи как убрать эти права? Если нет - смотрите шпаргалку*
```

```
*4.8.Если вы справились сами то расскажите что сделали и почему, если смотрели шпаргалку - объясните что сделали и почему выполнив указанные в ней команды*
```

```
*4.9.Теперь попробуйте выполнить команду create table t3(c1 integer); insert into t2 values (2);*
```

```
*4.10.Расскажите что получилось и почему*
```

```
