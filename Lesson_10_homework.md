# 1.Создание виртуальной машины и кластера PostgreSQL с настройками по умолчанию
*1.1.Создаем ВМ/докер c ПГ*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_28.png)
```
PS C:\Users\Egor> type C:\Users\Egor\.ssh\id_ed25519.pub | clip
PS C:\Users\Egor> ssh ssh-rsa@158.160.97.155
The authenticity of host '158.160.97.155 (158.160.97.155)' can't be established.
ECDSA key fingerprint is SHA256:3soyYhP9XttF7xJM+O+0rDk3y2slxKTCNOLxuN68GuY.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '158.160.97.155' (ECDSA) to the list of known hosts.
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-88-generic x86_64)

ssh-rsa@lesson10:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@lesson10:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```
# 2.Создание БД со схемой и таблицу с данными
*2.1.Создаем БД, схему и в ней таблицу*
```
ssh-rsa@lesson10:~$ sudo -u postgres psql
could not change directory to "/home/ssh-rsa": Permission denied
psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
Type "help" for help.

postgres=# CREATE DATABASE test_backup;
CREATE DATABASE
postgres=# \c test_backup
You are now connected to database "test_backup" as user "postgres".
test_backup=# CREATE SCHEMA test_backup_schema;
CREATE SCHEMA
test_backup=# CREATE TABLE test_backup_schema.test (i integer);
CREATE TABLE
```
*2.2.Заполним таблицу автосгенерированными 100 записями*
```
test_backup=# INSERT INTO test_backup_schema.test(i) SELECT * FROM generate_series(1,100);
INSERT 0 100
test_backup=# \q
```
# 3.Настройка и осуществление логического бэкапирования и восстановления
*3.1.Под линукс пользователем Postgres создадим каталог для бэкапов*
```
ssh-rsa@lesson10:~$ pwd
/home/ssh-rsa
ssh-rsa@lesson10:~$ mkdir -p backup_copy
ssh-rsa@lesson10:~$ ls
backup_copy
ssh-rsa@lesson10:~$ sudo chown -R postgres:postgres /home/ssh-rsa/backup_copy
```
*3.2.Сделаем логический бэкап используя утилиту COPY*
```
ssh-rsa@lesson10:~$ sudo -u postgres psql
could not change directory to "/home/ssh-rsa": Permission denied
psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
Type "help" for help.

postgres=# \c test_backup
You are now connected to database "test_backup" as user "postgres".
test_backup=# \copy test_backup_schema.test to '/home/ssh-rsa/backup_copy/test_backup_17_11_2023.sql';
/home/ssh-rsa/backup_copy/test_backup_17_11_2023.sql: Permission denied
```

Не хватает прав на папку (об этом написано при подключении к psql), надо вернуться к п. 3.1 и создать директорию в корне файловой системы.

```
ssh-rsa@lesson10:~$ sudo mkdir -p /backup_copy
ssh-rsa@lesson10:~$ sudo chown -R postgres:postgres /backup_copy
ssh-rsa@lesson10:~$ sudo -u postgres psql
could not change directory to "/home/ssh-rsa": Permission denied
psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
Type "help" for help.

postgres=# \c test_backup
You are now connected to database "test_backup" as user "postgres".
test_backup=# \copy test_backup_schema.test to '/backup_copy/test_backup_17_11_2023.sql';
COPY 100
```
*3.3.Восстановим во 2 таблицу данные из бэкапа*
```
CREATE TABLE test_backup_schema.test_from_backup (i int);
CREATE TABLE
test_backup=# \copy test_backup_schema.test_from_backup from '/backup_copy/test_backup_17_11_2023.sql';
COPY 100
test_backup=# SELECT * FROM test_backup_schema.test_from_backup ORDER BY i LIMIT 10;
 i
----
  1
  2
  3
  4
  5
  6
  7
  8
  9
 10
(10 rows)

```
# 4.Бэкапирование и восстановление с помощью pg_dump, pg_restore
*4.1.Используя утилиту pg_dump создадим бэкап в кастомном сжатом формате двух таблиц*
```
ssh-rsa@lesson10:~$ cd /backup_copy
ssh-rsa@lesson10:/backup_copy$ sudo passwd postgres
New password:
Retype new password:
passwd: password updated successfully
ssh-rsa@lesson10:/backup_copy$ su postgres
Password:
postgres@lesson10:/backup_copy$ rm *
postgres@lesson10:/backup_copy$ ls
postgres@lesson10:/backup_copy$ pg_dump -d test_backup --create -t 'test_backup_schema.test_from_backup' -t 'test_backup_schema.test' -Fc | gzip > /backup_copy/backup_pg_dump.gz
postgres@lesson10:/backup_copy$ ls
backup_pg_dump.gz
postgres@lesson10:/backup_copy$ exit
```
*4.2.Используя утилиту pg_restore восстановим в новую БД ТОЛЬКО вторую таблицу*
```
ssh-rsa@lesson10:/backup_copy$ sudo -u postgres psql
psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
Type "help" for help.

postgres=# CREATE DATABASE test_backup_restore;
CREATE DATABASE
postgres=# \q

postgres@lesson10:/backup_copy$ cat backup_pg_dump.gz | gunzip > backup_pg_dump.dump
postgres@lesson10:/backup_copy$ ls
backup_pg_dump.dump  backup_pg_dump.gz
pg_restore -d test_backup_restore -n 'test_backup_schema' -t 'test_backup_schema.test_from_backup' -Fc /backup_copy/backup_pg_dump.dump

postgres@lesson10:/backup_copy$ psql
psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
Type "help" for help.

postgres=# \c test_backup_restore
You are now connected to database "test_backup_restore" as user "postgres".
test_backup_restore=# \dn
      List of schemas
  Name  |       Owner
--------+-------------------
 public | pg_database_owner
(1 row)

test_backup_restore=# \dt
Did not find any relations.
test_backup_restore=# SELECT * FROM test_backup_schema.test_from_backup;
ERROR:  relation "test_backup_schema.test_from_backup" does not exist
LINE 1: SELECT * FROM test_backup_schema.test_from_backup;
```

Таблица не восстановилась. Пробую вручную создать схему в целевой БД и снова восстановить таблицу

```
test_backup_restore=# CREATE SCHEMA test_backup_schema;
CREATE SCHEMA
test_backup_restore=# \q
postgres@lesson10:/backup_copy$ pg_restore -d test_backup_restore -t 'test_backup_schema.test_from_backup' -Fc /backup_copy/backup_pg_dump.dump
postgres@lesson10:/backup_copy$ psql
psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
Type "help" for help.

postgres=# SELECT * FROM test_backup_schema.test_from_backup;
ERROR:  relation "test_backup_schema.test_from_backup" does not exist
LINE 1: SELECT * FROM test_backup_schema.test_from_backup;
```

Все равно не восстановилась. Помогло убрать указание схемы перед именем таблицы

```
postgres@lesson10:/backup_copy$ pg_restore -d test_backup_restore -U postgres -n 'test_backup_schema' -t 'test_from_backup' -Fc /backup_copy/backup_pg_dump.dump

postgres@lesson10:/backup_copy$ psql
psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
Type "help" for help.

postgres=# \c test_backup_restore
You are now connected to database "test_backup_restore" as user "postgres".
test_backup_restore=# SELECT count (*) FROM test_backup_schema.test_from_backup;
 count
-------
   100
(1 row)

```
