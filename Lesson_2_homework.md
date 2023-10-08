**Занятие 2. Домашнее задание**
# 1.Создание ВМ в Яндекс Облаке
*Создать новый проект в Google Cloud Platform, Яндекс облако или на любых ВМ, докере*

*Далее создать инстанс виртуальной машины с дефолтными параметрами*

# 2.Настройка подключения по ssh
*Добавить свой ssh ключ в metadata ВМ*

*Зайти удаленным ssh (первая сессия), не забывайте про ssh-add*

# 3.Установка интсанса PostgreSQL
*Поставить PostgreSQL*

# 4.Запуск второй сессии. Создание тестовой таблицы. Отключение autocommit
*Зайти вторым ssh (вторая сессия)*

*Запустить везде psql из под пользователя postgres*

*Выключить auto commit*

*Сделать в первой сессии новую таблицу и наполнить ее данными create table persons(id serial, first_name text, second_name text); insert into persons(first_name, second_name) values('ivan', 'ivanov'); insert into persons(first_name, second_name) values('petr', 'petrov'); commit*

# 5.Эксперимент с уровнем изоляции по умолчанию
*Посмотреть текущий уровень изоляции: show transaction isolation level*

*Начать новую транзакцию в обоих сессиях с дефолтным (не меняя) уровнем изоляции*

*В первой сессии добавить новую запись insert into persons(first_name, second_name) values('sergey', 'sergeev')*

*Cделать select * from persons во второй сессии*

*Видите ли вы новую запись и если да то почему?*

*Завершить первую транзакцию - commit*

*Cделать select * from persons во второй сессии*

*Видите ли вы новую запись и если да то почему?*

*Завершите транзакцию во второй сессии*

# 6.Эксперимент с уровнем изоляции repeatable read

