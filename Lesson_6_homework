# 1.Создание виртуальной машины и кластера PostgreSQL
*1.1.Cоздайте новый кластер PostgresSQL 14*
![Иллюстрация к проекту](https://github.com/sadbytrue/egor_sizov_pg_advanced/blob/main/Screenshot_9.png)
```
PS C:\Users\Egor> type C:\Users\Egor\.ssh\id_ed25519.pub | clip
PS C:\Users\Egor> ssh ssh-rsa@158.160.37.78
The authenticity of host '158.160.37.78 (158.160.37.78)' can't be established.
ECDSA key fingerprint is SHA256:XFW6NW2Q5FmG/kXURvo75GRXGgYN3ud+JZnmxDTZkPg.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '158.160.37.78' (ECDSA) to the list of known hosts.
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Enter passphrase for key 'C:\Users\Egor/.ssh/id_ed25519':
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-86-generic x86_64)
```
```
ssh-rsa@lesson5:~$ sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15
```
