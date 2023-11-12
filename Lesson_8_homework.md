# 0.Создание виртуальной машины и кластера PostgreSQL с настройками по умолчанию
*0.1.Создание инстанса ВМ*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_16.png)
```
PS C:\Users\Egor> type C:\Users\Egor\.ssh\id_ed25519.pub | clip
PS C:\Users\Egor> ssh ssh-rsa@51.250.80.65
The authenticity of host '51.250.80.65 (51.250.80.65)' can't be established.
ECDSA key fingerprint is SHA256:vg5QOyopgy35zPOUo2nHpdxIFqxavrMV4o7aypxhDY0.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '51.250.80.65' (ECDSA) to the list of known hosts.
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-88-generic x86_64)
```
*0.2.Установка PostgreSQL*
```
ssh-rsa@lesson8:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@lesson8:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```
# 1.Настройка логирования блокировок
*1.1.Настройте сервер так, чтобы в журнал сообщений сбрасывалась информация о блокировках, удерживаемых более 200 миллисекунд*
```
ssh-rsa@lesson8:~$ sudo -u postgres psql
could not change directory to "/home/ssh-rsa": Permission denied
psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
Type "help" for help.

postgres=# SHOW deadlock_timeout;
 deadlock_timeout
------------------
 1s
(1 row)

postgres=# SHOW log_lock_waits;
 log_lock_waits
----------------
 off
(1 row)

postgres=# ALTER SYSTEM SET log_lock_waits = on;
ALTER SYSTEM
postgres=# ALTER SYSTEM SET deadlock_timeout = 200;
ALTER SYSTEM
postgres=# SELECT pg_reload_conf();
 pg_reload_conf
----------------
 t
(1 row)

```
*1.2.Воспроизведите ситуацию, при которой в журнале появятся такие сообщения*
```
postgres=# CREATE TABLE blocks (id integer, data text);
CREATE TABLE
postgres=# INSERT INTO blocks VALUES (1,1);
INSERT 0 1
```

Сессия 1

```
postgres=# BEGIN;
BEGIN
postgres=*# UPDATE blocks SET data = '2';
UPDATE 1
postgres=*# 
```

Сессия 2

```
ssh-rsa@lesson8:~$ sudo -u postgres psql
could not change directory to "/home/ssh-rsa": Permission denied
psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
Type "help" for help.

postgres=# UPDATE blocks SET data = '2';

```
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_17.png)
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_18.png)
```
ssh-rsa@lesson8:~$ sudo -u  postgres nano /var/log/postgresql/postgresql-15-main.log

2023-11-11 19:43:44.613 UTC [6272] postgres@postgres LOG:  process 6272 still waiting for ShareLock on transaction 737 after 200.090 ms
2023-11-11 19:43:44.613 UTC [6272] postgres@postgres DETAIL:  Process holding the lock: 5927. Wait queue: 6272.
2023-11-11 19:43:44.613 UTC [6272] postgres@postgres CONTEXT:  while updating tuple (0,1) in relation "blocks"
2023-11-11 19:43:44.613 UTC [6272] postgres@postgres STATEMENT:  UPDATE blocks SET data = '2';
2023-11-11 19:45:38.592 UTC [5416] LOG:  checkpoint starting: time
2023-11-11 19:45:38.706 UTC [5416] LOG:  checkpoint complete: wrote 1 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.101 s, sync=0.003 s, total=0.115 s; sync files=1, longest=0.003 s, average=0.003 s; distance=0 kB,>2023-11-11 19:46:09.062 UTC [6272] postgres@postgres LOG:  process 6272 acquired ShareLock on transaction 737 after 144648.632 ms
2023-11-11 19:46:09.062 UTC [6272] postgres@postgres CONTEXT:  while updating tuple (0,1) in relation "blocks"
2023-11-11 19:46:09.062 UTC [6272] postgres@postgres STATEMENT:  UPDATE blocks SET data = '2';
```
# 2.Блокировка при обновлении одной и той же строки в разных транзакциях
*2.0.Создаем необходимые расширения и полезные view*
```
postgres=# CREATE EXTENSION pageinspect;
CREATE EXTENSION
postgres=# CREATE EXTENSION pgrowlocks;
CREATE EXTENSION
postgres=# CREATE VIEW locks_v AS
SELECT pid,
       locktype,
       CASE locktype
         WHEN 'relation' THEN relation::regclass::text
         WHEN 'transactionid' THEN transactionid::text
         WHEN 'tuple' THEN relation::regclass::text||':'||tuple::text
       END AS lockid,
       mode,
       granted
FROM pg_locks
WHERE locktype in ('relation','transactionid','tuple')
AND (locktype != 'relation' OR relation = 'blocks'::regclass);
CREATE VIEW
postgres=# CREATE VIEW blocks_v AS
postgres-# SELECT '(0,'||lp||')' AS ctid,
postgres-#        t_xmax as xmax,
postgres-#        CASE WHEN (t_infomask & 128) > 0   THEN 't' END AS lock_only,
    CASE postgres-#        CASE WHEN (t_infomask & 4096) > 0  THEN 't' END AS is_multi,
postgres-#        CASE WHEN (t_infomask2 & 8192) > 0 THEN 't' END AS keys_upd,
postgres-#        CASE WHEN (t_infomask & 16) > 0 THEN 't' END AS keyshr_lock,
postgres-#        CASE WHEN (t_infomask & 16+64) = 16+64 THEN 't' END AS shr_lock
postgres-# FROM heap_page_items(get_raw_page('blocks',0))
postgres-# ORDER BY lp;
CREATE VIEW
```
*2.1.Смоделируйте ситуацию обновления одной и той же строки тремя командами UPDATE в разных сеансах*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_19.png)
*2.2.Изучите возникшие блокировки в представлении pg_locks и убедитесь, что все они понятны*
```
postgres=*# SELECT * FROM locks_v ORDER BY pid, locktype;
 pid  |   locktype    |  lockid  |       mode       | granted
------+---------------+----------+------------------+---------
 6974 | relation      | blocks   | RowExclusiveLock | t
 6974 | transactionid | 743      | ExclusiveLock    | t
 7042 | relation      | blocks   | RowExclusiveLock | t
 7042 | transactionid | 743      | ShareLock        | f
 7042 | transactionid | 744      | ExclusiveLock    | t
 7042 | tuple         | blocks:3 | ExclusiveLock    | t
 7122 | relation      | blocks   | RowExclusiveLock | t
 7122 | transactionid | 745      | ExclusiveLock    | t
 7122 | tuple         | blocks:3 | ExclusiveLock    | f
(9 rows)
```
*2.3.Пришлите список блокировок и объясните, что значит каждая*

Первая транзакция с pid=6974 удерживает блокировку таблицы (строка 1) и собственного номера (строка 2).
Вторая транзакция с pid=7042 аналогично удерживает блокировку таблицы (строка 3) и собственного номера (строка 5). Также транзакция заблокировала версию строки (строка 6), но столкнулась с блокировкой строки от первой транзакции (строка 4).
У третьей транзакции на блокировку строки меньше, т.к. она повисла из-за блокировки версии строки второй транзакции (строка 9) и не дошла до проверки блокировки строки.

# 3.Dead lock
*3.0.Подготовим новую таблицу*
```
postgres=# CREATE TABLE blocks_1 (i integer, data integer);
CREATE TABLE
postgres=# INSERT INTO blocks_1 VALUES (1,2),(2,2),(3,2);
INSERT 0 3
postgres=# ALTER SYSTEM SET deadlock_timeout = 60000;
ALTER SYSTEM
postgres=# SELECT pg_reload_conf();
 pg_reload_conf
----------------
 t
(1 row)

```
*3.1.Воспроизведите взаимоблокировку трех транзакций*
```
--Сессия 1 перевод со счета 1 на счет 2
--Сессия 2 перевод со счета 2 на счет 3
--Сессия 3 перевод со счета 3 на счет 1

--Сессия 1 вычитаем со счета 1
BEGIN;
SELECT txid_current(), pg_backend_pid();
UPDATE blocks_1 SET data=data-1 WHERE i=1;

--Сессия 2 вычитаем со счета 2
BEGIN;
SELECT txid_current(), pg_backend_pid();
UPDATE blocks_1 SET data=data-1 WHERE i=2;

--Сессия 3 вычитаем со счета 3
BEGIN;
SELECT txid_current(), pg_backend_pid();
UPDATE blocks_1 SET data=data-1 WHERE i=3;

--Сессия 1 прибавляем к счету 2
UPDATE blocks_1 SET data=data+1 WHERE i=2;

--Сессия 2 прибавляем к счету 3
UPDATE blocks_1 SET data=data+1 WHERE i=3;

--Сессия 3 прибавляем к счету 1
UPDATE blocks_1 SET data=data+1 WHERE i=1;
```
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_22.png)
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_23.png)
*3.2.Можно ли разобраться в ситуации постфактум, изучая журнал сообщений?*
```
ssh-rsa@lesson8:~$ sudo -u  postgres nano /var/log/postgresql/postgresql-15-main.log

2023-11-12 12:27:42.747 UTC [1345] postgres@postgres ERROR:  deadlock detected
2023-11-12 12:27:42.747 UTC [1345] postgres@postgres DETAIL:  Process 1345 waits for ShareLock on transaction 759; blocked by process 1280.
        Process 1280 waits for ShareLock on transaction 760; blocked by process 1284.
        Process 1284 waits for ShareLock on transaction 758; blocked by process 1345.
        Process 1345: UPDATE blocks_1 SET data=data+1 WHERE i=2;
        Process 1280: UPDATE blocks_1 SET data=data+1 WHERE i=3;
        Process 1284: UPDATE blocks_1 SET data=data+1 WHERE i=1;
2023-11-12 12:27:42.747 UTC [1345] postgres@postgres HINT:  See server log for query details.
2023-11-12 12:27:42.747 UTC [1345] postgres@postgres CONTEXT:  while updating tuple (0,9) in relation "blocks_1"
2023-11-12 12:27:42.747 UTC [1345] postgres@postgres STATEMENT:  UPDATE blocks_1 SET data=data+1 WHERE i=2;
```

Да, сообщение которое мы видели в транзакции записалось и в лог-файл

# 4.Взаимная блокировка при UPDATE таблицы в двух транзакциях
*4.1.Могут ли две транзакции, выполняющие единственную команду UPDATE одной и той же таблицы (без where), заблокировать друг друга?*
```
--Подготовка

--Сессия 1

--Сессия 2

```
