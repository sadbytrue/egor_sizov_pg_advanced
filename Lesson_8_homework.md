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
*2.1.Смоделируйте ситуацию обновления одной и той же строки тремя командами UPDATE в разных сеансах*
```

```
*2.2.Изучите возникшие блокировки в представлении pg_locks и убедитесь, что все они понятны*
```

```
*2.3.Пришлите список блокировок и объясните, что значит каждая*
```

```
# 3.Dead lock
*3.1.Воспроизведите взаимоблокировку трех транзакций*
```

```
*3.2.Можно ли разобраться в ситуации постфактум, изучая журнал сообщений?*
```

```
# 4.Взаимная блокировка при UPDATE таблицы в двух транзакциях
*4.1.Могут ли две транзакции, выполняющие единственную команду UPDATE одной и той же таблицы (без where), заблокировать друг друга?*
```

```
