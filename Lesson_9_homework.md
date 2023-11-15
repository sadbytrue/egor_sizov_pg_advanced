# 1.Создание виртуальной машины и кластера PostgreSQL с настройками по умолчанию
*1.1.Развернуть виртуальную машину любым удобным способом*
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
*1.2.Поставить на неё PostgreSQL 15 любым способом*
```

```
# 2.Настройка PostgreSQL на максимальную производительность и тестирование производительности
*2.1.Настроить кластер PostgreSQL 15 на максимальную производительность не обращая внимание на возможные проблемы с надежностью в случае аварийной перезагрузки виртуальной машины*
```

```
*2.2.Нагрузить кластер через утилиту через утилиту pgbench*
```

```
*2.3.Написать какого значения tps удалось достичь, показать какие параметры в какие значения устанавливали и почему*
```

```
# 3.Задание со звездочкой
*3.1.Аналогично протестировать через утилиту https://github.com/Percona-Lab/sysbench-tpcc (требует установки https://github.com/akopytov/sysbench)*
```

```
