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