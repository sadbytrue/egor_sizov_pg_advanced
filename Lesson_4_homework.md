# 1.Создание виртуальной машины
*1.1.Создайте виртуальную машину c Ubuntu 20.04/22.04 LTS в GCE/ЯО/Virtual Box/докере*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_10.png)
```
PS C:\Users\Egor> type C:\Users\Egor\.ssh\id_ed25519.pub | clip
PS C:\Users\Egor> ssh ssh-rsa@51.250.70.95
The authenticity of host '51.250.70.95 (51.250.70.95)' can't be established.
ECDSA key fingerprint is SHA256:ChayyG+HjZCbpd3hMY5qiAcOlfBAjUWgmvaOTTfJBxY.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '51.250.70.95' (ECDSA) to the list of known hosts.
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-86-generic x86_64)Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-86-generic x86_64)
```
# 2.Установка PostgreSQL, создание таблицы и остановка Postgresql
*2.1.Поставьте на нее PostgreSQL 14 через sudo apt*
```
ssh-rsa@lesson4ex2:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-14
```
*2.2.Проверьте что кластер запущен через sudo -u postgres pg_lsclusters*
```
ssh-rsa@lesson4ex2:~$ sudo -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
14  main    5432 online postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log
```
*2.3.Зайдите из под пользователя postgres в psql и сделайте произвольную таблицу с произвольным содержимым
postgres=# create table test(c1 text);
postgres=# insert into test values('1');
\q*
```
ssh-rsa@lesson4ex2:~$ sudo -u postgres psql
could not change directory to "/home/ssh-rsa": Permission denied
psql (14.9 (Ubuntu 14.9-1.pgdg22.04+1))
Type "help" for help.

postgres=# create table test(c1 text);
CREATE TABLE
postgres=# insert into test values('1');
INSERT 0 1
postgres=# \q
```
*2.4.Остановите postgres например через sudo -u postgres pg_ctlcluster 14 main stop*
```
ssh-rsa@lesson4ex2:~$ sudo systemctl stop postgresql@14-main
ssh-rsa@lesson4ex2:~$ sudo -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
14  main    5432 down   postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log
```
# 3.Создание и монтирование диска
*3.1.Создайте новый диск к ВМ размером 10GB*
```

```
*3.2.Добавьте свеже-созданный диск к виртуальной машине - надо зайти в режим ее редактирования и дальше выбрать пункт attach existing disk*
```

```
*3.3.Проинициализируйте диск согласно инструкции и подмонтировать файловую систему, только не забывайте менять имя диска на актуальное, в вашем случае это скорее всего будет /dev/sdb - https://www.digitalocean.com/community/tutorials/how-to-partition-and-format-storage-devices-in-linux*
```

```
*3.4.Перезагрузите инстанс и убедитесь, что диск остается примонтированным (если не так смотрим в сторону fstab)*
```

```
*3.5.Сделайте пользователя postgres владельцем /mnt/data - chown -R postgres:postgres /mnt/data/*
```

```
# 4.Перенос данных на премонтированный диск
*4.1.Перенесите содержимое /var/lib/postgres/15 в /mnt/data - mv /var/lib/postgresql/15/mnt/data*
```

```
*4.2.Попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 15 main start*
```

```
*4.3.Напишите получилось или нет и почему*
```

```
*4.4.Задание: найти конфигурационный параметр в файлах раположенных в /etc/postgresql/15/main который надо поменять и поменяйте его*
```

```
*4.5.Напишите что и почему поменяли*
```

```
*4.6.Попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 15 main start*
```

```
*4.7.Напишите получилось или нет и почему*
```

```
*4.8.Зайдите через через psql и проверьте содержимое ранее созданной таблицы*
```

```
*4.9.Задание со звездочкой: не удаляя существующий инстанс ВМ сделайте новый, поставьте на его PostgreSQL, удалите файлы с данными из /var/lib/postgres, перемонтируйте внешний диск который сделали ранее от первой виртуальной машины ко второй и запустите PostgreSQL на второй машине так чтобы он работал с данными на внешнем диске, расскажите как вы это сделали и что в итоге получилось*
```

```
