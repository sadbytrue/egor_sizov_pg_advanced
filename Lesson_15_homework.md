# 0.Создание виртуальной машины и развертывание кластера PostgreSQL
*0.1. Создание виртуальной машины*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_43.png)
```
PS C:\Users\Egor> type C:\Users\Egor\.ssh\id_ed25519.pub | clip
PS C:\Users\Egor> ssh ssh-rsa@130.193.36.118
The authenticity of host '130.193.36.118 (130.193.36.118)' can't be established.
ECDSA key fingerprint is SHA256:FaWpebCjlD07v8wVKN8alG3rw+4c0JF0Baf4xsZqXDk.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '130.193.36.118' (ECDSA) to the list of known hosts.
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-91-generic x86_64)
```
*0.2. Установка postgres*
```
ssh-rsa@lesson15:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@lesson15:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```
*0.3. Развертывание базы, сздание и наполнение таблиц*
```

```
# 1.Создание триггера для поддержки данных в витрине в актуальном состоянии
*1.1. В БД создана структура, описывающая товары (таблица goods) и продажи (таблица sales).
Есть запрос для генерации отчета – сумма продаж по каждому товару.
БД была денормализована, создана таблица (витрина), структура которой повторяет структуру отчета.
Создать триггер на таблице продаж, для поддержки данных в витрине в актуальном состоянии (вычисляющий при каждой продаже сумму и записывающий её в витрину)
Подсказка: не забыть, что кроме INSERT есть еще UPDATE и DELETE*
```

```
*1.2. Тестирование работы триггеров при разных сценариях*
```

```
# 2.Задание со звездочкой *
*2.1. Чем такая схема (витрина+триггер) предпочтительнее отчета, создаваемого "по требованию" (кроме производительности)? Подсказка: В реальной жизни возможны изменения цен.*
```

```
