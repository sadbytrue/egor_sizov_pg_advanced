# 1.Создание виртуальной машины
*1.1.Создайте виртуальную машину c Ubuntu 20.04/22.04 LTS в GCE/ЯО/Virtual Box/докере*
```

```
# 2.Установка PostgreSQL, создание таблицы и остановка Postgresql
*2.1.Поставьте на нее PostgreSQL 15 через sudo apt*
```

```
*2.2.Проверьте что кластер запущен через sudo -u postgres pg_lsclusters*
```

```
*2.3.Зайдите из под пользователя postgres в psql и сделайте произвольную таблицу с произвольным содержимым
postgres=# create table test(c1 text);
postgres=# insert into test values('1');
\q*
```

```
*2.4.Остановите postgres например через sudo -u postgres pg_ctlcluster 15 main stop*
```

```



