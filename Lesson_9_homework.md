# 1.Создание виртуальной машины и кластера PostgreSQL с настройками по умолчанию
*1.1.Развернуть виртуальную машину любым удобным способом*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_29.png)
```
PS C:\Users\Egor> type C:\Users\Egor\.ssh\id_ed25519.pub | clip
PS C:\Users\Egor> ssh ssh-rsa@158.160.51.36
The authenticity of host '158.160.51.36 (158.160.51.36)' can't be established.
ECDSA key fingerprint is SHA256:t4gOlNFFSwoAGO8h3uqwFNtpWWkgfdEoQ8IR1YvwN4c.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '158.160.51.36' (ECDSA) to the list of known hosts.
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-88-generic x86_64)
```
*1.2.Поставить на неё PostgreSQL 15 любым способом*
```
ssh-rsa@lesson9:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@lesson9:~$ sudo postgres psql
sudo: postgres: command not found
ssh-rsa@lesson9:~$ sudo -u postgres psql
could not change directory to "/home/ssh-rsa": Permission denied
psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
Type "help" for help.

postgres=# \q
```
# 2.Настройка PostgreSQL на максимальную производительность и тестирование производительности
*2.1.Настроить кластер PostgreSQL 15 на максимальную производительность не обращая внимание на возможные проблемы с надежностью в случае аварийной перезагрузки виртуальной машины*

Воспользуюсь калькулятором https://pgconfigurator.cybertec.at/.

![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_30.png)
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_31.png)

Получил следующий конфиг:

```
# DISCLAIMER - Software and the resulting config files are provided AS IS - IN NO EVENT SHALL
# BE THE CREATOR LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
# DAMAGES, INCLUDING LOST PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION.

# Connectivity
max_connections = 100
superuser_reserved_connections = 3

# Memory Settings
shared_buffers = '1024 MB'
work_mem = '32 MB'
maintenance_work_mem = '320 MB'
huge_pages = off
effective_cache_size = '3 GB'
effective_io_concurrency = 100 # concurrent IO only really activated if OS supports posix_fadvise function
random_page_cost = 1.25 # speed of random disk access relative to sequential access (1.0)

# Monitoring
shared_preload_libraries = 'pg_stat_statements' # per statement resource usage stats
track_io_timing=on # measure exact block IO times
track_functions=pl # track execution times of pl-language procedures if any

# Replication
wal_level = replica # consider using at least 'replica'
max_wal_senders = 0
synchronous_commit = off

# Checkpointing:
checkpoint_timeout = '15 min'
checkpoint_completion_target = 0.9
max_wal_size = '1024 MB'
min_wal_size = '512 MB'


# WAL writing
wal_compression = on
wal_buffers = -1 # auto-tuned by Postgres till maximum of segment size (16MB by default)


# Background writer
bgwriter_delay = 200ms
bgwriter_lru_maxpages = 100
bgwriter_lru_multiplier = 2.0
bgwriter_flush_after = 0

# Parallel queries:
max_worker_processes = 2
max_parallel_workers_per_gather = 1
max_parallel_maintenance_workers = 1
max_parallel_workers = 2
parallel_leader_participation = on

# Advanced features
enable_partitionwise_join = on
enable_partitionwise_aggregate = on
jit = on
max_slot_wal_keep_size = '1000 MB'
track_wal_io_timing = on
maintenance_io_concurrency = 100
wal_recycle = on


# General notes:
# Note that not all settings are automatically tuned.
# Consider contacting experts at
# https://www.cybertec-postgresql.com
# for more professional expertise.
```

Из основных параметров: 
shared_buffers - общая память для работы с данными для чтения/записи. Увеличена относительно стандартной.
work_mem - количество используемой памяти для подключений. Выше стандартной.
maintenance_work_mem - объем памяти для системных операций. Выше стандартной.

Помещу полученный конфиг в конец файла postgresql.conf и перезапущу инстанс

```
ssh-rsa@lesson9:~$ cd /etc/postgresql/15/main
ssh-rsa@lesson9:/etc/postgresql/15/main$ sudo nano postgresql.conf
ssh-rsa@lesson9:~$ sudo pg_ctlcluster 15 main restart
```
*2.2.Нагрузить кластер через утилиту через утилиту pgbench*
```
ssh-rsa@lesson9:~$ sudo -u postgres psql
could not change directory to "/home/ssh-rsa": Permission denied
psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
Type "help" for help.

postgres=# CREATE DATABASE db_for_pgbench;
CREATE DATABASE
postgres=# \c db_for_pgbench
You are now connected to database "db_for_pgbench" as user "postgres".
db_for_pgbench=# ALTER ROLE postgres WITH PASSWORD 'postgres';
ALTER ROLE
db_for_pgbench=# \q

ssh-rsa@lesson9:~$ pgbench -i -U postgres -h localhost -p 5432  db_for_pgbench
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
done in 1.08 s (drop tables 0.00 s, create tables 0.00 s, client-side generate 0.90 s, vacuum 0.04 s, primary keys 0.14 s).

ssh-rsa@lesson9:~$ pgbench -c 50 -j 2 -P 60 -T 600 -U postgres -h localhost -p 5432 db_for_pgbench
Password:
pgbench (15.5 (Ubuntu 15.5-1.pgdg22.04+1))

scaling factor: 1
query mode: simple
number of clients: 50
number of threads: 2
maximum number of tries: 1
duration: 600 s
number of transactions actually processed: 897947
number of failed transactions: 0 (0.000%)
latency average = 33.376 ms
latency stddev = 23.979 ms
initial connection time = 631.641 ms
tps = 1497.817877 (without initial connection time)
```

Полученный tps=1498

*2.3.Написать какого значения tps удалось достичь, показать какие параметры в какие значения устанавливали и почему*

Т.к. согласно условию для нас не важна надежность при аварийной остановке, то можем понизить wal_level до minimal, чтобы писать минимум в журнал предзаписи и ряд операций шли в обходн его.

```
wal_level = minimal # consider using at least 'replica'
```

Также можем выставить synchronous_commit и fsync в off, чтобы не дожидаясь физической записи WAL на диск

```
synchronous_commit = off
fsync = off
```

Запишем новые значения параметра, перезапустим кластер и снова протестируем с помощью pgbench

```
ssh-rsa@lesson9:~$ cd /etc/postgresql/15/main
ssh-rsa@lesson9:/etc/postgresql/15/main$ sudo nano postgresql.conf
ssh-rsa@lesson9:/etc/postgresql/15/main$ sudo pg_ctlcluster 15 main restart

ssh-rsa@lesson9:/etc/postgresql/15/main$ pgbench -i -U postgres -h localhost -p 5432  db_for_pgbench
Password:
dropping old tables...
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.03 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.39 s (drop tables 0.03 s, create tables 0.01 s, client-side generate 0.22 s, vacuum 0.04 s, primary keys 0.09 s).
ssh-rsa@lesson9:/etc/postgresql/15/main$ pgbench -c 50 -j 2 -P 60 -T 600 -U postgres -h localhost -p 5432 db_for_pgbench
Password:
pgbench (15.5 (Ubuntu 15.5-1.pgdg22.04+1))

scaling factor: 1
query mode: simple
number of clients: 50
number of threads: 2
maximum number of tries: 1
duration: 600 s
number of transactions actually processed: 907425
number of failed transactions: 0 (0.000%)
latency average = 33.029 ms
latency stddev = 23.684 ms
initial connection time = 602.445 ms
tps = 1513.558921 (without initial connection time)
```

Полученный tps=1513

# 3.Задание со звездочкой
*3.1.Аналогично протестировать через утилиту https://github.com/Percona-Lab/sysbench-tpcc (требует установки https://github.com/akopytov/sysbench)*
```
ssh-rsa@lesson9:~$ sudo -u postgres psql
could not change directory to "/home/ssh-rsa": Permission denied
psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
Type "help" for help.

postgres=# DROP DATABASE db_for_pgbench;
DROP DATABASE
postgres=# CREATE DATABASE db_for_pgbench;
CREATE DATABASE
postgres=# \c db_for_pgbench
You are now connected to database "db_for_pgbench" as user "postgres".
db_for_pgbench=# ALTER ROLE postgres WITH PASSWORD 'postgres';
ALTER ROLE
db_for_pgbench=# \q

ssh-rsa@lesson9:~$ wget -qO - https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash
Detected operating system as Ubuntu/jammy.
Checking for curl...
Detected curl...
Checking for gpg...
Detected gpg...
Detected apt version as 2.4.11
Running apt-get update... done.
Installing apt-transport-https... done.
Installing /etc/apt/sources.list.d/akopytov_sysbench.list...done.
Importing packagecloud gpg key... Packagecloud gpg key imported to /etc/apt/keyrings/akopytov_sysbench-archive-keyring.gpg
done.
Running apt-get update... done.

The repository is setup! You can now install packages.
ssh-rsa@lesson9:~$ sudo apt install -y sysbench
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  libluajit-5.1-2 libluajit-5.1-common libmysqlclient21 mysql-common
The following NEW packages will be installed:
  libluajit-5.1-2 libluajit-5.1-common libmysqlclient21 mysql-common sysbench
0 upgraded, 5 newly installed, 0 to remove and 0 not upgraded.
Need to get 1,711 kB of archives.
After this operation, 8,056 kB of additional disk space will be used.
Get:1 http://mirror.yandex.ru/ubuntu jammy/universe amd64 libluajit-5.1-common all 2.1.0~beta3+dfsg-6 [44.3 kB]
Get:2 http://mirror.yandex.ru/ubuntu jammy/universe amd64 libluajit-5.1-2 amd64 2.1.0~beta3+dfsg-6 [238 kB]
Get:3 http://mirror.yandex.ru/ubuntu jammy/main amd64 mysql-common all 5.8+1.0.8 [7,212 B]
Get:4 http://mirror.yandex.ru/ubuntu jammy-updates/main amd64 libmysqlclient21 amd64 8.0.35-0ubuntu0.22.04.1 [1,301 kB]
Get:5 http://mirror.yandex.ru/ubuntu jammy/universe amd64 sysbench amd64 1.0.20+ds-2 [120 kB]
Fetched 1,711 kB in 0s (28.3 MB/s)
Selecting previously unselected package libluajit-5.1-common.
(Reading database ... 112364 files and directories currently installed.)
Preparing to unpack .../libluajit-5.1-common_2.1.0~beta3+dfsg-6_all.deb ...
Unpacking libluajit-5.1-common (2.1.0~beta3+dfsg-6) ...
Selecting previously unselected package libluajit-5.1-2:amd64.
Preparing to unpack .../libluajit-5.1-2_2.1.0~beta3+dfsg-6_amd64.deb ...
Unpacking libluajit-5.1-2:amd64 (2.1.0~beta3+dfsg-6) ...
Selecting previously unselected package mysql-common.
Preparing to unpack .../mysql-common_5.8+1.0.8_all.deb ...
Unpacking mysql-common (5.8+1.0.8) ...
Selecting previously unselected package libmysqlclient21:amd64.
Preparing to unpack .../libmysqlclient21_8.0.35-0ubuntu0.22.04.1_amd64.deb ...
Unpacking libmysqlclient21:amd64 (8.0.35-0ubuntu0.22.04.1) ...
Selecting previously unselected package sysbench.
Preparing to unpack .../sysbench_1.0.20+ds-2_amd64.deb ...
Unpacking sysbench (1.0.20+ds-2) ...
Setting up mysql-common (5.8+1.0.8) ...
update-alternatives: using /etc/mysql/my.cnf.fallback to provide /etc/mysql/my.cnf (my.cnf) in auto mode
Setting up libmysqlclient21:amd64 (8.0.35-0ubuntu0.22.04.1) ...
Setting up libluajit-5.1-common (2.1.0~beta3+dfsg-6) ...
Setting up libluajit-5.1-2:amd64 (2.1.0~beta3+dfsg-6) ...
Setting up sysbench (1.0.20+ds-2) ...
Processing triggers for man-db (2.10.2-1) ...
Processing triggers for libc-bin (2.35-0ubuntu3.4) ...
Scanning processes...
Scanning candidates...
Scanning linux images...

Running kernel seems to be up-to-date.

Restarting services...
Service restarts being deferred:
 systemctl restart unattended-upgrades.service
Service restarts being deferred:
 systemctl restart unattended-upgrades.service

No containers need to be restarted.

No user sessions are running outdated binaries.

No VM guests are running outdated hypervisor (qemu) binaries on this host.
ssh-rsa@lesson9:~$ sysbench --version
sysbench 1.0.20

ssh-rsa@lesson9:~$ sudo apt -y install libpq-dev
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  libssl-dev
Suggested packages:
  postgresql-doc-16 libssl-doc
The following NEW packages will be installed:
  libpq-dev libssl-dev
0 upgraded, 2 newly installed, 0 to remove and 0 not upgraded.
Need to get 2,515 kB of archives.
After this operation, 13.0 MB of additional disk space will be used.
Get:1 http://mirror.yandex.ru/ubuntu jammy-updates/main amd64 libssl-dev amd64 3.0.2-0ubuntu1.12 [2,373 kB]
Get:2 http://apt.postgresql.org/pub/repos/apt jammy-pgdg/main amd64 libpq-dev amd64 16.1-1.pgdg22.04+1 [142 kB]
Fetched 2,515 kB in 0s (15.4 MB/s)
Selecting previously unselected package libssl-dev:amd64.
(Reading database ... 112183 files and directories currently installed.)
Preparing to unpack .../libssl-dev_3.0.2-0ubuntu1.12_amd64.deb ...
Unpacking libssl-dev:amd64 (3.0.2-0ubuntu1.12) ...
Selecting previously unselected package libpq-dev.
Preparing to unpack .../libpq-dev_16.1-1.pgdg22.04+1_amd64.deb ...
Unpacking libpq-dev (16.1-1.pgdg22.04+1) ...
Setting up libssl-dev:amd64 (3.0.2-0ubuntu1.12) ...
Setting up libpq-dev (16.1-1.pgdg22.04+1) ...
Processing triggers for man-db (2.10.2-1) ...
Scanning processes...
Scanning candidates...
Scanning linux images...

Running kernel seems to be up-to-date.

Restarting services...
 systemctl restart packagekit.service
 systemctl restart packagekit.service
Service restarts being deferred:
 systemctl restart unattended-upgrades.service

No containers need to be restarted.

No user sessions are running outdated binaries.

No VM guests are running outdated hypervisor (qemu) binaries on this host.

ssh-rsa@lesson91:~$ git clone https://github.com/Percona-Lab/sysbench-tpcc.git
Cloning into 'sysbench-tpcc'...
remote: Enumerating objects: 226, done.
remote: Counting objects: 100% (58/58), done.
remote: Compressing objects: 100% (26/26), done.
remote: Total 226 (delta 32), reused 52 (delta 32), pack-reused 168
Receiving objects: 100% (226/226), 77.81 KiB | 996.00 KiB/s, done.
Resolving deltas: 100% (120/120), done.
ssh-rsa@lesson91:~$ ls
sysbench-tpcc
ssh-rsa@lesson91:~$ cd sysbench-tpcc

ssh-rsa@lesson9:~/sysbench-tpcc$ ./tpcc.lua --pgsql-user=postgres --pgsql-password=postgres  --pgsql-db=db_for_pgbench --time=600 --threads=10 --ta
bles=10 --scale=1 --db-driver=pgsql prepare

ssh-rsa@lesson9:~/sysbench-tpcc$ ./tpcc.lua --pgsql-user=postgres --pgsql-password=postgres  --pgsql-db=db_for_pgbench --time=600 --threads=10 --tables=10 --scale=1 --db-driver=pgsql run
SQL statistics:
    queries performed:
        read:                            2190919
        write:                           2264961
        other:                           366600
        total:                           4822480
    transactions:                        164572 (274.26 per sec.)
    queries:                             4822480 (8036.56 per sec.)
    ignored errors:                      19399  (32.33 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          600.0659s
    total number of events:              164572

Latency (ms):
         min:                                    0.60
         avg:                                   36.46
         max:                                 3661.22
         95th percentile:                       90.78
         sum:                              5999792.84

Threads fairness:
    events (avg/stddev):           16457.2000/113.98
    execution time (avg/stddev):   599.9793/0.02
```
