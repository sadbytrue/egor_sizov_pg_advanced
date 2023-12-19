# 0.Создание виртуальной машины и развертывание кластера PostgreSQL
*0.1. Создание виртуальной машины*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_42.png)
```
PS C:\Users\Egor> type C:\Users\Egor\.ssh\id_ed25519.pub | clip
PS C:\Users\Egor> ssh ssh-rsa@178.154.206.162
The authenticity of host '178.154.206.162 (178.154.206.162)' can't be established.
ECDSA key fingerprint is SHA256:pPjejF1dr5roeW8LiMn/4AXgoqLfnkC/NkV1jBkN2J8.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '178.154.206.162' (ECDSA) to the list of known hosts.
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-91-generic x86_64)
```
*0.2. Установка postgres*
```
ssh-rsa@lesson14:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@lesson14:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```
*0.3. Развертывание базы flights*
```
PS C:\Users\Egor> scp C:\Users\Egor\Downloads\demo-big-en\demo-big-en-20170815.sql ssh-rsa@178.154.206.162:/home/ssh-rsa
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
demo-big-en-20170815.sql                                                                                                                                                                                   100%  888MB   6.2MB/s   02:24
PS C:\Users\Egor> ssh ssh-rsa@178.154.206.162
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-91-generic x86_64)
ssh-rsa@lesson14:~$ ls
demo-big-en-20170815.sql
ssh-rsa@lesson14:~$ sudo chown -R postgres:postgres /home/ssh-rsa
ssh-rsa@lesson14:~$ sudo -u postgres psql -f demo-big-en-20170815.sql

ssh-rsa@lesson14:~$ sudo -u postgres psql
psql (15.5 (Ubuntu 15.5-1.pgdg22.04+1))
Type "help" for help.

postgres=# \c demo;
You are now connected to database "demo" as user "postgres".
demo=# \dt
               List of relations
  Schema  |      Name       | Type  |  Owner
----------+-----------------+-------+----------
 bookings | aircrafts_data  | table | postgres
 bookings | airports_data   | table | postgres
 bookings | boarding_passes | table | postgres
 bookings | bookings        | table | postgres
 bookings | flights         | table | postgres
 bookings | seats           | table | postgres
 bookings | ticket_flights  | table | postgres
 bookings | tickets         | table | postgres
(8 rows)

```
# 1.Секционирование таблицы
*1.1. Секционировать большую таблицу из демо базы flights*
```

```
