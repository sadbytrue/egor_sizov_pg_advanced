# 0.Создание 4 виртуальных машин и установка postgres
*0.1. Создание 4 виртуальных машин*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_33.png)
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_34.png)
*0.2. Установка postgres*
```
sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15
```
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_35.png)
# 1.Настройка логической репликации на ВМ 1
*1.1. На 1 ВМ создаем таблицы test для записи, test2 для запросов на чтение*
```

```
*1.2. Создаем публикацию таблицы test и подписываемся на публикацию таблицы test2 с ВМ №2*
```

```
# 2.Настройка логической репликации на ВМ 2
*2.1. На 2 ВМ создаем таблицы test2 для записи, test для запросов на чтение*
```

```
*2.2. Создаем публикацию таблицы test2 и подписываемся на публикацию таблицы test1 с ВМ №1*
```

```
# 3.Настройка физической репликации на ВМ 3
*3.1. 3 ВМ использовать как реплику для чтения и бэкапов (подписаться на таблицы из ВМ №1 и №2 )*
```

```
# 4.Настройка каскадной репликации на ВМ 4
*3.1. Реализовать горячее реплицирование для высокой доступности на 4ВМ. Источником должна выступать ВМ №3. Написать с какими проблемами столкнулись*
```

```
