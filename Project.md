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
| postgres1 | 10.128.0.31 | 158.160.38.176 |
| postgres2 | 10.129.0.17 | 158.160.83.222 |
| etcd | 10.128.0.3 | 158.160.106.255 |
| proxy | 10.128.0.17 | 178.154.202.169 |

*2.1. Развертывание ВМ*

ВМ 1 для postgres в географической зоне 1

```
PS C:\Windows\system32> yc compute instance create --name postgres1 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=64,auto-delete=true,type=network-ssd --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 32G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname postgres1
```

ВМ 2 для postgres в географической зоне 2

```
PS C:\Windows\system32> yc compute instance create --name postgres2 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=64,auto-delete=true,type=network-ssd --network-interface subnet-name=default-ru-central1-b,nat-ip-version=ipv4 --memory 32G --cores 2 --zone ru-central1-b --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname postgres2
```

ВМ 3 для etcd в географической зоне 1
```
PS C:\Windows\system32> yc compute instance create --name etcd --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=8,auto-delete=true,type=network-ssd --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 4G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname etcd
```

ВМ 4 для proxy в географической зоне 1
```
PS C:\Windows\system32> yc compute instance create --name proxy --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=8,auto-delete=true,type=network-ssd --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 4G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname proxy
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
      shared_buffers: 8GB
      effective_cache_size: 24GB
      maintenance_work_mem: 2GB
      checkpoint_completion_target: 0.9
      wal_buffers: 16MB
      default_statistics_target: 100
      random_page_cost: 1.1
      effective_io_concurrency: 200
      work_mem: 41943kB
      huge_pages: try
      min_wal_size: 2GB
      max_wal_size: 8GB

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
      shared_buffers: 8GB
      effective_cache_size: 24GB
      maintenance_work_mem: 2GB
      checkpoint_completion_target: 0.9
      wal_buffers: 16MB
      default_statistics_target: 100
      random_page_cost: 1.1
      effective_io_concurrency: 200
      work_mem: 41943kB
      huge_pages: try
      min_wal_size: 2GB
      max_wal_size: 8GB

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
PS C:\Windows\system32> yc compute instance create --name postgres1 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=64,auto-delete=true,type=network-ssd --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 32G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname postgres1
```

ВМ 2 для postgres в географической зоне 2

```
PS C:\Windows\system32> yc compute instance create --name postgres2 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=64,auto-delete=true,type=network-ssd --network-interface subnet-name=default-ru-central1-b,nat-ip-version=ipv4 --memory 32G --cores 2 --zone ru-central1-b --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname postgres2
```

ВМ 3 для реплики postgres в географической зоне 1

```
PS C:\Windows\system32> yc compute instance create --name postgres3 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=64,auto-delete=true,type=network-ssd --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 32G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname postgres3
```

ВМ 4 для etcd в географической зоне 1
```
PS C:\Windows\system32> yc compute instance create --name etcd --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=64,auto-delete=true,type=network-ssd --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 4G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname etcd
```

ВМ 5 для proxy в географической зоне 1
```
PS C:\Windows\system32> yc compute instance create --name proxy --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=64,auto-delete=true,type=network-ssd --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 4G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname proxy
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
PS C:\Windows\system32> yc compute instance create --name postgres1 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=64,auto-delete=true,type=network-ssd --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 32G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname postgres1
```

ВМ 2 для postgres в географической зоне 2

```
PS C:\Windows\system32> yc compute instance create --name postgres2 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=64,auto-delete=true,type=network-ssd --network-interface subnet-name=default-ru-central1-b,nat-ip-version=ipv4 --memory 32G --cores 2 --zone ru-central1-b --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname postgres2
```

ВМ 3 для реплики postgres в географической зоне 1

```
PS C:\Windows\system32> yc compute instance create --name postgres3 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=64,auto-delete=true,type=network-ssd --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 32G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname postgres3
```

ВМ 4 для реплики postgres в географической зоне 2

```
PS C:\Windows\system32> yc compute instance create --name postgres4 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=64,auto-delete=true,type=network-ssd --network-interface subnet-name=default-ru-central1-b,nat-ip-version=ipv4 --memory 32G --cores 2 --zone ru-central1-b --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname postgres4
```

ВМ 5 для etcd в географической зоне 1
```
PS C:\Windows\system32> yc compute instance create --name etcd --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=64,auto-delete=true,type=network-ssd --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 4G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname etcd
```

ВМ 6 для proxy в географической зоне 1
```
PS C:\Windows\system32> yc compute instance create --name proxy --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=64,auto-delete=true,type=network-ssd --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 4G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname proxy
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

Подготовка базы:

```
CREATE DATABASE contracts_test;
\c contracts_test

CREATE OR REPLACE FUNCTION random_between(low INT ,high INT) 
   RETURNS INT AS
$$
BEGIN
   RETURN floor(random()* (high-low + 1) + low);
END;
$$ language 'plpgsql' STRICT;

CREATE OR REPLACE FUNCTION random_string( int ) RETURNS TEXT as
$$
    SELECT string_agg(substring('0123456789bcdfghjkmnpqrstvwxyz', round(random() * 30)::integer, 1), '') FROM generate_series(1, $1);
$$ language sql;
```

```
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
```
*5.3. Скрипт для наполнения данными БД*
```
INSERT INTO phones (id, value)
SELECT 
generate_series,
random_between(100000000,999999999)
FROM generate_series(1,2000000);

INSERT INTO goods (id, name)
SELECT 
generate_series,
random_string(10)
FROM generate_series(1,100000);

INSERT INTO uoms (id, name)
SELECT 
generate_series,
random_string(5)
FROM generate_series(1,10000);

INSERT INTO customers (id, name, surname, phone_id)
SELECT 
generate_series,
random_string(10),
random_string(10),
random_between(1,1000000)
FROM generate_series(1,1000000);

INSERT INTO suppliers (id, name, surname, phone_id)
SELECT 
generate_series,
random_string(10),
random_string(10),
random_between(1,1000000)
FROM generate_series(1,1000000);

INSERT INTO contracts (id, supplier_id, customer_id, good_id, quantity, uom_id)
SELECT 
generate_series,
random_between(1,1000000),
random_between(1,1000000),
random_between(1,100000),
random_between(1,1000000)::numeric/1000::numeric,
random_between(1,10000)
FROM generate_series(1,10000000);
```
*5.4. Скрипты для OLTP нагрузки БД*
```
SELECT * FROM phones WHERE id = (SELECT * FROM random_between(1,2000000));
SELECT * FROM goods WHERE id = (SELECT * FROM random_between(1,100000));
SELECT * FROM uoms WHERE id = (SELECT * FROM random_between(1,10000));

SELECT * FROM customers WHERE id = (SELECT * FROM random_between(1,1000000));
SELECT * FROM suppliers WHERE id = (SELECT * FROM random_between(1,1000000));
SELECT * FROM customers WHERE phone_id = (SELECT * FROM random_between(1,2000000));
SELECT * FROM suppliers WHERE phone_id = (SELECT * FROM random_between(1,2000000));

SELECT * FROM contracts WHERE id = (SELECT * FROM random_between(1,10000000));
SELECT * FROM contracts WHERE supplier_id = (SELECT * FROM random_between(1,1000000));
SELECT * FROM contracts WHERE customer_id = (SELECT * FROM random_between(1,1000000));
SELECT * FROM contracts WHERE good_id = (SELECT * FROM random_between(1,100000));
SELECT * FROM contracts WHERE uom_id = (SELECT * FROM random_between(1,10000));


UPDATE phones SET value = random_between(100000000,999999999) WHERE id = (SELECT * FROM random_between(1,2000000));
UPDATE goods SET name = random_string(10) WHERE id = (SELECT * FROM random_between(1,100000));
UPDATE uoms SET name = random_string(5) WHERE id = (SELECT * FROM random_between(1,10000));

UPDATE customers SET 
name = random_string(10),
surname = random_string(10),
phone_id = random_between(1,2000000)
WHERE id = (SELECT * FROM random_between(1,1000000));
UPDATE suppliers SET 
name = random_string(10),
surname = random_string(10),
phone_id = random_between(1,2000000)
WHERE id = (SELECT * FROM random_between(1,1000000));

UPDATE contracts SET
supplier_id=random_between(1,1000000),
customer_id=random_between(1,1000000),
good_id=random_between(1,100000),
quantity=random_between(1,1000000)::numeric/1000::numeric,
uom_id=random_between(1,10000)
WHERE id = (SELECT * FROM random_between(1,10000000));
```
*5.5. Скрипты для OLAP нагрузки БД*
```
SELECT
contracts.id,
customers.name AS customer_name,
customers.surname AS customer_surname,
customers_phones.value AS customer_phone,
suppliers.name AS supplier_name,
suppliers.surname AS supplier_surname,
suppliers_phones.value AS supplier_phone,
goods.name AS good_name,
contracts.quantity,
uoms.name AS uom_name
FROM contracts
LEFT JOIN customers ON contracts.customer_id=customers.id
LEFT JOIN suppliers ON contracts.customer_id=suppliers.id
LEFT JOIN phones customers_phones ON customers.phone_id=customers_phones.id
LEFT JOIN phones suppliers_phones ON suppliers.phone_id=suppliers_phones.id
LEFT JOIN goods ON contracts.good_id=goods.id
LEFT JOIN uoms ON contracts.uom_id=uoms.id;

SELECT 
supplier_id,
AVG(quantity) AS avg_quantity,
COUNT(supplier_id) AS number_of_contracts,
SUM(quantity) AS sum_quantity
FROM contracts GROUP BY supplier_id;

SELECT 
customer_id,
AVG(quantity) AS avg_quantity,
COUNT(supplier_id) AS number_of_contracts,
SUM(quantity) AS sum_quantity
FROM contracts GROUP BY customer_id;

SELECT 
good_id,
AVG(quantity) AS avg_quantity,
COUNT(supplier_id) AS number_of_contracts,
SUM(quantity) AS sum_quantity
FROM contracts GROUP BY good_id;

SELECT 
uom_id,
AVG(quantity) AS avg_quantity,
COUNT(supplier_id) AS number_of_contracts,
SUM(quantity) AS sum_quantity
FROM contracts GROUP BY uom_id;
```
*5.6. Скрипт для backup БД*
```
#!/bin/bash

# $1 --root directory
# $2 --connection string
# $3 --time::integer, s - время выполнения
# $4 --pereodic - переодичность бэкапирования

for (( i = 0; i < $3; i += $4 ))
do
sleep $4
backup_name=$1/backup_$(date +'%d_%m_%Y_%H_%M_%S')
echo "[$(date +%d-%m-%Y-%H:%M:%S)] pg_basebackup $backup_name start"
pg_dump --dbname=$2 --format=directory --file=$backup_name
echo "[$(date +%d-%m-%Y-%H:%M:%S)] pg_basebackup $backup_name done"
sudo rm -f $backup_name -r
done
```
*5.7. Скрипт для моделирования отказа интстанса*
```
#!/bin/bash

# $1 --time::integer, s - время выполнения
# $2 --postgres_active::integer, продолжительность работы postgres в каждом цикле
# $3 --postgres_stop::integer, продолжительность останова postgres в каждом цикле
# $4 --offset::integer - смещение старта отсчета времени

sleep $4
for (( i = $4; i < $1; i += $2 +$3 ))
do
sleep $2
sudo systemctl stop patroni
echo "[$(date +%d-%m-%Y-%H:%M:%S)] postgresql stopped"
sleep $3
sudo systemctl start patroni
echo "[$(date +%d-%m-%Y-%H:%M:%S)] postgresql start"
done

```
*5.8. Инструмент для тестирования*

Инструментом для тестирования выбран https://github.com/winebarrel/pgslap
Он поддерживает создание пользовательских БД и выполнение пользовательских запросов
Скрипты в папке:
https://github.com/sadbytrue/egor_sizov_pg_advanced/tree/main/scripts_for_testing

```
PS C:\Users\Egor> scp C:\Users\Egor\Documents\project_otus\olap_load_scripts.sql ssh-rsa@<host_n>:/home/ssh-rsa
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
olap_load_scripts.sql                                                              100% 1367    69.6KB/s   00:00
PS C:\Users\Egor> scp C:\Users\Egor\Documents\project_otus\oltp_load_scripts.sql ssh-rsa@<host_n>:/home/ssh-rsa
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
oltp_load_scripts.sql                                                              100% 1629    78.0KB/s   00:00
PS C:\Users\Egor> scp C:\Users\Egor\Documents\project_otus\pg_base_backup.sh ssh-rsa@<host_n>:/home/ssh-rsa
PS C:\Users\Egor> scp C:\Users\Egor\Documents\project_otus\create_db_scripts_null.sql ssh-rsa@158.160.115.35:/home/ssh-rsa
PS C:\Users\Egor> scp C:\Users\Egor\Documents\project_otus\pg_stop_patroni.sh ssh-rsa@158.160.62.255:/home/ssh-rsa

PS C:\Users\Egor> scp C:\Users\Egor\Documents\project_otus\pgslap_v1.0.0_linux_amd64\pgslap ssh-rsa@<host_n>:/home/ssh-rsa
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':

ssh-rsa@postgres1:~$ sudo chmod +x pgslap
ssh-rsa@postgres1:~$ sudo -u postgres psql
could not change directory to "/home/ssh-rsa": Permission denied
psql (15.6 (Ubuntu 15.6-1.pgdg22.04+1))
Type "help" for help.

postgres=# CREATE DATABASE contracts_test;
CREATE DATABASE
postgres=# \c contracts_test
You are now connected to database "contracts_test" as user "postgres".
contracts_test=# CREATE OR REPLACE FUNCTION random_between(low INT ,high INT)
contracts_test-#    RETURNS INT AS
contracts_test-# $$
contracts_test$# BEGIN
contracts_test$#    RETURN floor(random()* (high-low + 1) + low);
contracts_test$# END;
contracts_test$# $$ language 'plpgsql' STRICT;
CREATE FUNCTION
contracts_test=# CREATE OR REPLACE FUNCTION random_string( int ) RETURNS TEXT as
contracts_test-# $$
contracts_test$#     SELECT string_agg(substring('0123456789bcdfghjkmnpqrstvwxyz', round(random() * 30)::integer, 1), '') FROM generate_series(1, $1);
contracts_test$# $$ language sql;
CREATE FUNCTION
contracts_test=# \q
```

Команда для генерации OLTP нагрузки:

```
./pgslap -u 'postgres://postgres:postgres@<host>:5432/contracts_test' --create create_db_scripts_null.sql -q oltp_load_scripts.sql -n 45 --no-drop --t <time in seconds>
```

Команда для генерации OLAP нагрузки:

```
./pgslap -u 'postgres://postgres:postgres@<host>:5432/contracts_test' --create create_db_scripts_null.sql -q olap_load_scripts.sql -n 45 --no-drop --t <time in seconds>
```

Команда для генерации backup нагрузки - bash скрипт

```
sudo chmod +x pg_base_backup.sh
./pg_base_backup.sh /var/lib/postgresql/15/main postgresql://postgres:postgres@localhost:5432 30 10
```

Команда для моделирования отказа инстансов - bash скрипт

```
sudo chmod +x pg_stop_patroni.sh
./pg_stop_patroni.sh 120 30 30 0
```

# 6.Тестирование

БАЗОВАЯ АРХИТЕКТУРА

*6.1.Виртуальная машина для запуска тестирования*
```
PS C:\Windows\system32> yc compute instance create --name test --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=8,auto-delete=true,type=network-ssd --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 8G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname test
PS C:\Users\Egor> ssh ssh-rsa@178.154.203.151
ssh-rsa@test:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15
ssh-rsa@test:~$ sudo systemctl stop postgresql
```
*6.2.Создание тестовой БД*
```
ssh-rsa@test:~$ psql -h 178.154.202.169 -p 5000 -U postgres
Password for user postgres:
postgres=# CREATE DATABASE contracts_test;
CREATE DATABASE
postgres=# \c contracts_test
You are now connected to database "contracts_test" as user "postgres".

contracts_test=# CREATE OR REPLACE FUNCTION random_between(low INT ,high INT)
contracts_test-#    RETURNS INT AS
contracts_test-# $$
contracts_test$# BEGIN
contracts_test$#    RETURN floor(random()* (high-low + 1) + low);
contracts_test$# END;
contracts_test$# $$ language 'plpgsql' STRICT;
CREATE FUNCTION
contracts_test=# CREATE OR REPLACE FUNCTION random_string( int ) RETURNS TEXT as
contracts_test-# $$
  SEcontracts_test$#     SELECT string_agg(substring('0123456789bcdfghjkmnpqrstvwxyz', round(random() * 30)::integer, 1), '') FROM generate_series(1, $1);
contracts_test$# $$ language sql;
CREATE FUNCTION
contracts_test=# CREATE TABLE phones (
contracts_test(# id serial PRIMARY KEY,
contracts_test(# value integer);
CREATE TABLE
contracts_test=# CREATE TABLE goods (
contracts_test(# id serial PRIMARY KEY,
contracts_test(# name text);
CREATE TABLE
contracts_test=# CREATE TABLE uoms
contracts_test-# (id serial PRIMARY KEY,
contracts_test(# name text);
CREATE TABLE
contracts_test=# CREATE TABLE customers (
contracts_test(# id serial PRIMARY KEY,
contracts_test(# name text,
contracts_test(# surname text,
contracts_test(# phone_id integer REFERENCES phones (id)
contracts_test(# );
CREATE TABLE
contracts_test=# CREATE TABLE suppliers (
contracts_test(# id serial PRIMARY KEY,
contracts_test(# name text,
contracts_test(# surname text,
contracts_test(# phone_id integer REFERENCES phones (id)
contracts_test(# );
CREATE TABLE
contracts_test=# CREATE TABLE contracts (
contracts_test(# id serial PRIMARY KEY,
contracts_test(# supplier_id integer REFERENCES suppliers (id),
contracts_test(# customer_id integer REFERENCES customers (id),
contracts_test(# good_id integer REFERENCES goods (id),
contracts_test(# quantity integer,
contracts_test(# uom_id integer REFERENCES uoms (id)
contracts_test(# );
CREATE TABLE

contracts_test=# INSERT INTO phones (id, value)
contracts_test-# SELECT
contracts_test-# generate_series,
contracts_test-# random_between(100000000,999999999)
contracts_test-# FROM generate_series(1,2000000);
INSERT 0 2000000
contracts_test=# INSERT INTO goods (id, name)
contracts_test-# SELECT
contracts_test-# generate_series,
contracts_test-# random_string(10)
contracts_test-# FROM generate_series(1,100000);
INSERT 0 100000
contracts_test=# INSERT INTO uoms (id, name)
contracts_test-# SELECT
contracts_test-# generate_series,
contracts_test-# random_string(5)
contracts_test-# FROM generate_series(1,10000);
INSERT 0 10000
contracts_test=# INSERT INTO customers (id, name, surname, phone_id)
_series,
contracts_test-# SELECT
andocontracts_test-# generate_series,
contracts_test-# random_string(10),
contracts_test-# random_string(10),
contracts_test-# random_between(1,1000000)
contracts_test-# FROM generate_series(1,1000000);
INSERT 0 1000000
contracts_test=# INSERT INTO suppliers (id, name, surname, phone_id)
contracts_test-# SELECT
contracts_test-# generate_series,
contracts_test-# random_string(10),
contracts_test-# random_string(10),
contracts_test-# random_between(1,1000000)
contracts_test-# FROM generate_series(1,1000000);
INSERT 0 1000000
contracts_test=# INSERT INTO contracts (id, supplier_id, customer_id, good_id, quantity, uom_id)
contracts_test-# SELECT
contracts_test-# generate_series,
contracts_test-# random_between(1,1000000),
contracts_test-# random_between(1,1000000),
contracts_test-# random_between(1,100000),
contracts_test-# random_between(1,1000000)::numeric/1000::numeric,
contracts_test-# random_between(1,10000)
contracts_test-# FROM generate_series(1,10000000);
INSERT 0 10000000
```
*6.3.Копирование скриптов для тестирования*
```
PS C:\Users\Egor> scp C:\Users\Egor\Documents\project_otus\create_db_scripts_null.sql ssh-rsa@178.154.203.151:/home/ssh-rsa
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
create_db_scripts_null.sql                                                         100%    0     0.0KB/s   00:00
PS C:\Users\Egor> scp C:\Users\Egor\Documents\project_otus\olap_load_scripts.sql ssh-rsa@178.154.203.151:/home/ssh-rsa
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
olap_load_scripts.sql                                                              100% 1367    74.0KB/s   00:00
PS C:\Users\Egor> scp C:\Users\Egor\Documents\project_otus\oltp_load_scripts.sql ssh-rsa@178.154.203.151:/home/ssh-rsa
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
oltp_load_scripts.sql                                                              100% 1629    80.2KB/s   00:00
PS C:\Users\Egor> scp C:\Users\Egor\Documents\project_otus\pgslap_v1.0.0_linux_amd64/pgslap ssh-rsa@178.154.203.151:/home/ssh-rsa
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
pgslap
PS C:\Users\Egor> scp C:\Users\Egor\Documents\project_otus\pg_base_backup.sh ssh-rsa@178.154.203.151:/home/ssh-rsa
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
pg_base_backup.sh                                                                  100%  506    24.5KB/s   00:00


PS C:\Users\Egor> scp C:\Users\Egor\Documents\project_otus\pg_stop_patroni.sh ssh-rsa@158.160.38.176:/home/ssh-rsa
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
pg_base_backup.sh                                                                  100%  506    24.5KB/s   00:00
PS C:\Users\Egor> scp C:\Users\Egor\Documents\project_otus\pg_stop_patroni.sh ssh-rsa@158.160.83.222:/home/ssh-rsa
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
pg_base_backup.sh                                                                  100%  506    24.5KB/s   00:00

ssh-rsa@test:~$ sudo chmod +x pg_base_backup.sh
ssh-rsa@test:~$ sudo chmod +x pgslap

ssh-rsa@postgres1:~$ sudo chmod +x pg_stop_patroni.sh
ssh-rsa@postgres2:~$ sudo chmod +x pg_stop_patroni.sh
```
*6.4.Подготовка к запуску тестирования*

Каждый инструмент в отдельном подключении ssh запускать!!!

```
ssh-rsa@test:~$ ./pgslap -u 'postgres://postgres:postgres@178.154.202.169:5000/contracts_test' --create create_db_scripts_null.sql -q oltp_load_scripts.sql -n 45 --no-drop --t 3600
```

```
ssh-rsa@test:~$ ./pgslap -u 'postgres://postgres:postgres@178.154.202.169:5000/contracts_test' --create create_db_scripts_null.sql -q olap_load_scripts.sql -n 45 --no-drop --t 3600
```

```
ssh-rsa@test:~$ ./pg_base_backup.sh /home/ssh-rsa postgresql://postgres:postgres@178.154.202.169:5000/contracts_test 3600 900
```

```
ssh-rsa@postgres1:~$ ./pg_stop_patroni.sh 3600 900 300 0
```
```
ssh-rsa@postgres2:~$ ./pg_stop_patroni.sh 3600 900 300 600
```
*6.5.Результаты тестирования*

OLTP

```
{
  "URL": "postgres://postgres:postgres@158.160.109.0:5000/contracts_test",
  "StartedAt": "2024-02-18T09:34:36.56396228Z",
  "FinishedAt": "2024-02-18T10:34:36.568097538Z",
  "ElapsedTime": 3600,
  "NAgents": 45,
  "Rate": 0,
  "AutoGenerateSql": false,
  "NumberPrePopulatedData": 100,
  "NumberQueriesToExecute": 0,
  "DropExistingDatabase": false,
  "UseExistingDatabase": true,
  "NoDropDatabase": true,
  "LoadType": "mixed",
  "GuidPrimary": false,
  "NumberSecondaryIndexes": 0,
  "CommitRate": 0,
  "MixedSelRatio": 1,
  "MixedInsRatio": 1,
  "NumberIntCols": 1,
  "IntColsIndex": false,
  "NumberCharCols": 1,
  "CharColsIndex": false,
  "PreQueries": null,
  "GOMAXPROCS": 2,
  "QueryCount": 11200,
  "AvgQPS": 3.1111075374345987,
  "MaxQPS": 243,
  "MinQPS": 1,
  "MedianQPS": 1,
  "ExpectedQPS": 0,
  "Response": {
    "Time": {
      "Cumulative": "44h32m32.265642035s",
      "HMean": "371.853µs",
      "Avg": "14.317166575s",
      "P50": "60.357609ms",
      "P75": "7.603990059s",
      "P95": "1m5.867670626s",
      "P99": "1m13.240376236s",
      "P999": "1m17.616541398s",
      "Long5p": "1m10.225410519s",
      "Short5p": "1.118718ms",
      "Max": "1m19.49518576s",
      "Min": "500ns",
      "Range": "1m19.49518526s",
      "StdDev": "24.951578086s"
    },
    "Rate": {
      "Second": 0.06984622234775593
    },
    "Samples": 11200,
    "Count": 11200,
    "Histogram": [
      {
        "0s - 7.949519s": 8573
      },
      {
        "7.949519s - 15.899037s": 136
      },
      {
        "15.899037s - 23.848556s": 2
      },
      {
        "23.848556s - 31.798074s": 1
      },
      {
        "31.798074s - 39.747593s": 1
      },
      {
        "39.747593s - 47.697111s": 5
      },
      {
        "47.697111s - 55.64663s": 591
      },
      {
        "55.64663s - 1m3.596148s": 1176
      },
      {
        "1m3.596148s - 1m11.545667s": 539
      },
      {
        "1m11.545667s - 1m19.495185s": 176
      }
    ]
  }
}
```

OLAP

```
{
  "URL": "postgres://postgres:postgres@158.160.109.0:5000/contracts_test",
  "StartedAt": "2024-02-18T09:34:49.889052432Z",
  "FinishedAt": "2024-02-18T10:34:49.894219834Z",
  "ElapsedTime": 3600,
  "NAgents": 45,
  "Rate": 0,
  "AutoGenerateSql": false,
  "NumberPrePopulatedData": 100,
  "NumberQueriesToExecute": 0,
  "DropExistingDatabase": false,
  "UseExistingDatabase": true,
  "NoDropDatabase": true,
  "LoadType": "mixed",
  "GuidPrimary": false,
  "NumberSecondaryIndexes": 0,
  "CommitRate": 0,
  "MixedSelRatio": 1,
  "MixedInsRatio": 1,
  "NumberIntCols": 1,
  "IntColsIndex": false,
  "NumberCharCols": 1,
  "CharColsIndex": false,
  "PreQueries": null,
  "GOMAXPROCS": 2,
  "QueryCount": 120,
  "AvgQPS": 0.033333285487003865,
  "MaxQPS": 1,
  "MinQPS": 1,
  "MedianQPS": 1,
  "ExpectedQPS": 0,
  "Response": {
    "Time": {
      "Cumulative": "39h34m48.314042398s",
      "HMean": "4.048µs",
      "Avg": "19m47.402617019s",
      "P50": "12m43.562417702s",
      "P75": "38m47.756983556s",
      "P95": "40m29.773423817s",
      "P99": "41m21.03933404s",
      "P999": "41m22.839902993s",
      "Long5p": "40m56.02672116s",
      "Short5p": "611ns",
      "Max": "41m22.839902993s",
      "Min": "544ns",
      "Range": "41m22.839902449s",
      "StdDev": "15m48.24288236s"
    },
    "Rate": {
      "Second": 0.0008421743271121413
    },
    "Samples": 120,
    "Count": 120,
    "Histogram": [
      {
        "0s - 4m8.28399s": 24
      },
      {
        "4m8.28399s - 8m16.567981s": 1
      },
      {
        "8m16.567981s - 12m24.851971s": 9
      },
      {
        "12m24.851971s - 16m33.135961s": 41
      },
      {
        "16m33.135961s - 20m41.419951s": 1
      },
      {
        "20m41.419951s - 24m49.703942s": 1
      },
      {
        "24m49.703942s - 28m57.987932s": 1
      },
      {
        "28m57.987932s - 33m6.271922s": 1
      },
      {
        "33m6.271922s - 37m14.555912s": 1
      },
      {
        "37m14.555912s - 41m22.839902s": 40
      }
    ]
  }
}
```

Backup

```
[18-02-2024-09:49:40] pg_basebackup /home/ssh-rsa/backup_18_02_2024_09_49_40 start
[18-02-2024-10:00:57] pg_basebackup /home/ssh-rsa/backup_18_02_2024_09_49_40 done
[18-02-2024-10:15:57] pg_basebackup /home/ssh-rsa/backup_18_02_2024_10_15_57 start
[18-02-2024-10:29:11] pg_basebackup /home/ssh-rsa/backup_18_02_2024_10_15_57 done
```

Пересчет в tps: в каждой query для OLTP нагрузки 18 транзакций, для OLAP - 5 транзакций
Итого:
avg_qps OLTP = 56
avg_qps OLAP = 0.167
avg_backup_time = 1471 s


АРХИТЕКТУРА С ОТДЕЛЬНОЙ РЕПЛИКОЙ для OLAP+backup

*6.6.Подготовка к запуску тестирования*

Каждый инструмент в отдельном подключении ssh запускать!!!

```
ssh-rsa@test:~$ ./pgslap -u 'postgres://postgres:postgres@178.154.202.169:5000/contracts_test' --create create_db_scripts_null.sql -q oltp_load_scripts.sql -n 45 --no-drop --t 3600
```

```
ssh-rsa@test:~$ ./pgslap -u 'postgres://postgres:postgres@178.154.202.169:5000/contracts_test' --create create_db_scripts_null.sql -q olap_load_scripts.sql -n 45 --no-drop --t 3600
```

```
ssh-rsa@test:~$ ./pg_base_backup.sh /home/ssh-rsa postgresql://postgres:postgres@178.154.202.169:5000/contracts_test 3600 900
```

```
ssh-rsa@postgres1:~$ ./pg_stop_patroni.sh 3600 900 300 0
```
```
ssh-rsa@postgres2:~$ ./pg_stop_patroni.sh 3600 900 300 600
```
*6.7.Результаты тестирования*

OLTP

```

```

OLAP

```

```

Backup

```

```

Пересчет в tps: в каждой query для OLTP нагрузки 18 транзакций, для OLAP - 5 транзакций
Итого:
avg_qps OLTP = 
avg_qps OLAP = 
avg_backup_time = 
