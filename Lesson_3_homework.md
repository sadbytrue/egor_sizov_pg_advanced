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
postgres=# \set AUTOCOMMIT OFF
```
*2.2.Развернуть контейнер с PostgreSQL 15 смонтировав в него /var/lib/postgresql*
```
postgres=# \set AUTOCOMMIT OFF
```
*2.3.Развернуть контейнер с клиентом postgres*
```
postgres=# \set AUTOCOMMIT OFF
```
# 3.Подключение к PostgreSQL 15
*3.1.Подключится из контейнера с клиентом к контейнеру с сервером и сделать таблицу с парой строк*
```
postgres=# \set AUTOCOMMIT OFF
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
