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
*3.2.Добавьте свеже-созданный диск к виртуальной машине - надо зайти в режим ее редактирования и дальше выбрать пункт attach existing disk*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_11.png)
*3.3.Проинициализируйте диск согласно инструкции и подмонтировать файловую систему, только не забывайте менять имя диска на актуальное, в вашем случае это скорее всего будет /dev/sdb - https://www.digitalocean.com/community/tutorials/how-to-partition-and-format-storage-devices-in-linux*
```
ssh-rsa@lesson4ex2:~$ sudo apt install parted
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
parted is already the newest version (3.4-2build1).
parted set to manually installed.
The following packages were automatically installed and are no longer required:
  linux-headers-5.15.0-76 linux-headers-5.15.0-76-generic linux-image-5.15.0-76-generic linux-modules-5.15.0-76-generic linux-modules-extra-5.15.0-76-generic
Use 'sudo apt autoremove' to remove them.
0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.

ssh-rsa@lesson4ex2:~$ sudo parted -l | grep Error
Error: /dev/vdb: unrecognised disk label

ssh-rsa@lesson4ex2:~$ lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0    7:0    0  63.3M  1 loop /snap/core20/1822
loop1    7:1    0  63.5M  1 loop /snap/core20/2015
loop2    7:2    0 111.9M  1 loop /snap/lxd/24322
loop3    7:3    0  49.8M  1 loop /snap/snapd/18357
vda    252:0    0     8G  0 disk
├─vda1 252:1    0     1M  0 part
└─vda2 252:2    0     8G  0 part /
vdb    252:16   0    10G  0 disk

ssh-rsa@lesson4ex2:~$ sudo parted /dev/vdb mklabel gpt
Information: You may need to update /etc/fstab.

ssh-rsa@lesson4ex2:~$ sudo parted -a opt /dev/vdb mkpart primary ext4 0% 100%
Information: You may need to update /etc/fstab.

ssh-rsa@lesson4ex2:~$ lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0    7:0    0  63.3M  1 loop /snap/core20/1822
loop1    7:1    0  63.5M  1 loop /snap/core20/2015
loop2    7:2    0 111.9M  1 loop /snap/lxd/24322
loop3    7:3    0  49.8M  1 loop /snap/snapd/18357
vda    252:0    0     8G  0 disk
├─vda1 252:1    0     1M  0 part
└─vda2 252:2    0     8G  0 part /
vdb    252:16   0    10G  0 disk
└─vdb1 252:17   0    10G  0 part

ssh-rsa@lesson4ex2:~$ sudo mkfs.ext4 -L datapartition /dev/vdb1
mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 2620928 4k blocks and 655360 inodes
Filesystem UUID: 801e2200-a4ca-4f1a-8326-1a074ad83044
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done

ssh-rsa@lesson4ex2:~$ sudo mkdir -p /mnt/data
ssh-rsa@lesson4ex2:~$ sudo nano /etc/fstab
ssh-rsa@lesson4ex2:~$ df -h -x tmpfs
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda2       7.8G  5.1G  2.4G  69% /
/dev/vdb1       9.8G   24K  9.3G   1% /mnt/data
ssh-rsa@lesson4ex2:~$ echo "success" | sudo tee /mnt/data/test_file
success
ssh-rsa@lesson4ex2:~$ cat /mnt/data/test_file
success
ssh-rsa@lesson4ex2:~$ sudo rm /mnt/data/test_file
```
*3.4.Перезагрузите инстанс и убедитесь, что диск остается примонтированным (если не так смотрим в сторону fstab)*
```
ssh-rsa@lesson4ex2:~$ sudo pg_ctlcluster 14 main restart

ssh-rsa@lesson4ex2:~$ sudo -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
14  main    5432 online postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log

ssh-rsa@lesson4ex2:~$ df -h -x tmpfs
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda2       7.8G  5.1G  2.4G  69% /
/dev/vdb1       9.8G   24K  9.3G   1% /mnt/data
```
*3.5.Сделайте пользователя postgres владельцем /mnt/data - chown -R postgres:postgres /mnt/data/*
```
ssh-rsa@lesson4ex2:~$ sudo chown -R postgres:postgres /mnt/data/
```
# 4.Перенос данных на премонтированный диск
*4.1.Перенесите содержимое /var/lib/postgres/15 в /mnt/data - mv /var/lib/postgresql/15/mnt/data*
```
ssh-rsa@lesson4ex2:~$ sudo systemctl stop postgresql@14-main
ssh-rsa@lesson4ex2:~$ sudo -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
14  main    5432 down   postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log

ssh-rsa@lesson4ex2:~$ sudo -u postgres mv /var/lib/postgresql/14 /mnt/data
```
*4.2.Попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 14 main start*
```
ssh-rsa@lesson4ex2:/mnt/data/14$ sudo -u postgres pg_ctlcluster 14 main start
Error: /var/lib/postgresql/14/main is not accessible or does not exist
```
*4.3.Напишите получилось или нет и почему*

Не получилось, т.к. директория main была перемещена на примонтированный диск

*4.4.Задание: найти конфигурационный параметр в файлах раположенных в /etc/postgresql/14/main который надо поменять и поменяйте его*
```
ssh-rsa@lesson4ex2:/etc/postgresql/14/main$ sudo -u  postgres nano postgresql.conf
```
```
data_directory = '/mnt/data/14/main'             # use data in another directory
```
*4.5.Напишите что и почему поменяли*
Поменял data directory, где указал путь до примонтированного диска
*4.6.Попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 14 main start*
```
ssh-rsa@lesson4ex2:/etc/postgresql/14/main$ sudo pg_ctlcluster 14 main restart
Job for postgresql@14-main.service failed because the service did not take the steps required by its unit configuration.
See "systemctl status postgresql@14-main.service" and "journalctl -xeu postgresql@14-main.service" for details.
```
*4.7.Напишите получилось или нет и почему*

Не хватает прав на доступ к директории с конф-файлами https://serverfault.com/questions/1006099/postgresql-10-and-ubuntu-unable-to-postgresql-server-up. Надо выдать.

```
ssh-rsa@lesson4ex2:~$ sudo chown -R postgres:postgres /mnt/data/
ssh-rsa@lesson4ex2:~$ sudo chown -R postgres:postgres /etc/postgresql/14/main
```
*4.8.Зайдите через через psql и проверьте содержимое ранее созданной таблицы*
```
ssh-rsa@lesson4ex2:~$ sudo -u postgres psql
could not change directory to "/home/ssh-rsa": Permission denied
psql (14.9 (Ubuntu 14.9-1.pgdg22.04+1))
Type "help" for help.

postgres=# SELECT * FROM test;
 c1
----
 1
(1 row)
```
*4.9.Задание со звездочкой: не удаляя существующий инстанс ВМ сделайте новый, поставьте на его PostgreSQL, удалите файлы с данными из /var/lib/postgres, перемонтируйте внешний диск который сделали ранее от первой виртуальной машины ко второй и запустите PostgreSQL на второй машине так чтобы он работал с данными на внешнем диске, расскажите как вы это сделали и что в итоге получилось*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_12.png)
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_13.png)
```
PS C:\Users\Egor> type C:\Users\Egor\.ssh\id_ed25519.pub | clip
PS C:\Users\Egor> ssh ssh-rsa@158.160.63.183
The authenticity of host '158.160.63.183 (158.160.63.183)' can't be established.
ECDSA key fingerprint is SHA256:1oYselplLlTszL69G8DG1MgzzCZB3EahUUil3Yx9vno.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '158.160.63.183' (ECDSA) to the list of known hosts.
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-86-generic x86_64)Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-86-generic x86_64)

ssh-rsa@lesson4ex3:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-14

ssh-rsa@lesson4ex3:~$ sudo systemctl stop postgresql@14-main
ssh-rsa@lesson4ex3:~$ sudo -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
14  main    5432 down   postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log

ssh-rsa@lesson4ex3:~$ sudo apt install parted
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
parted is already the newest version (3.4-2build1).
parted set to manually installed.
The following packages were automatically installed and are no longer required:
  linux-headers-5.15.0-76 linux-headers-5.15.0-76-generic linux-image-5.15.0-76-generic linux-modules-5.15.0-76-generic linux-modules-extra-5.15.0-76-generic
Use 'sudo apt autoremove' to remove them.
0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.

ssh-rsa@lesson4ex3:~$ df -h -x tmpfs
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda2       7.8G  5.1G  2.4G  69% /

ssh-rsa@lesson4ex3:~$ sudo nano /etc/fstab
ssh-rsa@lesson4ex3:~$ sudo mount -a
ssh-rsa@lesson4ex3:~$ df -h -x tmpfs
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda2       7.8G  5.1G  2.4G  69% /
/dev/vdb1       9.8G   42M  9.2G   1% /mnt/data

ssh-rsa@lesson4ex3:~$ cd /etc/postgresql/14/main
ssh-rsa@lesson4ex3:/etc/postgresql/14/main$ sudo -u  postgres nano postgresql.conf
data_directory = '/mnt/data/14/main'             # use data in another directory

ssh-rsa@lesson4ex3:~$ cd /var/lib/
ssh-rsa@lesson4ex3:/var/lib$ rm -r postgresql
rm: descend into write-protected directory 'postgresql'? yes
rm: descend into write-protected directory 'postgresql/.local'? yes
rm: descend into write-protected directory 'postgresql/.local/share'? yes
rm: remove write-protected directory 'postgresql/.local/share'? yes
rm: cannot remove 'postgresql/.local/share': Permission denied
rm: descend into write-protected directory 'postgresql/14'? yes
rm: descend into write-protected directory 'postgresql/14/main'? yes
rm: remove write-protected directory 'postgresql/14/main'? yes
rm: cannot remove 'postgresql/14/main': Permission denied

ssh-rsa@lesson4ex3:~$ sudo chown -R postgres:postgres /mnt/data/
ssh-rsa@lesson4ex3:~$ sudo chown -R postgres:postgres /etc/postgresql/14/main

ssh-rsa@lesson4ex3:~$ sudo pg_ctlcluster 14 main restart
ssh-rsa@lesson4ex3:~$ sudo -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory    Log file
14  main    5432 online postgres /mnt/data/14/main /var/log/postgresql/postgresql-14-main.log

ssh-rsa@lesson4ex3:~$ sudo -u postgres psql
could not change directory to "/home/ssh-rsa": Permission denied
psql (14.9 (Ubuntu 14.9-1.pgdg22.04+1))
Type "help" for help.

postgres=# SELECT * FROM test;
 c1
----
 1
(1 row)

```

Делал то же самое, что и в первой части. Кроме того, что внешний диск уже был размечен файловой системой и с его монтажом пришлось проводить меньше действий. Дополнительно была удалена директория /var/lib/postgres
