# 0.Создание виртуальной машины и кластера PostgreSQL с настройками по умолчанию
*0.1.Создание инстанса ВМ*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_15.png)
```
PS C:\Users\Egor> type C:\Users\Egor\.ssh\id_ed25519.pub | clip
PS C:\Users\Egor> ssh ssh-rsa@158.160.49.228
The authenticity of host '158.160.49.228 (158.160.49.228)' can't be established.
ECDSA key fingerprint is SHA256:gbOM7Ddd9XCe5gebedlyc2r4QhMcqTFBr5ITaVkPl+I.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '158.160.49.228' (ECDSA) to the list of known hosts.
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-87-generic x86_64)
```
*0.2.Установка PostgreSQL с настройками по умолчанию*
```
ssh-rsa@lesson7:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@lesson7:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log

ssh-rsa@lesson7:~$ sudo -u postgres psql
could not change directory to "/home/ssh-rsa": Permission denied
psql (15.4 (Ubuntu 15.4-2.pgdg22.04+1))
Type "help" for help.

postgres=# exit
ssh-rsa@lesson7:~$
```
# 1.Тестирование объема журналирования с настройками по умолчанию
*1.1.Настройте выполнение контрольной точки раз в 30 секунд*
```

```
*1.2.10 минут c помощью утилиты pgbench подавайте нагрузку*
```

```
*1.3.Измерьте, какой объем журнальных файлов был сгенерирован за это время. Оцените, какой объем приходится в среднем на одну контрольную точку*
```

```



# 2.Сравнение работы в синхронном и асинхронном режиме
*2.1.Проверьте данные статистики: все ли контрольные точки выполнялись точно по расписанию*
```

```
*2.2.Почему так произошло?*



*2.3.Сравните tps в синхронном/асинхронном режиме утилитой pgbench*
```

```
*2.4.Объясните полученный результат*



# 3.Тестирование режима контрольной суммы таблицы
*3.1.Создайте новый кластер с включенной контрольной суммой страниц*
```

```
*3.2.Создайте таблицу*
```

```
*3.3.Вставьте несколько значений*
```

```
*3.4.Выключите кластер*
```

```
*3.5.Измените пару байт в таблице*
```

```
*3.6.Включите кластер и сделайте выборку из таблицы*
```

```
*3.7.Что и почему произошло?*



*3.8.Как проигнорировать ошибку и продолжить работу?*



```

```
