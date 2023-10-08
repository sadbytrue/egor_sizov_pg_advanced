**Занятие 2. Домашнее задание**
# 1.Создание ВМ в Яндекс Облаке
*1.1.Создать новый проект в Google Cloud Platform, Яндекс облако или на любых ВМ, докере*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_5.png)
*1.2.Далее создать инстанс виртуальной машины с дефолтными параметрами*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_4.png)
# 2.Настройка подключения по ssh
*2.1.Добавить свой ssh ключ в metadata ВМ*
```
PS C:\Users\Egor> ssh-keygen -t ed25519
Generating public/private ed25519 key pair.
Enter file in which to save the key (C:\Users\Egor/.ssh/id_ed25519):
Created directory 'C:\Users\Egor/.ssh'.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in C:\Users\Egor/.ssh/id_ed25519.
Your public key has been saved in C:\Users\Egor/.ssh/id_ed25519.pub.
The key fingerprint is:
SHA256:6sYFlJmxjDz8fMfYXA1f36X5fB4ZE2HDaFMbQKLPtEc egor@WIN-GRJINGE790V
PS C:\Users\Egor> type C:\Users\Egor\.ssh\id_ed25519.pub | clip
```
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_6.png)
*2.2.Зайти удаленным ssh (первая сессия), не забывайте про ssh-add*
```
PS C:\Users\Egor> ssh ssh-rsa@158.160.116.157
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-84-generic x86_64)
```
# 3.Установка интсанса PostgreSQL
*3.1.Поставить PostgreSQL*
```
ssh-rsa@homework2:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q &&
> sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt-get -y install postgresql-15
Hit:1 http://mirror.yandex.ru/ubuntu jammy InRelease
```
```
ssh-rsa@homework2:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```
# 4.Запуск второй сессии. Создание тестовой таблицы. Отключение autocommit
*4.1.Зайти вторым ssh (вторая сессия)*
```
PS C:\Users\Egor> ssh ssh-rsa@158.160.116.157
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-84-generic x86_64)
```
*4.2.Запустить везде psql из под пользователя postgres*
```
ssh-rsa@homework2:~$ sudo -u postgres psql
```
*4.3.Выключить auto commit*
```
postgres=# \set AUTOCOMMIT OFF
```
*4.4.Сделать в первой сессии новую таблицу и наполнить ее данными create table persons(id serial, first_name text, second_name text); insert into persons(first_name, second_name) values('ivan', 'ivanov'); insert into persons(first_name, second_name) values('petr', 'petrov'); commit*
```
postgres=# create table persons(id serial, first_name text, second_name text); insert into persons(first_name, second_name) values('ivan', 'ivanov'); insert into persons(first_name, second_name) values('petr', 'petrov'); commit;
CREATE TABLE
INSERT 0 1
INSERT 0 1
COMMIT
```
# 5.Эксперимент с уровнем изоляции по умолчанию
*5.1.Посмотреть текущий уровень изоляции: show transaction isolation level*
```
postgres=# show transaction isolation level;
 transaction_isolation
-----------------------
 read committed
(1 row)

```
*5.2.Начать новую транзакцию в обоих сессиях с дефолтным (не меняя) уровнем изоляции*
```
postgres=# BEGIN;
BEGIN
```
*5.3.В первой сессии добавить новую запись insert into persons(first_name, second_name) values('sergey', 'sergeev')*
```
postgres=*# insert into persons(first_name, second_name) values('sergey', 'sergeev');
INSERT 0 1
```
*5.4.Cделать select * from persons во второй сессии*
```
postgres=# BEGIN;
BEGIN
postgres=*# select * from persons;
 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
(2 rows)

```
**5.5.Видите ли вы новую запись и если да то почему?**
Нет, потому что первая транзация, где выполнялся INSERT - UNCOMMITED, поэтому 2 транзакция при уровне изоляции read commited не делает SELECT "граязных" данных, которые не зафиксированны в 1 транзакции.

*5.6.Завершить первую транзакцию - commit*
```
postgres=*# COMMIT;
COMMIT
```
*5.7.Cделать select * from persons во второй сессии*
```
postgres=*# select * from persons;
 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
(3 rows)

```
**5.8.Видите ли вы новую запись и если да то почему?**
Да, потому что первая транзакция зафиксирована, данные не "грязные" и они доступны для чтения

*5.9.Завершите транзакцию во второй сессии*
```
postgres=*# COMMIT;
COMMIT
```
# 6.Эксперимент с уровнем изоляции repeatable read
*6.1.Начать новые но уже repeatable read транзации - set transaction isolation level repeatable read*

*6.2.В первой сессии добавить новую запись insert into persons(first_name, second_name) values('sveta', 'svetova')*

*6.3.Сделать select * from persons во второй сессии*

**6.4.Видите ли вы новую запись и если да то почему?**

*6.5.Завершить первую транзакцию - commit*

*6.6.Сделать select * from persons во второй сессии*

**6.7.Видите ли вы новую запись и если да то почему?**

*6.8.Завершить вторую транзакцию*

*6.9.Сделать select * from persons во второй сессии*

**6.10.Видите ли вы новую запись и если да то почему?**
