**Занятие 3. Домашнее задание**
# 1.Создание ВМ в Яндекс Облаке и установка Docker Engine
*1.1.Создать ВМ с Ubuntu 20.04/22.04*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_7.png)
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_8.png)
```
PS C:\Users\Egor> ssh admin@158.160.40.159
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-86-generic x86_64)
```
*1.2.Поставить на нем Docker Engine*
```
admin@homework3:~$ curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh && rm get-docker.sh && sudo usermod -aG docker $USER && newgrp docker
<...>
Client: Docker Engine - Community
 Version:           24.0.6
 API version:       1.43
 Go version:        go1.20.7
 Git commit:        ed223bc
 Built:             Mon Sep  4 12:31:44 2023
 OS/Arch:           linux/amd64
 Context:           default

Server: Docker Engine - Community
 Engine:
  Version:          24.0.6
  API version:      1.43 (minimum version 1.12)
  Go version:       go1.20.7
  Git commit:       1a79695
  Built:            Mon Sep  4 12:31:44 2023
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.6.24
  GitCommit:        61f9fd88f79f081d64d6fa3bb1a0dc71ec870523
 runc:
  Version:          1.1.9
  GitCommit:        v1.1.9-0-gccaecfc
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0
```
# 2.Развернуть PostgreSQL 15 в контейнере
*2.1.Сделать каталог /var/lib/postgres*
```
admin@homework3:~$ sudo docker network create pg-net
7013ae5baad7b6d63a1d9e01909f6da46a8ea2dc7a573b786d4f5593d59e0452
```
*2.2.Развернуть контейнер с PostgreSQL 15 смонтировав в него /var/lib/postgresql*
```
admin@homework3:~$ sudo docker run --name pg-server --network pg-net -e POSTGRES_PASSWORD=postgres -d -p 5432:5432 -v /var/lib/postgres:/var/lib/postgresql/data postgres:15
Unable to find image 'postgres:15' locally
15: Pulling from library/postgres
a378f10b3218: Pull complete
3ae46626af9d: Pull complete
a3ca8ddad466: Pull complete
6e0e6cf3ae2b: Pull complete
d4f0c91b5558: Pull complete
ace5692d59be: Pull complete
19b7f523271d: Pull complete
dec3f4c35148: Pull complete
9a53aadebb04: Pull complete
2fd8d4b4df9d: Pull complete
665564a81906: Pull complete
b69c79506eb3: Pull complete
a433f9c93365: Pull complete
Digest: sha256:3faff326de0fa3713424d44f3b85993459ac1917e0a4bfd35bab9e0a58e41900
Status: Downloaded newer image for postgres:15
3cef289f69aef0cd7f50e39cc5a1ede294a3575afd9784cba73b85f714b484f7
```
*2.3.Развернуть контейнер с клиентом postgres*
```
admin@homework3:~$ sudo docker run -it --rm --network pg-net --name pg-client postgres:15 psql -h pg-server -U postgres
Password for user postgres:
psql (15.4 (Debian 15.4-2.pgdg120+1))
Type "help" for help.

postgres=#
```
# 3.Подключение к PostgreSQL 15
*3.1.Подключится из контейнера с клиентом к контейнеру с сервером и сделать таблицу с парой строк*
```
postgres=# CREATE TABLE table1 (column1 int);
CREATE TABLE
postgres=# INSERT INTO table1 VALUES (1), (2);
INSERT 0 2
```
*3.2.Подключится к контейнеру с сервером с ноутбука/компьютера извне инстансов GCP/ЯО/места установки докера*
```
postgres=# \set AUTOCOMMIT OFF
```
# 4.Удаление контейнера, создание заново и подключение заново
*4.1.Удалить контейнер с сервером*
```
postgres=# \set AUTOCOMMIT OFF
```
*4.2.Создать его заново*
```
postgres=# \set AUTOCOMMIT OFF
```
*4.3.Подключится снова из контейнера с клиентом к контейнеру с сервером*
```
postgres=# \set AUTOCOMMIT OFF
```
*4.4.Проверить, что данные остались на месте*
```
postgres=# \set AUTOCOMMIT OFF
```
