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

# 4.Запуск второй сессии. Создание тестовой таблицы. Отключение autocommit
*4.1.Зайти вторым ssh (вторая сессия)*

*4.2.Запустить везде psql из под пользователя postgres*

*4.3.Выключить auto commit*

*4.4.Сделать в первой сессии новую таблицу и наполнить ее данными create table persons(id serial, first_name text, second_name text); insert into persons(first_name, second_name) values('ivan', 'ivanov'); insert into persons(first_name, second_name) values('petr', 'petrov'); commit*

# 5.Эксперимент с уровнем изоляции по умолчанию
*5.1.Посмотреть текущий уровень изоляции: show transaction isolation level*

*5.2.Начать новую транзакцию в обоих сессиях с дефолтным (не меняя) уровнем изоляции*

*5.3.В первой сессии добавить новую запись insert into persons(first_name, second_name) values('sergey', 'sergeev')*

*5.4.Cделать select * from persons во второй сессии*

**5.5.Видите ли вы новую запись и если да то почему?**

*5.6.Завершить первую транзакцию - commit*

*5.7.Cделать select * from persons во второй сессии*

**5.8.Видите ли вы новую запись и если да то почему?**

*5.9.Завершите транзакцию во второй сессии*

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
