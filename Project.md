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

*2.1. Установка postgres, patroni, etcd и haproxy*

ВМ 1 установка postgres, patroni, etcd и haproxy

```
PS C:\Users\Egor> ssh ssh-rsa@51.250.14.208
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
PS C:\Users\Egor> ssh ssh-rsa@158.160.21.15
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
PS C:\Users\Egor> ssh ssh-rsa@51.250.80.23
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-92-generic x86_64)

ssh-rsa@etcd:~$ sudo apt install net-tools
ssh-rsa@etcd:~$ sudo apt -y install etcd
```

ВМ 4 установка haproxy

```
PS C:\Users\Egor> ssh ssh-rsa@178.154.207.138
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-92-generic x86_64)

ssh-rsa@proxy:~$ sudo apt update
ssh-rsa@proxy:~$ sudo apt install net-tools

ssh-rsa@proxy:~$ sudo apt -y install haproxy
```
*2.2. Настройка etcd*

ВМ 3

```
PS C:\Users\Egor> ssh ssh-rsa@51.250.80.23

ssh-rsa@etcd:~$ netstat -ltupn
(Not all processes could be identified, non-owned process info
 will not be shown, you would have to be root to see it all.)
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      -
tcp        0      0 127.0.0.53:53           0.0.0.0:*               LISTEN      -
tcp6       0      0 :::22                   :::*                    LISTEN      -
udp        0      0 127.0.0.53:53           0.0.0.0:*                           -
udp        0      0 10.128.0.24:68          0.0.0.0:*                           -

ssh-rsa@etcd:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether d0:0d:72:71:05:6d brd ff:ff:ff:ff:ff:ff
    altname enp138s0
    altname ens8
    inet 10.128.0.24/24 metric 100 brd 10.128.0.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::d20d:72ff:fe71:56d/64 scope link
       valid_lft forever preferred_lft forever

ssh-rsa@etcd:~$ sudo iptables -i lo -I INPUT -p tcp --dport 2379 -j ACCEPT
ssh-rsa@etcd:~$ sudo iptables -i lo -I INPUT -p tcp --dport 2380 -j ACCEPT
ssh-rsa@etcd:~$ sudo ufw enable
ssh-rsa@etcd:~$ sudo ufw allow 2379/tcp
ssh-rsa@etcd:~$ sudo ufw allow 2380/tcp

ssh-rsa@etcd:~$ sudo nano /etc/default/etcd

#Внутренний IP
ETCD_LISTEN_PEER_URLS="http://10.128.0.255:2380"
ETCD_LISTEN_CLIENT_URLS="http://10.128.0.255:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.128.0.255:2380"
ETCD_INITIAL_CLUSTER="default=http://10.128.0.255:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="http://10.128.0.255:2379"
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

Feb 04 22:05:15 etcd etcd[5913]: 8e9e05c52164694d became leader at term 5
Feb 04 22:05:15 etcd etcd[5913]: raft.node: 8e9e05c52164694d elected leader 8e9e05c52164694d at term 5
Feb 04 22:05:15 etcd etcd[5913]: published {Name:etcd ClientURLs:[http://10.128.0.255:2379]} to cluster cdf818194e3a>
Feb 04 22:05:15 etcd etcd[5913]: ready to serve client requests
Feb 04 22:05:15 etcd systemd[1]: Started etcd - highly-available key value store.
Feb 04 22:05:15 etcd etcd[5913]: serving insecure client requests on 10.128.0.255:2379, this is strongly discouraged!
Feb 04 22:05:15 etcd etcd[5913]: WARNING: 2024/02/04 22:05:15 grpc: addrConn.createTransport failed to connect to {1>
Feb 04 22:05:16 etcd etcd[5913]: WARNING: 2024/02/04 22:05:16 grpc: addrConn.createTransport failed to connect to {1>
Feb 04 22:05:18 etcd etcd[5913]: WARNING: 2024/02/04 22:05:18 grpc: addrConn.createTransport failed to connect to {1>
Feb 04 22:05:20 etcd etcd[5913]: WARNING: 2024/02/04 22:05:20 grpc: addrConn.createTransport failed to connect to {
```
*2.3. Настройка patroni*

ВМ 1

```
PS C:\Users\Egor> ssh ssh-rsa@51.250.90.21
ssh-rsa@postgres1:~$ sudo nano /etc/patroni.yml

!!! Внутренний IP хоста, а не внешний !!!
scope: postgres
namespace: /db/
name: postgres1

restapi:
    listen: 51.250.90.21:8008
    connect_address: 51.250.90.21:8008

etcd:
    host: 51.250.89.114:2379

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
  - host replication replicator 51.250.90.21/0 md5
  - host replication replicator 158.160.16.28/0 md5
  - host all all 0.0.0.0/0 md5

  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb
postgresql:
  listen: 51.250.90.21:5432
  connect_address: 51.250.90.21:5432
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
PS C:\Users\Egor> ssh ssh-rsa@158.160.16.28
ssh-rsa@postgres1:~$ sudo nano /etc/patroni.yml

scope: postgres
namespace: /db/
name: postgres2

restapi:
#Внутренний IP хоста
    listen: 158.160.16.28:8008
#Внешний IP хоста
    connect_address: 158.160.16.28:8008

etcd:
    host: 51.250.89.114:2379

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
  - host replication replicator 51.250.90.21/0 md5
  - host replication replicator 158.160.16.28/0 md5
  - host all all 0.0.0.0/0 md5

  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb
postgresql:
#Внутренний IP хоста
  listen: 158.160.16.28:5432
#Внутренний IP хоста
  connect_address: 158.160.16.28:5432
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
*2.4. Включение patroni*

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
*2.5. Настройка HAProxy*

ВМ HAProxy

```
PS C:\Users\Egor> ssh ssh-rsa@158.160.51.105

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
    server node1 51.250.90.21:5432 maxconn 100 check port 8008
#Внешний IP хоста
    server node2 158.160.16.28:5432 maxconn 100 check port 8008

ssh-rsa@proxy:~$ ssh-rsa@proxy:~$ sudo systemctl restart haproxy
ssh-rsa@proxy:~$ sudo systemctl status haproxy
```
