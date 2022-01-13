#!/bin/bash


PODS=3
declare -A ips
for ((i=0;i<PODS;i++)); do
 ips[$i]=$(k3s kubectl get pods -o wide | grep lotus-node-$i | awk '{print $6}')
done


declare -A walletKeys

for ((i=0;i<PODS;i++)); do
 nrWallets=$(curl -s "http://${ips[$i]}?lotus%20wallet%20list%20--addr-only%20%7C%20wc%20-l")
 echo "$i has $nrWallets wallets"
 if [[ $nrWallets -eq 0 ]]; then
   curl -s "http://${ips[$i]}?lotus%20wallet%20new"
   echo "need to create wallet on $i" 
 fi
 walletKey[$i]=$(curl -s "http://${ips[$i]}?lotus%20wallet%20list%20--addr-only%20%7C%20tail%20-n%201")
done

for k in "${walletKey[@]}"; do
 echo "$k"
done

counter=0
seconds=10
time_0=$(date +%s%N)
while ((time_0 + (seconds * 1000000000) > $(date +%s%N))); do
#for ((i=0;i<counter;i++)); do
  for ((j=1;j<PODS;j++)); do
    curl -s "http://${ips[0]}?lotus%20send%20${walletKey[$j]}%200.000001" > /dev/null
    ((counter++))
  done
done
time_1=$(date +%s%N)
time_run=$(($time_1-$time_0))
echo "nanoseconds: $time_run"
echo "time: $(($time_run/1000000000)) s $(( ($time_run/1000000)% 1000 ))ms $(( ($time_run/1000) % 1000 ))us"
mps=$(($counter * 1000000000 / $time_run))
echo "in $(($time_run / 1000000 )) milliseconds has $counter messages i.e. $mps mps" 
