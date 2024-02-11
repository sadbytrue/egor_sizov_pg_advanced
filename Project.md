# 0.Материалы проекта
*0.1. Презентация*

https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Project_Presentation.pptx

*0.2. Базовая архитектура*

https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Base_Arch_NEW.drawio

![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Base_Arch_NEW.drawio.png)

*0.3. Архитектура с отдельным инстансом под backup и OLAP*

https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Separate_OLTP_OLAP_Arch_NEW.drawio

![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Separate_OLTP_OLAP_Arch_NEW.drawio.png)

*0.4. Архитектура с оптимизированным межсетеввым трафиком*

https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Opt_Traffic_Arch_NEW.drawio

![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Opt_Traffic_Arch_NEW.drawio.png)

# 1.Подготовка к развертыванию
*1.1. Установка Yandex Cloud CLI*
```
PS C:\Windows\system32> iex (New-Object System.Net.WebClient).DownloadString('https://storage.yandexcloud.net/yandexcloud-yc/install.ps1')
Downloading yc 0.117.0
Yandex Cloud CLI 0.117.0 windows/amd64
Now we have zsh completion. Type "echo 'source C:\Users\Egor\yandex-cloud\completion.zsh.inc' >>  ~/.zshrc" to install itAdd yc installation dir to your PATH? [Y/n]: Y
PS C:\Windows\system32> yc init
Welcome! This command will take you through the configuration process.
Please go to https://oauth.yandex.ru/authorize?response_type=token&client_id=*** in order to obtain OAuth token.

Please enter OAuth token: ***
You have one cloud available: 'cloud-sizyi-egor' (id = ***). It is going to be used by default.
Please choose folder to use:
 [1] default (id = ***)
 [2] Create a new folder
Please enter your numeric choice: 1
Your current folder has been set to 'default' (id = ***).
Do you want to configure a default Compute zone? [Y/n] Y
Which zone do you want to use as a profile default?
 [1] ru-central1-a
 [2] ru-central1-b
 [3] ru-central1-c
 [4] ru-central1-d
 [5] Don't set default zone
Please enter your numeric choice: 1
Your profile default Compute zone has been set to 'ru-central1-a'.
PS C:\Windows\system32> yc config list
token: ***
cloud-id: ***
folder-id: ***
compute-default-zone: ru-central1-a
PS C:\Windows\system32>
```
*1.2. Файл с метаданными пользователя для подключения к ВМ*
```
#cloud-config
datasource:
 Ec2:
  strict_id: false
ssh_pwauth: no
users:
- name: ssh-rsa
  sudo: ALL=(ALL) NOPASSWD:ALL
  shell: /bin/bash
  ssh_authorized_keys:
  - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIALwPSUA8bw/xh8zkEaME/uauGwFs7FtpFba4ysmTChX egor@WIN-GRJINGE790V
runcmd: []
```
# 2.Базовая архитектура
| Host | Internal IP | Public IP |
| ------ | ------ | ------ |
| postgres1 |  |  |
| postgres2 |  |  |
| etcd |  |  |
| proxy |  |  |

*2.1. Развертывание ВМ*

ВМ 1 для postgres в географической зоне 1

```
PS C:\Windows\system32> yc compute instance create --name postgres1 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=10,auto-delete=true --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 8G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname postgres1
```

ВМ 2 для postgres в географической зоне 2

```
PS C:\Windows\system32> yc compute instance create --name postgres2 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=10,auto-delete=true --network-interface subnet-name=default-ru-central1-b,nat-ip-version=ipv4 --memory 8G --cores 2 --zone ru-central1-b --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname postgres2
```

ВМ 3 для etcd в географической зоне 1
```
PS C:\Windows\system32> yc compute instance create --name etcd --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=10,auto-delete=true --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 4G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname etcd
```

ВМ 4 для proxy в географической зоне 1
```
PS C:\Windows\system32> yc compute instance create --name proxy --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=10,auto-delete=true --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 4G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname proxy
```

*2.2. Установка postgres, patroni, etcd и haproxy*

ВМ 1 установка postgres, patroni, etcd и haproxy

```
PS C:\Users\Egor> ssh ssh-rsa@<postgres1_public_ip>
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':

ssh-rsa@postgres1:~$ sudo apt install net-tools

PS C:\Windows\system32> sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@postgres1:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
ssh-rsa@postgres1:~$ sudo systemctl stop postgresql
ssh-rsa@postgres1:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 down   postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log

ssh-rsa@postgres1:~$ sudo ln -s /usr/lib/postgresql/15/bin/* /usr/sbin/

ssh-rsa@postgres1:~$ sudo apt install python-is-python3
ssh-rsa@postgres1:~$ sudo apt install python3-testresources
ssh-rsa@postgres1:~$ sudo apt install python3-pip
ssh-rsa@postgres1:~$ pip3 install --upgrade setuptools
ssh-rsa@postgres1:~$ sudo apt-get install --reinstall libpq-dev
ssh-rsa@postgres1:~$ sudo pip3 install psycopg2

ssh-rsa@postgres1:~$ sudo pip3 install patroni

ssh-rsa@postgres1:~$ sudo pip3 install python-etcd
```

ВМ 2 установка postgres, patroni, etcd и haproxy

```
PS C:\Users\Egor> ssh ssh-rsa@<postgres2_public_ip>
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-92-generic x86_64)

ssh-rsa@postgres2:~$  sudo apt install net-tools

ssh-rsa@postgres2:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@postgres2:~$ sudo systemctl stop postgresql
ssh-rsa@postgres2:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 down   postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log

ssh-rsa@postgres2:~$ sudo ln -s /usr/lib/postgresql/15/bin/* /usr/sbin/

ssh-rsa@postgres1:~$ sudo apt install python-is-python3
ssh-rsa@postgres1:~$ sudo apt install python3-testresources
ssh-rsa@postgres1:~$ sudo apt install python3-pip
ssh-rsa@postgres1:~$ pip3 install --upgrade setuptools
ssh-rsa@postgres1:~$ sudo apt-get install --reinstall libpq-dev
ssh-rsa@postgres1:~$ sudo pip3 install psycopg2

ssh-rsa@postgres1:~$ sudo pip3 install patroni

ssh-rsa@postgres1:~$ sudo pip3 install python-etcd
```

ВМ 3 установка etcd

```
PS C:\Users\Egor> ssh ssh-rsa@<etcd_public_ip>
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-92-generic x86_64)

ssh-rsa@etcd:~$ sudo apt install net-tools
ssh-rsa@etcd:~$ sudo apt -y install etcd
```

ВМ 4 установка haproxy

```
PS C:\Users\Egor> ssh ssh-rsa@<haproxy_public_ip>
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-92-generic x86_64)

ssh-rsa@proxy:~$ sudo apt update
ssh-rsa@proxy:~$ sudo apt install net-tools

ssh-rsa@proxy:~$ sudo apt -y install haproxy
```
*2.3. Настройка etcd*

ВМ 3

```
PS C:\Users\Egor> ssh ssh-rsa@<etcd_public_ip>
ssh-rsa@etcd:~$ netstat -ltupn

ssh-rsa@etcd:~$ sudo nano /etc/default/etcd

#Внутренний IP
ETCD_LISTEN_PEER_URLS="http://<etcd_internal_ip>:2380"
ETCD_LISTEN_CLIENT_URLS="http://localhost:2379,http://<etcd_internal_ip>:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://<etcd_internal_ip>:2380"
ETCD_INITIAL_CLUSTER="default=http://<etcd_internal_ip>:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="http://<etcd_internal_ip>:2379"
ETCD_ENABLE_V2="true"

ssh-rsa@etcd:~$ sudo systemctl restart etcd
ssh-rsa@etcd:~$ sudo systemctl status etcd
● etcd.service - etcd - highly-available key value store
     Loaded: loaded (/lib/systemd/system/etcd.service; enabled; vendor preset: enabled)
     Active: active (running) since Sun 2024-02-04 22:05:15 UTC; 6s ago
       Docs: https://etcd.io/docs
             man:etcd
   Main PID: 5913 (etcd)
      Tasks: 7 (limit: 4558)
     Memory: 4.3M
        CPU: 68ms
     CGroup: /system.slice/etcd.service
             └─5913 /usr/bin/etcd

```
*2.4. Настройка patroni*

ВМ 1

```
PS C:\Users\Egor> ssh ssh-rsa@<postgres1_public_ip>
ssh-rsa@postgres1:~$ sudo nano /etc/patroni.yml

scope: postgres
namespace: /db/
name: postgres1

restapi:
    listen: <postgres1_internal_ip>:8008
    connect_address: <postgres1_public_ip>:8008

etcd:
    host: <etcd_public_ip>:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:

  initdb:
  - encoding: UTF8
  - data-checksums

  pg_hba:
  - host replication replicator 127.0.0.1/32 md5
  - host replication replicator <postgres1_public_ip>/0 md5
  - host replication replicator <postgres2_public_ip>/0 md5
  - host all all 0.0.0.0/0 md5

  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb
postgresql:
  listen: <postgres1_internal_ip>:5432
  connect_address: <postgres1_public_ip>:5432
  data_dir: /data/patroni
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: replicator
      password: replicator
    superuser:
      username: postgres
      password: postgres
  parameters:
      unix_socket_directories: '.'

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false

ssh-rsa@postgres1:~$ sudo mkdir -p /data/patroni
ssh-rsa@postgres1:~$ sudo chown postgres:postgres /data/patroni
ssh-rsa@postgres1:~$ sudo chmod 700 /data/patroni
ssh-rsa@postgres1:~$ sudo nano /etc/systemd/system/patroni.service

[Unit]
Description=High availability PostgreSQL Cluster
After=syslog.target network.target

[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/local/bin/patroni /etc/patroni.yml
KillMode=process
TimeoutSec=30
Restart=no

[Install]
WantedBy=multi-user.targ
```

ВМ 2

```
PS C:\Users\Egor> ssh ssh-rsa@<postgres2_public_ip>
ssh-rsa@postgres1:~$ sudo nano /etc/patroni.yml

scope: postgres
namespace: /db/
name: postgres2

restapi:
#Внутренний IP хоста
    listen: <postgres2_internal_ip>:8008
#Внешний IP хоста
    connect_address: <postgres2_public_ip>:8008

etcd:
    host: <etcd_public_ip>:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:

  initdb:
  - encoding: UTF8
  - data-checksums

  pg_hba:
  - host replication replicator 127.0.0.1/32 md5
  - host replication replicator <postgres1_public_ip>/0 md5
  - host replication replicator <postgres2_public_ip>/0 md5
  - host all all 0.0.0.0/0 md5

  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb
postgresql:
#Внутренний IP хоста
  listen: <postgres2_internal_ip>:5432
#Внутренний IP хоста
  connect_address: <postgres2_public_ip>:5432
  data_dir: /data/patroni
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: replicator
      password: replicator
    superuser:
      username: postgres
      password: postgres
  parameters:
      unix_socket_directories: '.'

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false

ssh-rsa@postgres1:~$ sudo mkdir -p /data/patroni
ssh-rsa@postgres1:~$ sudo chown postgres:postgres /data/patroni
ssh-rsa@postgres1:~$ sudo chmod 700 /data/patroni
ssh-rsa@postgres1:~$ sudo nano /etc/systemd/system/patroni.service

[Unit]
Description=High availability PostgreSQL Cluster
After=syslog.target network.target

[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/local/bin/patroni /etc/patroni.yml
KillMode=process
TimeoutSec=30
Restart=no

[Install]
WantedBy=multi-user.targ
```
*2.5. Включение patroni*

ВМ 1

```
ssh-rsa@postgres1:~$ sudo systemctl start patroni
ssh-rsa@postgres1:~$ sudo systemctl status patroni
```

ВМ 2

```
ssh-rsa@postgres2:~$ sudo systemctl start patroni
ssh-rsa@postgres2:~$ sudo systemctl status patroni
```
*2.6. Настройка HAProxy*

ВМ HAProxy

```
PS C:\Users\Egor> ssh ssh-rsa@<proxy_public_ip>

ssh-rsa@proxy:~$ sudo nano /etc/haproxy/haproxy.cfg

global
        maxconn 100
        log     127.0.0.1 local2

defaults
        log global
        mode tcp
        retries 2
        timeout client 30m
        timeout connect 4s
        timeout server 30m
        timeout check 5s
listen stats
    mode http
    bind *:7000
    stats enable
    stats uri /

listen postgres
    bind *:5000
    option httpchk
    http-check expect status 200
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
#Внешний IP хоста
    server node1 <postgres1_public_ip>:5432 maxconn 100 check port 8008
#Внешний IP хоста
    server node2 <postgres2_public_ip>:5432 maxconn 100 check port 8008

ssh-rsa@proxy:~$ ssh-rsa@proxy:~$ sudo systemctl restart haproxy
ssh-rsa@proxy:~$ sudo systemctl status haproxy
```
# 3.Архитектура с отдельной репликой для OLAP и backup
| Host | Internal IP | Public IP |
| ------ | ------ | ------ |
| postgres1 |  |  |
| postgres2 |  |  |
| postgres3 |  |  |
| etcd |  |  |
| proxy |  |  |

*3.1. Развертывание ВМ*

ВМ 1 для postgres в географической зоне 1

```
PS C:\Windows\system32> yc compute instance create --name postgres1 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=10,auto-delete=true --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 8G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname postgres1
```

ВМ 2 для postgres в географической зоне 2

```
PS C:\Windows\system32> yc compute instance create --name postgres2 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=10,auto-delete=true --network-interface subnet-name=default-ru-central1-b,nat-ip-version=ipv4 --memory 8G --cores 2 --zone ru-central1-b --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname postgres2
```

ВМ 3 для реплики postgres в географической зоне 1

```
PS C:\Windows\system32> yc compute instance create --name postgres3 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=10,auto-delete=true --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 8G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname postgres3
```

ВМ 4 для etcd в географической зоне 1
```
PS C:\Windows\system32> yc compute instance create --name etcd --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=10,auto-delete=true --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 4G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname etcd
```

ВМ 5 для proxy в географической зоне 1
```
PS C:\Windows\system32> yc compute instance create --name proxy --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=10,auto-delete=true --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 4G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname proxy
```

*3.2. Установка postgres, patroni, etcd и haproxy*

ВМ 1 установка postgres, patroni, etcd и haproxy

```
PS C:\Users\Egor> ssh ssh-rsa@<postgres1_public_ip>
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':

ssh-rsa@postgres1:~$ sudo apt install net-tools

PS C:\Windows\system32> sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@postgres1:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
ssh-rsa@postgres1:~$ sudo systemctl stop postgresql
ssh-rsa@postgres1:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 down   postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log

ssh-rsa@postgres1:~$ sudo ln -s /usr/lib/postgresql/15/bin/* /usr/sbin/

ssh-rsa@postgres1:~$ sudo apt install python-is-python3
ssh-rsa@postgres1:~$ sudo apt install python3-testresources
ssh-rsa@postgres1:~$ sudo apt install python3-pip
ssh-rsa@postgres1:~$ pip3 install --upgrade setuptools
ssh-rsa@postgres1:~$ sudo apt-get install --reinstall libpq-dev
ssh-rsa@postgres1:~$ sudo pip3 install psycopg2

ssh-rsa@postgres1:~$ sudo pip3 install patroni

ssh-rsa@postgres1:~$ sudo pip3 install python-etcd
```

ВМ 2 установка postgres, patroni, etcd и haproxy

```
PS C:\Users\Egor> ssh ssh-rsa@<postgres2_public_ip>
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-92-generic x86_64)

ssh-rsa@postgres2:~$  sudo apt install net-tools

ssh-rsa@postgres2:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@postgres2:~$ sudo systemctl stop postgresql
ssh-rsa@postgres2:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 down   postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log

ssh-rsa@postgres2:~$ sudo ln -s /usr/lib/postgresql/15/bin/* /usr/sbin/

ssh-rsa@postgres1:~$ sudo apt install python-is-python3
ssh-rsa@postgres1:~$ sudo apt install python3-testresources
ssh-rsa@postgres1:~$ sudo apt install python3-pip
ssh-rsa@postgres1:~$ pip3 install --upgrade setuptools
ssh-rsa@postgres1:~$ sudo apt-get install --reinstall libpq-dev
ssh-rsa@postgres1:~$ sudo pip3 install psycopg2

ssh-rsa@postgres1:~$ sudo pip3 install patroni

ssh-rsa@postgres1:~$ sudo pip3 install python-etcd
```

ВМ 3 установка postgres, patroni, etcd и haproxy

```
PS C:\Users\Egor> ssh ssh-rsa@<postgres3_public_ip>
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-92-generic x86_64)

ssh-rsa@postgres2:~$  sudo apt install net-tools

ssh-rsa@postgres2:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@postgres2:~$ sudo systemctl stop postgresql
ssh-rsa@postgres2:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 down   postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log

ssh-rsa@postgres2:~$ sudo ln -s /usr/lib/postgresql/15/bin/* /usr/sbin/

ssh-rsa@postgres1:~$ sudo apt install python-is-python3
ssh-rsa@postgres1:~$ sudo apt install python3-testresources
ssh-rsa@postgres1:~$ sudo apt install python3-pip
ssh-rsa@postgres1:~$ pip3 install --upgrade setuptools
ssh-rsa@postgres1:~$ sudo apt-get install --reinstall libpq-dev
ssh-rsa@postgres1:~$ sudo pip3 install psycopg2

ssh-rsa@postgres1:~$ sudo pip3 install patroni

ssh-rsa@postgres1:~$ sudo pip3 install python-etcd
```

ВМ 4 установка etcd

```
PS C:\Users\Egor> ssh ssh-rsa@<etcd_public_ip>
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-92-generic x86_64)

ssh-rsa@etcd:~$ sudo apt install net-tools
ssh-rsa@etcd:~$ sudo apt -y install etcd
```

ВМ 5 установка haproxy

```
PS C:\Users\Egor> ssh ssh-rsa@<haproxy_public_ip>
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-92-generic x86_64)

ssh-rsa@proxy:~$ sudo apt update
ssh-rsa@proxy:~$ sudo apt install net-tools

ssh-rsa@proxy:~$ sudo apt -y install haproxy
```
*3.3. Настройка etcd*

ВМ 4

```
PS C:\Users\Egor> ssh ssh-rsa@<etcd_public_ip>
ssh-rsa@etcd:~$ netstat -ltupn

ssh-rsa@etcd:~$ sudo nano /etc/default/etcd

#Внутренний IP
ETCD_LISTEN_PEER_URLS="http://<etcd_internal_ip>:2380"
ETCD_LISTEN_CLIENT_URLS="http://localhost:2379,http://<etcd_internal_ip>:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://<etcd_internal_ip>:2380"
ETCD_INITIAL_CLUSTER="default=http://<etcd_internal_ip>:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="http://<etcd_internal_ip>:2379"
ETCD_ENABLE_V2="true"

ssh-rsa@etcd:~$ sudo systemctl restart etcd
ssh-rsa@etcd:~$ sudo systemctl status etcd
● etcd.service - etcd - highly-available key value store
     Loaded: loaded (/lib/systemd/system/etcd.service; enabled; vendor preset: enabled)
     Active: active (running) since Sun 2024-02-04 22:05:15 UTC; 6s ago
       Docs: https://etcd.io/docs
             man:etcd
   Main PID: 5913 (etcd)
      Tasks: 7 (limit: 4558)
     Memory: 4.3M
        CPU: 68ms
     CGroup: /system.slice/etcd.service
             └─5913 /usr/bin/etcd

```
*3.4. Настройка patroni*

ВМ 1

```
PS C:\Users\Egor> ssh ssh-rsa@<postgres1_public_ip>
ssh-rsa@postgres1:~$ sudo nano /etc/patroni.yml

scope: postgres
namespace: /db/
name: postgres1

restapi:
    listen: <postgres1_internal_ip>:8008
    connect_address: <postgres1_public_ip>:8008

etcd:
    host: <etcd_public_ip>:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:

  initdb:
  - encoding: UTF8
  - data-checksums

  pg_hba:
  - host replication replicator 127.0.0.1/32 md5
  - host replication replicator <postgres1_public_ip>/0 md5
  - host replication replicator <postgres2_public_ip>/0 md5
  - host replication replicator <postgres3_public_ip>/0 md5
  - host all all 0.0.0.0/0 md5

  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb
postgresql:
  listen: <postgres1_internal_ip>:5432
  connect_address: <postgres1_public_ip>:5432
  data_dir: /data/patroni
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: replicator
      password: replicator
    superuser:
      username: postgres
      password: postgres
  parameters:
      unix_socket_directories: '.'

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false

ssh-rsa@postgres1:~$ sudo mkdir -p /data/patroni
ssh-rsa@postgres1:~$ sudo chown postgres:postgres /data/patroni
ssh-rsa@postgres1:~$ sudo chmod 700 /data/patroni
ssh-rsa@postgres1:~$ sudo nano /etc/systemd/system/patroni.service

[Unit]
Description=High availability PostgreSQL Cluster
After=syslog.target network.target

[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/local/bin/patroni /etc/patroni.yml
KillMode=process
TimeoutSec=30
Restart=no

[Install]
WantedBy=multi-user.targ
```

ВМ 2

```
PS C:\Users\Egor> ssh ssh-rsa@<postgres2_public_ip>
ssh-rsa@postgres1:~$ sudo nano /etc/patroni.yml

scope: postgres
namespace: /db/
name: postgres2

restapi:
#Внутренний IP хоста
    listen: <postgres2_internal_ip>:8008
#Внешний IP хоста
    connect_address: <postgres2_public_ip>:8008

etcd:
    host: <etcd_public_ip>:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:

  initdb:
  - encoding: UTF8
  - data-checksums

  pg_hba:
  - host replication replicator 127.0.0.1/32 md5
  - host replication replicator <postgres1_public_ip>/0 md5
  - host replication replicator <postgres2_public_ip>/0 md5
  - host replication replicator <postgres3_public_ip>/0 md5
  - host all all 0.0.0.0/0 md5

  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb
postgresql:
#Внутренний IP хоста
  listen: <postgres2_internal_ip>:5432
#Внутренний IP хоста
  connect_address: <postgres2_public_ip>:5432
  data_dir: /data/patroni
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: replicator
      password: replicator
    superuser:
      username: postgres
      password: postgres
  parameters:
      unix_socket_directories: '.'

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false

ssh-rsa@postgres1:~$ sudo mkdir -p /data/patroni
ssh-rsa@postgres1:~$ sudo chown postgres:postgres /data/patroni
ssh-rsa@postgres1:~$ sudo chmod 700 /data/patroni
ssh-rsa@postgres1:~$ sudo nano /etc/systemd/system/patroni.service

[Unit]
Description=High availability PostgreSQL Cluster
After=syslog.target network.target

[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/local/bin/patroni /etc/patroni.yml
KillMode=process
TimeoutSec=30
Restart=no

[Install]
WantedBy=multi-user.targ
```

ВМ 3

```
PS C:\Users\Egor> ssh ssh-rsa@<postgres3_public_ip>
ssh-rsa@postgres1:~$ sudo nano /etc/patroni.yml

scope: postgres
namespace: /db/
name: postgres3

restapi:
#Внутренний IP хоста
    listen: <postgres3_internal_ip>:8008
#Внешний IP хоста
    connect_address: <postgres3_public_ip>:8008

etcd:
    host: <etcd_public_ip>:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:

  initdb:
  - encoding: UTF8
  - data-checksums

  pg_hba:
  - host replication replicator 127.0.0.1/32 md5
  - host replication replicator <postgres1_public_ip>/0 md5
  - host replication replicator <postgres2_public_ip>/0 md5
  - host replication replicator <postgres3_public_ip>/0 md5
  - host all all 0.0.0.0/0 md5

  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb
postgresql:
#Внутренний IP хоста
  listen: <postgres3_internal_ip>:5432
#Внутренний IP хоста
  connect_address: <postgres3_public_ip>:5432
  data_dir: /data/patroni
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: replicator
      password: replicator
    superuser:
      username: postgres
      password: postgres
  parameters:
      unix_socket_directories: '.'

tags:
    nofailover: true
    noloadbalance: false
    clonefrom: true
    nosync: true

ssh-rsa@postgres1:~$ sudo mkdir -p /data/patroni
ssh-rsa@postgres1:~$ sudo chown postgres:postgres /data/patroni
ssh-rsa@postgres1:~$ sudo chmod 700 /data/patroni
ssh-rsa@postgres1:~$ sudo nano /etc/systemd/system/patroni.service

[Unit]
Description=High availability PostgreSQL Cluster
After=syslog.target network.target

[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/local/bin/patroni /etc/patroni.yml
KillMode=process
TimeoutSec=30
Restart=no

[Install]
WantedBy=multi-user.targ
```
*3.5. Включение patroni*

ВМ 1

```
ssh-rsa@postgres1:~$ sudo systemctl start patroni
ssh-rsa@postgres1:~$ sudo systemctl status patroni
```

ВМ 2

```
ssh-rsa@postgres2:~$ sudo systemctl start patroni
ssh-rsa@postgres2:~$ sudo systemctl status patroni
```

ВМ 3

```
ssh-rsa@postgres3:~$ sudo systemctl start patroni
ssh-rsa@postgres3:~$ sudo systemctl status patroni
```
*3.6. Настройка HAProxy*

ВМ 5 HAProxy

```
PS C:\Users\Egor> ssh ssh-rsa@<proxy_public_ip>

ssh-rsa@proxy:~$ sudo nano /etc/haproxy/haproxy.cfg

global
        maxconn 100
        log     127.0.0.1 local2

defaults
        log global
        mode tcp
        retries 2
        timeout client 30m
        timeout connect 4s
        timeout server 30m
        timeout check 5s
listen stats
    mode http
    bind *:7000
    stats enable
    stats uri /

listen postgres
    bind *:5000
    option httpchk
    http-check expect status 200
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
#Внешний IP хоста
    server node1 <postgres1_public_ip>:5432 maxconn 100 check port 8008
#Внешний IP хоста
    server node2 <postgres2_public_ip>:5432 maxconn 100 check port 8008
#Внешний IP хоста
    server node3 <postgres3_public_ip>:5432 maxconn 100 check port 8008

ssh-rsa@proxy:~$ ssh-rsa@proxy:~$ sudo systemctl restart haproxy
ssh-rsa@proxy:~$ sudo systemctl status haproxy
```
# 4.Архитектура с отдельными репликами для OLAP и backup в каждой географиеческой зоне
| Host | Internal IP | Public IP |
| ------ | ------ | ------ |
| postgres1 |  |  |
| postgres2 |  |  |
| postgres3 |  |  |
| postgres4 |  |  |
| etcd |  |  |
| proxy |  |  |

*4.1. Развертывание ВМ*

ВМ 1 для postgres в географической зоне 1

```
PS C:\Windows\system32> yc compute instance create --name postgres1 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=10,auto-delete=true --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 8G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname postgres1
```

ВМ 2 для postgres в географической зоне 2

```
PS C:\Windows\system32> yc compute instance create --name postgres2 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=10,auto-delete=true --network-interface subnet-name=default-ru-central1-b,nat-ip-version=ipv4 --memory 8G --cores 2 --zone ru-central1-b --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname postgres2
```

ВМ 3 для реплики postgres в географической зоне 1

```
PS C:\Windows\system32> yc compute instance create --name postgres3 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=10,auto-delete=true --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 8G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname postgres3
```

ВМ 4 для реплики postgres в географической зоне 2

```
PS C:\Windows\system32> yc compute instance create --name postgres4 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=10,auto-delete=true --network-interface subnet-name=default-ru-central1-b,nat-ip-version=ipv4 --memory 8G --cores 2 --zone ru-central1-b --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname postgres4
```

ВМ 5 для etcd в географической зоне 1
```
PS C:\Windows\system32> yc compute instance create --name etcd --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=10,auto-delete=true --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 4G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname etcd
```

ВМ 6 для proxy в географической зоне 1
```
PS C:\Windows\system32> yc compute instance create --name proxy --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=10,auto-delete=true --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 4G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname proxy
```

*4.2. Установка postgres, patroni, etcd и haproxy*

ВМ 1 установка postgres, patroni, etcd и haproxy

```
PS C:\Users\Egor> ssh ssh-rsa@<postgres1_public_ip>
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':

ssh-rsa@postgres1:~$ sudo apt install net-tools

PS C:\Windows\system32> sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@postgres1:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
ssh-rsa@postgres1:~$ sudo systemctl stop postgresql
ssh-rsa@postgres1:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 down   postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log

ssh-rsa@postgres1:~$ sudo ln -s /usr/lib/postgresql/15/bin/* /usr/sbin/

ssh-rsa@postgres1:~$ sudo apt install python-is-python3
ssh-rsa@postgres1:~$ sudo apt install python3-testresources
ssh-rsa@postgres1:~$ sudo apt install python3-pip
ssh-rsa@postgres1:~$ pip3 install --upgrade setuptools
ssh-rsa@postgres1:~$ sudo apt-get install --reinstall libpq-dev
ssh-rsa@postgres1:~$ sudo pip3 install psycopg2

ssh-rsa@postgres1:~$ sudo pip3 install patroni

ssh-rsa@postgres1:~$ sudo pip3 install python-etcd
```

ВМ 2 установка postgres, patroni, etcd и haproxy

```
PS C:\Users\Egor> ssh ssh-rsa@<postgres2_public_ip>
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-92-generic x86_64)

ssh-rsa@postgres2:~$  sudo apt install net-tools

ssh-rsa@postgres2:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@postgres2:~$ sudo systemctl stop postgresql
ssh-rsa@postgres2:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 down   postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log

ssh-rsa@postgres2:~$ sudo ln -s /usr/lib/postgresql/15/bin/* /usr/sbin/

ssh-rsa@postgres1:~$ sudo apt install python-is-python3
ssh-rsa@postgres1:~$ sudo apt install python3-testresources
ssh-rsa@postgres1:~$ sudo apt install python3-pip
ssh-rsa@postgres1:~$ pip3 install --upgrade setuptools
ssh-rsa@postgres1:~$ sudo apt-get install --reinstall libpq-dev
ssh-rsa@postgres1:~$ sudo pip3 install psycopg2

ssh-rsa@postgres1:~$ sudo pip3 install patroni

ssh-rsa@postgres1:~$ sudo pip3 install python-etcd
```

ВМ 3 установка postgres, patroni, etcd и haproxy

```
PS C:\Users\Egor> ssh ssh-rsa@<postgres3_public_ip>
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-92-generic x86_64)

ssh-rsa@postgres2:~$  sudo apt install net-tools

ssh-rsa@postgres2:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@postgres2:~$ sudo systemctl stop postgresql
ssh-rsa@postgres2:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 down   postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log

ssh-rsa@postgres2:~$ sudo ln -s /usr/lib/postgresql/15/bin/* /usr/sbin/

ssh-rsa@postgres1:~$ sudo apt install python-is-python3
ssh-rsa@postgres1:~$ sudo apt install python3-testresources
ssh-rsa@postgres1:~$ sudo apt install python3-pip
ssh-rsa@postgres1:~$ pip3 install --upgrade setuptools
ssh-rsa@postgres1:~$ sudo apt-get install --reinstall libpq-dev
ssh-rsa@postgres1:~$ sudo pip3 install psycopg2

ssh-rsa@postgres1:~$ sudo pip3 install patroni

ssh-rsa@postgres1:~$ sudo pip3 install python-etcd
```

ВМ 4 установка postgres, patroni, etcd и haproxy

```
PS C:\Users\Egor> ssh ssh-rsa@<postgres4_public_ip>
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-92-generic x86_64)

ssh-rsa@postgres2:~$  sudo apt install net-tools

ssh-rsa@postgres2:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

ssh-rsa@postgres2:~$ sudo systemctl stop postgresql
ssh-rsa@postgres2:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 down   postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log

ssh-rsa@postgres2:~$ sudo ln -s /usr/lib/postgresql/15/bin/* /usr/sbin/

ssh-rsa@postgres1:~$ sudo apt install python-is-python3
ssh-rsa@postgres1:~$ sudo apt install python3-testresources
ssh-rsa@postgres1:~$ sudo apt install python3-pip
ssh-rsa@postgres1:~$ pip3 install --upgrade setuptools
ssh-rsa@postgres1:~$ sudo apt-get install --reinstall libpq-dev
ssh-rsa@postgres1:~$ sudo pip3 install psycopg2

ssh-rsa@postgres1:~$ sudo pip3 install patroni

ssh-rsa@postgres1:~$ sudo pip3 install python-etcd
```

ВМ 5 установка etcd

```
PS C:\Users\Egor> ssh ssh-rsa@<etcd_public_ip>
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-92-generic x86_64)

ssh-rsa@etcd:~$ sudo apt install net-tools
ssh-rsa@etcd:~$ sudo apt -y install etcd
```

ВМ 6 установка haproxy

```
PS C:\Users\Egor> ssh ssh-rsa@<haproxy_public_ip>
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-92-generic x86_64)

ssh-rsa@proxy:~$ sudo apt update
ssh-rsa@proxy:~$ sudo apt install net-tools

ssh-rsa@proxy:~$ sudo apt -y install haproxy
```
*4.3. Настройка etcd*

ВМ 5

```
PS C:\Users\Egor> ssh ssh-rsa@<etcd_public_ip>
ssh-rsa@etcd:~$ netstat -ltupn

ssh-rsa@etcd:~$ sudo nano /etc/default/etcd

#Внутренний IP
ETCD_LISTEN_PEER_URLS="http://<etcd_internal_ip>:2380"
ETCD_LISTEN_CLIENT_URLS="http://localhost:2379,http://<etcd_internal_ip>:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://<etcd_internal_ip>:2380"
ETCD_INITIAL_CLUSTER="default=http://<etcd_internal_ip>:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="http://<etcd_internal_ip>:2379"
ETCD_ENABLE_V2="true"

ssh-rsa@etcd:~$ sudo systemctl restart etcd
ssh-rsa@etcd:~$ sudo systemctl status etcd
● etcd.service - etcd - highly-available key value store
     Loaded: loaded (/lib/systemd/system/etcd.service; enabled; vendor preset: enabled)
     Active: active (running) since Sun 2024-02-04 22:05:15 UTC; 6s ago
       Docs: https://etcd.io/docs
             man:etcd
   Main PID: 5913 (etcd)
      Tasks: 7 (limit: 4558)
     Memory: 4.3M
        CPU: 68ms
     CGroup: /system.slice/etcd.service
             └─5913 /usr/bin/etcd

```
*4.4. Настройка patroni*

ВМ 1

```
PS C:\Users\Egor> ssh ssh-rsa@<postgres1_public_ip>
ssh-rsa@postgres1:~$ sudo nano /etc/patroni.yml

scope: postgres
namespace: /db/
name: postgres1

restapi:
    listen: <postgres1_internal_ip>:8008
    connect_address: <postgres1_public_ip>:8008

etcd:
    host: <etcd_public_ip>:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:

  initdb:
  - encoding: UTF8
  - data-checksums

  pg_hba:
  - host replication replicator 127.0.0.1/32 md5
  - host replication replicator <postgres1_public_ip>/0 md5
  - host replication replicator <postgres2_public_ip>/0 md5
  - host replication replicator <postgres3_public_ip>/0 md5
  - host replication replicator <postgres4_public_ip>/0 md5
  - host all all 0.0.0.0/0 md5

  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb
postgresql:
  listen: <postgres1_internal_ip>:5432
  connect_address: <postgres1_public_ip>:5432
  data_dir: /data/patroni
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: replicator
      password: replicator
    superuser:
      username: postgres
      password: postgres
  parameters:
      unix_socket_directories: '.'

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false

ssh-rsa@postgres1:~$ sudo mkdir -p /data/patroni
ssh-rsa@postgres1:~$ sudo chown postgres:postgres /data/patroni
ssh-rsa@postgres1:~$ sudo chmod 700 /data/patroni
ssh-rsa@postgres1:~$ sudo nano /etc/systemd/system/patroni.service

[Unit]
Description=High availability PostgreSQL Cluster
After=syslog.target network.target

[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/local/bin/patroni /etc/patroni.yml
KillMode=process
TimeoutSec=30
Restart=no

[Install]
WantedBy=multi-user.targ
```

ВМ 2

```
PS C:\Users\Egor> ssh ssh-rsa@<postgres2_public_ip>
ssh-rsa@postgres1:~$ sudo nano /etc/patroni.yml

scope: postgres
namespace: /db/
name: postgres2

restapi:
#Внутренний IP хоста
    listen: <postgres2_internal_ip>:8008
#Внешний IP хоста
    connect_address: <postgres2_public_ip>:8008

etcd:
    host: <etcd_public_ip>:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:

  initdb:
  - encoding: UTF8
  - data-checksums

  pg_hba:
  - host replication replicator 127.0.0.1/32 md5
  - host replication replicator <postgres1_public_ip>/0 md5
  - host replication replicator <postgres2_public_ip>/0 md5
  - host replication replicator <postgres3_public_ip>/0 md5
  - host replication replicator <postgres4_public_ip>/0 md5
  - host all all 0.0.0.0/0 md5

  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb
postgresql:
#Внутренний IP хоста
  listen: <postgres2_internal_ip>:5432
#Внутренний IP хоста
  connect_address: <postgres2_public_ip>:5432
  data_dir: /data/patroni
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: replicator
      password: replicator
    superuser:
      username: postgres
      password: postgres
  parameters:
      unix_socket_directories: '.'

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false

ssh-rsa@postgres1:~$ sudo mkdir -p /data/patroni
ssh-rsa@postgres1:~$ sudo chown postgres:postgres /data/patroni
ssh-rsa@postgres1:~$ sudo chmod 700 /data/patroni
ssh-rsa@postgres1:~$ sudo nano /etc/systemd/system/patroni.service

[Unit]
Description=High availability PostgreSQL Cluster
After=syslog.target network.target

[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/local/bin/patroni /etc/patroni.yml
KillMode=process
TimeoutSec=30
Restart=no

[Install]
WantedBy=multi-user.targ
```

ВМ 3

```
PS C:\Users\Egor> ssh ssh-rsa@<postgres3_public_ip>
ssh-rsa@postgres1:~$ sudo nano /etc/patroni.yml

scope: postgres
namespace: /db/
name: postgres3

restapi:
#Внутренний IP хоста
    listen: <postgres3_internal_ip>:8008
#Внешний IP хоста
    connect_address: <postgres3_public_ip>:8008

etcd:
    host: <etcd_public_ip>:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:

  initdb:
  - encoding: UTF8
  - data-checksums

  pg_hba:
  - host replication replicator 127.0.0.1/32 md5
  - host replication replicator <postgres1_public_ip>/0 md5
  - host replication replicator <postgres2_public_ip>/0 md5
  - host replication replicator <postgres3_public_ip>/0 md5
  - host replication replicator <postgres4_public_ip>/0 md5
  - host all all 0.0.0.0/0 md5

  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb
postgresql:
#Внутренний IP хоста
  listen: <postgres3_internal_ip>:5432
#Внутренний IP хоста
  connect_address: <postgres3_public_ip>:5432
  data_dir: /data/patroni
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: replicator
      password: replicator
    superuser:
      username: postgres
      password: postgres
  parameters:
      unix_socket_directories: '.'

tags:
    nofailover: true
    noloadbalance: false
    clonefrom: true
    nosync: true
    replicatefrom: postgres1

ssh-rsa@postgres1:~$ sudo mkdir -p /data/patroni
ssh-rsa@postgres1:~$ sudo chown postgres:postgres /data/patroni
ssh-rsa@postgres1:~$ sudo chmod 700 /data/patroni
ssh-rsa@postgres1:~$ sudo nano /etc/systemd/system/patroni.service

[Unit]
Description=High availability PostgreSQL Cluster
After=syslog.target network.target

[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/local/bin/patroni /etc/patroni.yml
KillMode=process
TimeoutSec=30
Restart=no

[Install]
WantedBy=multi-user.targ
```

ВМ 4

```
PS C:\Users\Egor> ssh ssh-rsa@<postgres4_public_ip>
ssh-rsa@postgres1:~$ sudo nano /etc/patroni.yml

scope: postgres
namespace: /db/
name: postgres4

restapi:
#Внутренний IP хоста
    listen: <postgres4_internal_ip>:8008
#Внешний IP хоста
    connect_address: <postgres4_public_ip>:8008

etcd:
    host: <etcd_public_ip>:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:

  initdb:
  - encoding: UTF8
  - data-checksums

  pg_hba:
  - host replication replicator 127.0.0.1/32 md5
  - host replication replicator <postgres1_public_ip>/0 md5
  - host replication replicator <postgres2_public_ip>/0 md5
  - host replication replicator <postgres3_public_ip>/0 md5
  - host replication replicator <postgres4_public_ip>/0 md5
  - host all all 0.0.0.0/0 md5

  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb
postgresql:
#Внутренний IP хоста
  listen: <postgres4_internal_ip>:5432
#Внутренний IP хоста
  connect_address: <postgres4_public_ip>:5432
  data_dir: /data/patroni
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: replicator
      password: replicator
    superuser:
      username: postgres
      password: postgres
  parameters:
      unix_socket_directories: '.'

tags:
    nofailover: true
    noloadbalance: false
    clonefrom: true
    nosync: true
    replicatefrom: postgres2

ssh-rsa@postgres1:~$ sudo mkdir -p /data/patroni
ssh-rsa@postgres1:~$ sudo chown postgres:postgres /data/patroni
ssh-rsa@postgres1:~$ sudo chmod 700 /data/patroni
ssh-rsa@postgres1:~$ sudo nano /etc/systemd/system/patroni.service

[Unit]
Description=High availability PostgreSQL Cluster
After=syslog.target network.target

[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/local/bin/patroni /etc/patroni.yml
KillMode=process
TimeoutSec=30
Restart=no

[Install]
WantedBy=multi-user.targ
```
*4.5. Включение patroni*

ВМ 1

```
ssh-rsa@postgres1:~$ sudo systemctl start patroni
ssh-rsa@postgres1:~$ sudo systemctl status patroni
```

ВМ 2

```
ssh-rsa@postgres2:~$ sudo systemctl start patroni
ssh-rsa@postgres2:~$ sudo systemctl status patroni
```

ВМ 3

```
ssh-rsa@postgres3:~$ sudo systemctl start patroni
ssh-rsa@postgres3:~$ sudo systemctl status patroni
```

ВМ 4

```
ssh-rsa@postgres4:~$ sudo systemctl start patroni
ssh-rsa@postgres4:~$ sudo systemctl status patroni
```
*4.6. Настройка HAProxy*

ВМ 6 HAProxy

```
PS C:\Users\Egor> ssh ssh-rsa@<proxy_public_ip>

ssh-rsa@proxy:~$ sudo nano /etc/haproxy/haproxy.cfg

global
        maxconn 100
        log     127.0.0.1 local2

defaults
        log global
        mode tcp
        retries 2
        timeout client 30m
        timeout connect 4s
        timeout server 30m
        timeout check 5s
listen stats
    mode http
    bind *:7000
    stats enable
    stats uri /

listen postgres
    bind *:5000
    option httpchk
    http-check expect status 200
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
#Внешний IP хоста
    server node1 <postgres1_public_ip>:5432 maxconn 100 check port 8008
#Внешний IP хоста
    server node2 <postgres2_public_ip>:5432 maxconn 100 check port 8008
#Внешний IP хоста
    server node3 <postgres3_public_ip>:5432 maxconn 100 check port 8008
#Внешний IP хоста
    server node4 <postgres4_public_ip>:5432 maxconn 100 check port 8008

ssh-rsa@proxy:~$ ssh-rsa@proxy:~$ sudo systemctl restart haproxy
ssh-rsa@proxy:~$ sudo systemctl status haproxy
```
# 5. Тестирование производительности
*5.1. Структура тестовой БД*

https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/db_scheme.drawio

![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/db_scheme.drawio.png)
*5.2. Скрипт инита тестовой БД*
```
DROP IF EXISTS DATABASE contracts_test;

CREATE IF NOT EXISTS DATABASE contracts_test;

CREATE TABLE phones (
id serial PRIMARY KEY, 
value integer);

CREATE TABLE goods (
id serial PRIMARY KEY, 
name text);

CREATE TABLE uoms 
(id serial PRIMARY KEY, 
name text);

CREATE TABLE customers (
id serial PRIMARY KEY, 
name text,
surname text,
phone_id integer REFERENCES phones (id)
);

CREATE TABLE suppliers (
id serial PRIMARY KEY, 
name text,
surname text,
phone_id integer REFERENCES phones (id)
);

CREATE TABLE contracts (
id serial PRIMARY KEY, 
supplier_id integer REFERENCES suppliers (id),
customer_id integer REFERENCES customers (id),
good_id integer REFERENCES goods (id),
quantity integer,
uom_id integer REFERENCES uoms (id)
);

CREATE OR REPLACE FUNCTION random_between(low INT ,high INT) 
   RETURNS INT AS
$$
BEGIN
   RETURN floor(random()* (high-low + 1) + low);
END;
$$ language 'plpgsql' STRICT;
CREATE OR REPLACE FUNCTION random_string( int ) RETURNS TEXT as $$
    SELECT string_agg(substring('0123456789bcdfghjkmnpqrstvwxyz', round(random() * 30)::integer, 1), '') FROM generate_series(1, $1);
$$ language sql;
```
*5.3. Скрипт для наполнения данными БД*
```
INSERT INTO phones (id, value)
SELECT 
generate_series,
random_between(100000000,999999999)
FROM generate_series(1,200000);

INSERT INTO goods (id, name)
SELECT 
generate_series,
random_string(10)
FROM generate_series(1,10000);

INSERT INTO uoms (id, name)
SELECT 
generate_series,
random_string(5)
FROM generate_series(1,1000);

INSERT INTO customers (id, name, surname, phone_id)
SELECT 
generate_series,
random_string(10),
random_string(10),
random_between(1,100000)
FROM generate_series(1,100000);

INSERT INTO suppliers (id, name, surname, phone_id)
SELECT 
generate_series,
random_string(10),
random_string(10),
random_between(1,100000)
FROM generate_series(1,100000);

INSERT INTO contracts (id, supplier_id, customer_id, good_id, quantity, uom_id)
SELECT 
generate_series,
random_between(1,100000),
random_between(1,100000),
random_between(1,10000),
random_between(1,1000000)::numeric/1000:numeric,
random_between(1,1000)
FROM generate_series(1,1000000);
```
*5.4. Скрипты для OLTP нагрузки БД*
```
INSERT INTO phones (value)
VALUES (random_between(100000000,999999999));

INSERT INTO goods (name)
VALUES (random_string(10));

INSERT INTO uoms (name)
VALUES (random_string(5));

INSERT INTO customers (name, surname, phone_id)
VALUES (
random_string(10),
random_string(10),
random_between(1,200000));

INSERT INTO suppliers (name, surname, phone_id)
VALUES (
random_string(10),
random_string(10),
random_between(1,200000));

INSERT INTO contracts (supplier_id, customer_id, good_id, quantity, uom_id)
VALUES (
random_between(1,100000),
random_between(1,100000),
random_between(1,10000),
random_between(1,1000000)::numeric/1000:numeric,
random_between(1,1000));


SELECT * FROM phones WHERE id = random_between(1,200000);
SELECT * FROM goods WHERE id = random_between(1,10000);
SELECT * FROM uoms WHERE id = random_between(1,1000);

SELECT * FROM customers WHERE id = random_between(1,100000);
SELECT * FROM suppliers WHERE id = random_between(1,100000);
SELECT * FROM customers WHERE phone_id = random_between(1,200000);
SELECT * FROM suppliers WHERE phone_id = random_between(1,200000);

SELECT * FROM contracts WHERE id = random_between(1,1000000);
SELECT * FROM contracts WHERE supplier_id = random_between(1,100000);
SELECT * FROM contracts WHERE customer_id = random_between(1,100000);
SELECT * FROM contracts WHERE good_id = random_between(1,10000);
SELECT * FROM contracts WHERE good_id = random_between(1,1000);


UPDATE phones SET value = random_between(100000000,999999999) WHERE id = random_between(1,200000);
UPDATE goods SET name = random_string(10) WHERE id = random_between(1,10000);
UPDATE uoms SET name = random_string(5) WHERE id = random_between(1,1000);

UPDATE customers SET 
name = random_string(10),
surname = random_string(10),
phone_id = random_between(1,200000)
WHERE id = random_between(1,100000);
UPDATE suppliers SET 
name = random_string(10),
surname = random_string(10),
phone_id = random_between(1,200000)
WHERE id = random_between(1,100000);

UPDATE contracts SET
supplier_id=random_between(1,100000),
customer_id=random_between(1,100000),
good_id=random_between(1,10000),
quantity=random_between(1,1000000)::numeric/1000:numeric,
uom_id=random_between(1,1000)
WHERE id = random_between(1,1000000);
```
*5.5. Скрипты для OLAP нагрузки БД*
```

```
*5.6. Скрипт для backup БД*
```

```
*5.7. Скрипт для моделирования отказа интстанса*
```

```
