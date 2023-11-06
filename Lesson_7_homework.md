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
Тогда объем buffercashe = 131 072 КБ = 128 МБ.
Или 6,4 МБ на одну точку checkpoint.

# 2.Сравнение работы в синхронном и асинхронном режиме
*2.1.Проверьте данные статистики: все ли контрольные точки выполнялись точно по расписанию*
```
ssh-rsa@lesson7:~$ sudo -u  postgres nano /var/log/postgresql/postgresql-15-main.log
2023-11-06 07:49:07.922 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 07:49:07.941 UTC [17176] LOG:  checkpoint complete: wrote 3 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.005 s, sync=0.003 s, total=0.019 s; sync files=2, longest=0.002 s, average=0.002 s; distance=0 kB>
2023-11-06 07:50:38.006 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 07:51:05.036 UTC [17176] LOG:  checkpoint complete: wrote 925 buffers (5.6%); 0 WAL file(s) added, 0 removed, 0 recycled; write=26.997 s, sync=0.018 s, total=27.031 s; sync files=300, longest=0.014 s, average=0.001 s; distanc>
2023-11-06 07:51:38.068 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 07:51:38.284 UTC [17176] LOG:  checkpoint complete: wrote 3 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.203 s, sync=0.004 s, total=0.216 s; sync files=3, longest=0.003 s, average=0.002 s; distance=2 kB>
2023-11-06 07:53:08.322 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 07:53:35.009 UTC [17176] LOG:  checkpoint complete: wrote 1702 buffers (10.4%); 0 WAL file(s) added, 0 removed, 1 recycled; write=26.673 s, sync=0.004 s, total=26.688 s; sync files=54, longest=0.003 s, average=0.001 s; distan>
2023-11-06 07:54:08.042 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 07:54:35.112 UTC [17176] LOG:  checkpoint complete: wrote 1850 buffers (11.3%); 0 WAL file(s) added, 0 removed, 1 recycled; write=26.987 s, sync=0.054 s, total=27.070 s; sync files=24, longest=0.015 s, average=0.003 s; distan>
2023-11-06 07:54:38.115 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 07:55:05.158 UTC [17176] LOG:  checkpoint complete: wrote 1866 buffers (11.4%); 0 WAL file(s) added, 0 removed, 1 recycled; write=26.868 s, sync=0.142 s, total=27.044 s; sync files=15, longest=0.127 s, average=0.010 s; distan>
2023-11-06 07:55:08.161 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 07:55:35.083 UTC [17176] LOG:  checkpoint complete: wrote 2014 buffers (12.3%); 0 WAL file(s) added, 0 removed, 2 recycled; write=26.878 s, sync=0.018 s, total=26.922 s; sync files=13, longest=0.009 s, average=0.002 s; distan>
2023-11-06 07:55:38.086 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 07:56:05.106 UTC [17176] LOG:  checkpoint complete: wrote 2080 buffers (12.7%); 0 WAL file(s) added, 0 removed, 1 recycled; write=26.978 s, sync=0.020 s, total=27.020 s; sync files=14, longest=0.010 s, average=0.002 s; distan>
2023-11-06 07:56:08.106 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 07:56:35.137 UTC [17176] LOG:  checkpoint complete: wrote 2040 buffers (12.5%); 0 WAL file(s) added, 0 removed, 2 recycled; write=26.964 s, sync=0.020 s, total=27.032 s; sync files=9, longest=0.008 s, average=0.003 s; distanc>
2023-11-06 07:56:38.138 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 07:57:05.123 UTC [17176] LOG:  checkpoint complete: wrote 2118 buffers (12.9%); 0 WAL file(s) added, 0 removed, 1 recycled; write=26.906 s, sync=0.035 s, total=26.986 s; sync files=16, longest=0.027 s, average=0.003 s; distan>
2023-11-06 07:57:08.126 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 07:57:35.122 UTC [17176] LOG:  checkpoint complete: wrote 2001 buffers (12.2%); 0 WAL file(s) added, 0 removed, 1 recycled; write=26.931 s, sync=0.042 s, total=26.996 s; sync files=10, longest=0.021 s, average=0.005 s; distan>
2023-11-06 07:57:38.125 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 07:58:05.047 UTC [17176] LOG:  checkpoint complete: wrote 2115 buffers (12.9%); 0 WAL file(s) added, 0 removed, 2 recycled; write=26.872 s, sync=0.008 s, total=26.922 s; sync files=14, longest=0.008 s, average=0.001 s; distan>
2023-11-06 07:58:08.050 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 07:58:35.061 UTC [17176] LOG:  checkpoint complete: wrote 1976 buffers (12.1%); 0 WAL file(s) added, 0 removed, 1 recycled; write=26.970 s, sync=0.018 s, total=27.011 s; sync files=9, longest=0.013 s, average=0.002 s; distanc>
2023-11-06 07:58:38.064 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 07:59:05.081 UTC [17176] LOG:  checkpoint complete: wrote 2089 buffers (12.8%); 0 WAL file(s) added, 0 removed, 2 recycled; write=26.972 s, sync=0.027 s, total=27.018 s; sync files=16, longest=0.022 s, average=0.002 s; distan>
2023-11-06 07:59:08.085 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 07:59:35.105 UTC [17176] LOG:  checkpoint complete: wrote 1973 buffers (12.0%); 0 WAL file(s) added, 0 removed, 1 recycled; write=26.964 s, sync=0.028 s, total=27.021 s; sync files=8, longest=0.019 s, average=0.004 s; distanc>
2023-11-06 07:59:38.106 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 08:00:05.082 UTC [17176] LOG:  checkpoint complete: wrote 2102 buffers (12.8%); 0 WAL file(s) added, 0 removed, 1 recycled; write=26.890 s, sync=0.026 s, total=26.977 s; sync files=15, longest=0.013 s, average=0.002 s; distan>
2023-11-06 08:00:08.085 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 08:00:35.144 UTC [17176] LOG:  checkpoint complete: wrote 1893 buffers (11.6%); 0 WAL file(s) added, 0 removed, 2 recycled; write=26.981 s, sync=0.035 s, total=27.060 s; sync files=9, longest=0.027 s, average=0.004 s; distanc>
2023-11-06 08:00:38.147 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 08:01:05.159 UTC [17176] LOG:  checkpoint complete: wrote 2058 buffers (12.6%); 0 WAL file(s) added, 0 removed, 1 recycled; write=26.896 s, sync=0.040 s, total=27.012 s; sync files=11, longest=0.040 s, average=0.004 s; distan>
2023-11-06 08:01:08.162 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 08:01:35.102 UTC [17176] LOG:  checkpoint complete: wrote 1936 buffers (11.8%); 0 WAL file(s) added, 0 removed, 1 recycled; write=26.894 s, sync=0.012 s, total=26.941 s; sync files=9, longest=0.007 s, average=0.002 s; distanc>
2023-11-06 08:01:38.106 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 08:02:05.042 UTC [17176] LOG:  checkpoint complete: wrote 2275 buffers (13.9%); 0 WAL file(s) added, 0 removed, 2 recycled; write=26.886 s, sync=0.011 s, total=26.937 s; sync files=15, longest=0.011 s, average=0.001 s; distan>
2023-11-06 08:02:08.045 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 08:02:35.059 UTC [17176] LOG:  checkpoint complete: wrote 1917 buffers (11.7%); 0 WAL file(s) added, 0 removed, 1 recycled; write=26.969 s, sync=0.019 s, total=27.014 s; sync files=7, longest=0.011 s, average=0.003 s; distanc>
2023-11-06 08:02:38.062 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 08:03:05.073 UTC [17176] LOG:  checkpoint complete: wrote 2065 buffers (12.6%); 0 WAL file(s) added, 0 removed, 1 recycled; write=26.966 s, sync=0.016 s, total=27.011 s; sync files=14, longest=0.013 s, average=0.002 s; distan>
2023-11-06 08:03:08.074 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 08:03:35.141 UTC [17176] LOG:  checkpoint complete: wrote 1955 buffers (11.9%); 0 WAL file(s) added, 0 removed, 2 recycled; write=26.976 s, sync=0.068 s, total=27.067 s; sync files=9, longest=0.057 s, average=0.008 s; distanc>
2023-11-06 08:03:38.144 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 08:04:05.064 UTC [17176] LOG:  checkpoint complete: wrote 2267 buffers (13.8%); 0 WAL file(s) added, 0 removed, 1 recycled; write=26.882 s, sync=0.011 s, total=26.920 s; sync files=14, longest=0.011 s, average=0.001 s; distan>
2023-11-06 08:04:38.097 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 08:05:05.112 UTC [17176] LOG:  checkpoint complete: wrote 1920 buffers (11.7%); 0 WAL file(s) added, 0 removed, 1 recycled; write=26.973 s, sync=0.012 s, total=27.016 s; sync files=13, longest=0.010 s, average=0.001 s; distan>
2023-11-06 08:10:38.396 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 08:10:42.228 UTC [17176] LOG:  checkpoint complete: wrote 39 buffers (0.2%); 0 WAL file(s) added, 0 removed, 0 recycled; write=3.815 s, sync=0.006 s, total=3.833 s; sync files=34, longest=0.004 s, average=0.001 s; distance=16>
2023-11-06 08:12:08.314 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 08:12:10.742 UTC [17176] LOG:  checkpoint complete: wrote 25 buffers (0.2%); 0 WAL file(s) added, 0 removed, 0 recycled; write=2.410 s, sync=0.007 s, total=2.428 s; sync files=21, longest=0.005 s, average=0.001 s; distance=13>
2023-11-06 08:13:08.798 UTC [17176] LOG:  checkpoint starting: time
2023-11-06 08:13:09.012 UTC [17176] LOG:  checkpoint complete: wrote 2 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.201 s, sync=0.004 s, total=0.215 s; sync files=2, longest=0.004 s, average=0.002 s; distance=7 kB>
```
*2.2.Почему так произошло?*

Без нагрузки pgbench checkpoints не выполняются, т.к. отсутствует изменение буфера и нет грязных записей.

*2.3.Сравните tps в синхронном/асинхронном режиме утилитой pgbench*
```
ssh-rsa@lesson7:~$ cd /etc/postgresql/15/main
ssh-rsa@lesson7:/etc/postgresql/15/main$ sudo -u  postgres nano postgresql.conf

#------------------------------------------------------------------------------
# WRITE-AHEAD LOG
#------------------------------------------------------------------------------

# - Settings -

#wal_level = replica                    # minimal, replica, or logical
                                        # (change requires restart)
fsync = off                             # flush data to disk for crash safety
                                        # (turning this off can cause
                                        # unrecoverable data corruption)
#synchronous_commit = on                # synchronization level;
                                        # off, local, remote_write, remote_apply, or on
#wal_sync_method = fsync                # the default is the first option
                                        # supported by the operating system:
                                        #   open_datasync
                                        #   fdatasync (default on Linux and FreeBSD)
                                        #   fsync
                                        #   fsync_writethrough
                                        #   open_sync
#full_page_writes = on                  # recover from partial page writes
#wal_log_hints = off                    # also do full page writes of non-critical updates
                                        # (change requires restart)
#wal_compression = off                  # enables compression of full-page writes;
                                        # off, pglz, lz4, zstd, or on
#wal_init_zero = on                     # zero-fill new WAL files
#wal_recycle = on                       # recycle WAL files
#wal_buffers = -1                       # min 32kB, -1 sets based on shared_buffers
                                        # (change requires restart)
#wal_writer_delay = 200ms               # 1-10000 milliseconds
#wal_writer_flush_after = 1MB           # measured in pages, 0 disables
#wal_skip_threshold = 2MB

#commit_delay = 0                       # range 0-100000, in microseconds
#commit_siblings = 5                    # range 1-1000

ssh-rsa@lesson7:/etc/postgresql/15/main$ sudo pg_ctlcluster 15 main restart

ssh-rsa@lesson7:/etc/postgresql/15/main$ pgbench -i -U postgres -h localhost -p 5432  db_for_pgbench
Password:
dropping old tables...
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.03 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.15 s (drop tables 0.01 s, create tables 0.00 s, client-side generate 0.08 s, vacuum 0.03 s, primary keys 0.04 s).

ssh-rsa@lesson7:/etc/postgresql/15/main$ pgbench -c8 -P 6 -T 600 -U postgres -h localhost -p 5432 db_for_pgbench
Password:
pgbench (15.4 (Ubuntu 15.4-2.pgdg22.04+1))
<...>
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 600 s
number of transactions actually processed: 1340214
number of failed transactions: 0 (0.000%)
latency average = 3.580 ms
latency stddev = 1.411 ms
initial connection time = 95.430 ms
tps = 2233.977174 (without initial connection time)
```
*2.4.Объясните полученный результат*

tps вырос с 590 до 2233 - примерно в 4 раза. 
Это происходит, потому что изменена настройка fsync=true -> fsync=false, и postgres не ожидает физической записи на диск изменений и переходит к следующей записи в WAL.

# 3.Тестирование режима контрольной суммы таблицы
*3.1.Создайте новый кластер с включенной контрольной суммой страниц*
```
ssh-rsa@lesson7:~$ sudo pg_dropcluster 15 main --stop
ssh-rsa@lesson7:~$ pg_lsclusters
Ver Cluster Port Status Owner Data directory Log file


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
