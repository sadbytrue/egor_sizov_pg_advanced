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
*2.1. Развертывание ВМ*

ВМ 1 для postgres в географической зоне 1

```
PS C:\Windows\system32> yc compute instance create --name postgres1 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1804-lts,size=10,auto-delete=true --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 8G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname postgres1
```

ВМ 2 для postgres в географической зоне 2

```
PS C:\Windows\system32> yc compute instance create --name postgres2 --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1804-lts,size=10,auto-delete=true --network-interface subnet-name=default-ru-central1-b,nat-ip-version=ipv4 --memory 8G --cores 2 --zone ru-central1-b --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname postgres2
```

ВМ 3 для etcd в географической зоне 1
```
PS C:\Windows\system32> yc compute instance create --name etcd --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1804-lts,size=10,auto-delete=true --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 4G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname etcd
```

ВМ 4 для proxy в географической зоне 1
```
PS C:\Windows\system32> yc compute instance create --name proxy --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1804-lts,size=10,auto-delete=true --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --memory 4G --cores 2 --zone ru-central1-a --metadata-from-file user-data=C:\Users\Egor\user_data.yaml  --hostname proxy
```

*2.1. Установка postgres, patroni, haproxy и необходимых пакетов*

ВМ 1 установка postgres, patroni и необходимых пакетов

```
PS C:\Windows\system32> 
```

ВМ 2 установка postgres, patroni и необходимых пакетов

```

```

ВМ 3 установка etcd

```

```

ВМ 4 установка haproxy

```

```
