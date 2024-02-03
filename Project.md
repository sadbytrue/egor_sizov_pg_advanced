# 0.Материалы проекта
*0.1. Презентация*

https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Project_Presentation.pptx

*0.2. Базовая архитектура*

https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Base_Arch.drawio

![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Base_Arch.drawio.png)

*0.3. Архитектура с отдельным инстансом под backup и OLAP*

https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Separate_OLTP_OLAP_Arch.drawio

![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Separate_OLTP_OLAP_Arch.drawio.png)

*0.4. Архитектура с оптимизированным межсетеввым трафиком*

https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Opt_Traffic_Arch.drawio

![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Opt_Traffic_Arch.drawio.png)

*0.2. Установка postgres*
```
ssh-rsa@lesson15:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@lesson15:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
