# 0.Создание виртуальной машины и кластера PostgreSQL с настройками по умолчанию
*0.1.Создание инстанса ВМ*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_15.png)
```
PS C:\Users\Egor> type C:\Users\Egor\.ssh\id_ed25519.pub | clip
PS C:\Users\Egor> ssh ssh-rsa@158.160.49.228
The authenticity of host '158.160.49.228 (158.160.49.228)' can't be established.
ECDSA key fingerprint is SHA256:gbOM7Ddd9XCe5gebedlyc2r4QhMcqTFBr5ITaVkPl+I.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '158.160.49.228' (ECDSA) to the list of known hosts.
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-87-generic x86_64)
```
*0.2.Установка PostgreSQL с настройками по умолчанию*
```
ssh-rsa@lesson7:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@lesson7:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log

ssh-rsa@lesson7:~$ sudo -u postgres psql
could not change directory to "/home/ssh-rsa": Permission denied
psql (15.4 (Ubuntu 15.4-2.pgdg22.04+1))
Type "help" for help.

postgres=# exit
ssh-rsa@lesson7:~$
```
# 1.Тестирование объема журналирования с настройками по умолчанию
*1.1.Настройте выполнение контрольной точки раз в 30 секунд*
```
ssh-rsa@lesson7:~$ cd /etc/postgresql/15/main
ssh-rsa@lesson7:/etc/postgresql/15/main$ sudo -u  postgres nano postgresql.conf

# - Checkpoints -

checkpoint_timeout = 30s                # range 30s-1d
#checkpoint_completion_target = 0.9     # checkpoint target duration, 0.0 - 1.0
#checkpoint_flush_after = 256kB         # measured in pages, 0 disables
#checkpoint_warning = 30s               # 0 disables

ssh-rsa@lesson7:/etc/postgresql/15/main$
ssh-rsa@lesson7:/etc/postgresql/15/main$ cd
ssh-rsa@lesson7:~$ sudo pg_ctlcluster 15 main restart
ssh-rsa@lesson7:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```
*1.2.10 минут c помощью утилиты pgbench подавайте нагрузку*
```
ssh-rsa@lesson7:~$ sudo -u postgres psql
could not change directory to "/home/ssh-rsa": Permission denied
psql (15.4 (Ubuntu 15.4-2.pgdg22.04+1))
Type "help" for help.

postgres=# CREATE DATABASE db_for_pgbench;
CREATE DATABASE
postgres=# \c db_for_pgbench
You are now connected to database "db_for_pgbench" as user "postgres".
db_for_pgbench=# ALTER ROLE postgres WITH PASSWORD '123';
ALTER ROLE
db_for_pgbench=# \q

ssh-rsa@lesson7:~$ pgbench -i -U postgres -h localhost -p 5432  db_for_pgbench
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
done in 1.19 s (drop tables 0.00 s, create tables 0.01 s, client-side generate 0.87 s, vacuum 0.04 s, primary keys 0.28 s).

$ pgbench -c8 -P 6 -T 600 -U postgres -h localhost -p 5432 db_for_pgbench
Password:
pgbench (15.4 (Ubuntu 15.4-2.pgdg22.04+1))
<...>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 600 s
number of transactions actually processed: 354410
number of failed transactions: 0 (0.000%)
latency average = 13.542 ms
latency stddev = 11.640 ms
initial connection time = 95.083 ms
tps = 590.700435 (without initial connection time)
```
*1.3.Измерьте, какой объем журнальных файлов был сгенерирован за это время. Оцените, какой объем приходится в среднем на одну контрольную точку*
```
postgres=# \c db_for_pgbench
You are now connected to database "db_for_pgbench" as user "postgres".
db_for_pgbench=# CREATE EXTENSION pg_buffercache;
CREATE EXTENSION
db_for_pgbench=# CREATE VIEW pg_buffercache_v AS
db_for_pgbench-# SELECT bufferid,
db_for_pgbench-#        (SELECT c.relname FROM pg_class c WHERE  pg_relation_filenode(c.oid) = b.relfilenode ) relname,
    CAdb_for_pgbench-#        CASE relforknumber
db_for_pgbench-#          WHEN 0 THEN 'main'
db_for_pgbench-#          WHEN 1 THEN 'fsm'
db_for_pgbench-#          WHEN 2 THEN 'vm'
db_for_pgbench-#        END relfork,
db_for_pgbench-#        relblocknumber,
db_for_pgbench-#        isdirty,
db_for_pgbench-#        usagecount
db_for_pgbench-# FROM   pg_buffercache b
db_for_pgbench-# WHERE  b.relDATABASE IN (    0, (SELECT oid FROM pg_DATABASE WHERE datname = current_database()) )
db_for_pgbench-# AND    b.usagecount is not null;
CREATE VIEW
db_for_pgbench=# select COUNT(*) from pg_buffercache;
 count
-------
 16384
(1 row)
```

Размер одной страницы buffercashe = 8 КБ.
Тогда объем buffercashe = 131 072 КБ = 128 Мб

# 2.Сравнение работы в синхронном и асинхронном режиме
*2.1.Проверьте данные статистики: все ли контрольные точки выполнялись точно по расписанию*
```

```
*2.2.Почему так произошло?*



*2.3.Сравните tps в синхронном/асинхронном режиме утилитой pgbench*
```

```
*2.4.Объясните полученный результат*



# 3.Тестирование режима контрольной суммы таблицы
*3.1.Создайте новый кластер с включенной контрольной суммой страниц*
```

```
*3.2.Создайте таблицу*
```

```
*3.3.Вставьте несколько значений*
```

```
*3.4.Выключите кластер*
```

```
*3.5.Измените пару байт в таблице*
```

```
*3.6.Включите кластер и сделайте выборку из таблицы*
```

```
*3.7.Что и почему произошло?*



*3.8.Как проигнорировать ошибку и продолжить работу?*



```

```
