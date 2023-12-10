# 0.Создание 4 виртуальных машин и установка postgres
*0.1. Создание 4 виртуальных машин*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_33.png)
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_34.png)
*0.2. Установка postgres*
```
sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15
```
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_35.png)
# 1.Настройка логической репликации на ВМ 1
*1.1. На 1 ВМ создаем таблицы test для записи, test2 для запросов на чтение*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_36.png)
*1.2. Создаем публикацию таблицы test и подписываемся на публикацию таблицы test2 с ВМ №2*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_37.png)
```
postgres=# CREATE PUBLICATION test_pub FOR TABLE test;
CREATE PUBLICATION

postgres=# CREATE SUBSCRIPTION test_sub CONNECTION 'host=158.160.125.198 port=5432 user=postgres password=1 dbname=postgres' PUBLICATION test2_pub WITH (copy_data = true);
ERROR:  could not connect to the publisher: connection to server at "158.160.125.198", port 5432 failed: Connection refused
        Is the server running on that host and accepting TCP/IP connections?
```

Надо настроить listen_addresses = '*' в postgresql.conf и host  all  all 0.0.0.0/0 scram-sha-256 в pg_hba.conf на обоих виртуальных машинах.

```
ssh-rsa@vm1:~$ cd /etc/postgresql/15/main
ssh-rsa@vm1:/etc/postgresql/15/main$ sudo nano postgresql.conf
ssh-rsa@vm1:/etc/postgresql/15/main$ sudo nano pg_hba.conf
ssh-rsa@vm1:/etc/postgresql/15/main$ sudo pg_ctlcluster 15 main restart
```

Создаем подписку

```
postgres=# CREATE SUBSCRIPTION test2_sub CONNECTION 'host=158.160.125.198 port=5432 user=postgres password=1 dbname=postgres' PUBLICATION test2_pub WITH (copy_data = true);
NOTICE:  created replication slot "test2_sub" on publisher
CREATE SUBSCRIPTION
```
# 2.Настройка логической репликации на ВМ 2
*2.1. На 2 ВМ создаем таблицы test2 для записи, test для запросов на чтение*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_36.png)
*2.2. Создаем публикацию таблицы test2 и подписываемся на публикацию таблицы test1 с ВМ №1*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_37.png)
```
postgres=# CREATE PUBLICATION test2_pub FOR TABLE test2;
WARNING:  wal_level is insufficient to publish logical changes
HINT:  Set wal_level to "logical" before creating subscriptions.
CREATE PUBLICATION
postgres=# \q
ssh-rsa@vm2:~$ sudo pg_ctlcluster 15 main restart
ssh-rsa@vm2:~$ sudo -u postgres psql
could not change directory to "/home/ssh-rsa": Permission denied
psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
Type "help" for help.

postgres=# CREATE PUBLICATION test2_pub FOR TABLE test2;
ERROR:  publication "test2_pub" already exists
postgres=# DROP PUBLICATION test2_pub FOR TABLE test2;
ERROR:  syntax error at or near "FOR"
LINE 1: DROP PUBLICATION test2_pub FOR TABLE test2;
                                   ^
postgres=# DROP PUBLICATION test2_pub;
DROP PUBLICATION
postgres=# CREATE PUBLICATION test2_pub FOR TABLE test2;
CREATE PUBLICATION

postgres=# CREATE SUBSCRIPTION test_sub CONNECTION 'host=158.160.124.245 port=5432 user=postgres password=1 dbname=po
stgres' PUBLICATION test_pub WITH (copy_data = true);
NOTICE:  created replication slot "test_sub" on publisher
CREATE SUBSCRIPTION
```

Проверяем, как работает логическая репликация таблицы test. Для этого вставим данные в таблицу test на ВМ1 и проверяем, что данные появились в соответсвующей таблице на ВМ2:

![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_38.png)

Работает.

Проверяем, как работает логическая репликация таблицы test2. Для этого вставим данные в таблицу test2 на ВМ2 и проверяем, что данные появились в соответсвующей таблице на ВМ1:

![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_39.png)

Работает.

# 3.Настройка физической репликации на ВМ 3
*3.1. 3 ВМ использовать как реплику для чтения и бэкапов (подписаться на таблицы из ВМ №1 и №2 )*
```

```
# 4.Настройка каскадной репликации на ВМ 4
*3.1. Реализовать горячее реплицирование для высокой доступности на 4ВМ. Источником должна выступать ВМ №3. Написать с какими проблемами столкнулись*
```

```
