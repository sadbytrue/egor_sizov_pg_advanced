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


```
*2.3.Написать какого значения tps удалось достичь, показать какие параметры в какие значения устанавливали и почему*
```

```
# 3.Задание со звездочкой
*3.1.Аналогично протестировать через утилиту https://github.com/Percona-Lab/sysbench-tpcc (требует установки https://github.com/akopytov/sysbench)*
```

```
