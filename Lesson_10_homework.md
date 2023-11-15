# 1.Создание виртуальной машины и кластера PostgreSQL с настройками по умолчанию
*1.1.Создаем ВМ/докер c ПГ*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_16.png)
```
PS C:\Users\Egor> type C:\Users\Egor\.ssh\id_ed25519.pub | clip
PS C:\Users\Egor> ssh ssh-rsa@51.250.80.65
The authenticity of host '51.250.80.65 (51.250.80.65)' can't be established.
ECDSA key fingerprint is SHA256:vg5QOyopgy35zPOUo2nHpdxIFqxavrMV4o7aypxhDY0.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '51.250.80.65' (ECDSA) to the list of known hosts.
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-88-generic x86_64)
```
# 2.Создание БД со схемой и таблицу с данными
*2.1.Создаем БД, схему и в ней таблицу*
```

```
*2.2.Заполним таблицу автосгенерированными 100 записями*
```

```
# 3.Настройка и осуществление логического бэкапирования и восстановления
*3.1.Под линукс пользователем Postgres создадим каталог для бэкапов*
```

```
*3.2.Сделаем логический бэкап используя утилиту COPY*
```

```
*3.3.Восстановим во 2 таблицу данные из бэкапа*
```

```
# 4.Бэкапирование и восстановление с помощью pg_dump, pg_restore
*4.1.Используя утилиту pg_dump создадим бэкап в кастомном сжатом формате двух таблиц*
```

```
*4.2.Используя утилиту pg_restore восстановим в новую БД ТОЛЬКО вторую таблицу*
```

```
