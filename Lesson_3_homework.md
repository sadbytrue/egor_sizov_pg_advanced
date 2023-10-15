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
postgres=# \set AUTOCOMMIT OFF
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
