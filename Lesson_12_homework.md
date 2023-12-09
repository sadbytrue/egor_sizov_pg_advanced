# 0.Создание виртуальной машины и развертывание кластера PostgreSQL
*0.1. Создание виртуальной машины*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_32.png)
```
PS C:\Users\Egor> type C:\Users\Egor\.ssh\id_ed25519.pub | clip
PS C:\Users\Egor> ssh ssh-rsa@158.160.111.168
The authenticity of host '158.160.111.168 (158.160.111.168)' can't be established.
ECDSA key fingerprint is SHA256:BGxIOpqD0ARENJ+sDyzOY7XHn5bF3S+Csr1LG5lqhbo.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '158.160.111.168' (ECDSA) to the list of known hosts.
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-89-generic x86_64)
```
*0.2. Установка PostgreSQL*
```
ssh-rsa@lesson12:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@lesson12:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```
# 1.Работа с индексами
*1.1. Создание тестовой БД и таблицы*
```

```
*1.2. Создать индекс к какой-либо из таблиц вашей БД*
```

```
*1.3. Прислать текстом результат команды explain, в которой используется данный индекс*
```

```
*1.4. Реализовать индекс для полнотекстового поиска*
```

```
*1.5. Реализовать индекс на часть таблицы или индекс на поле с функцией*
```

```
*1.6. Создать индекс на несколько полей*
```

```
