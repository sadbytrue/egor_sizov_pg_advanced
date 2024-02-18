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
