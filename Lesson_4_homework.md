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
# 3.Создание и монтирование диска
*3.1.Создайте новый диск к ВМ размером 10GB*
```

```
*3.2.Добавьте свеже-созданный диск к виртуальной машине - надо зайти в режим ее редактирования и дальше выбрать пункт attach existing disk*
```

```
*3.3.Проинициализируйте диск согласно инструкции и подмонтировать файловую систему, только не забывайте менять имя диска на актуальное, в вашем случае это скорее всего будет /dev/sdb - https://www.digitalocean.com/community/tutorials/how-to-partition-and-format-storage-devices-in-linux*
```

```
*3.4.Перезагрузите инстанс и убедитесь, что диск остается примонтированным (если не так смотрим в сторону fstab)*
```

```
*3.5.Сделайте пользователя postgres владельцем /mnt/data - chown -R postgres:postgres /mnt/data/*
```

```
# 4.Перенос данных на премонтированный диск
*4.1.Перенесите содержимое /var/lib/postgres/15 в /mnt/data - mv /var/lib/postgresql/15/mnt/data*
```

```
*4.2.Попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 15 main start*
```

```
*4.3.Напишите получилось или нет и почему*
```

```
*4.4.Задание: найти конфигурационный параметр в файлах раположенных в /etc/postgresql/15/main который надо поменять и поменяйте его*
```

```
*4.5.Напишите что и почему поменяли*
```

```
*4.6.Попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 15 main start*
```

```
*4.7.Напишите получилось или нет и почему*
```

```
*4.8.Зайдите через через psql и проверьте содержимое ранее созданной таблицы*
```

```
*4.9.Задание со звездочкой: не удаляя существующий инстанс ВМ сделайте новый, поставьте на его PostgreSQL, удалите файлы с данными из /var/lib/postgres, перемонтируйте внешний диск который сделали ранее от первой виртуальной машины ко второй и запустите PostgreSQL на второй машине так чтобы он работал с данными на внешнем диске, расскажите как вы это сделали и что в итоге получилось*
```

```