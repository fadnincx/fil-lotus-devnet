#!/bin/sh

k3s kubectl scale --replicas=0 -f ./deploy/deployment.yaml
echo "Delete all"
k3s kubectl delete -f ./deploy/deployment.yaml --grace-period 0
k3s kubectl delete -f ./deploy/volume.yaml --grace-period 0
k3s kubectl delete -f ./deploy/monitoring --grace-period 0
k3s kubectl delete -f ./deploy/redis.yaml --grace-period 0
echo "delete pods"
kubectl delete pod --all --grace-period 0
echo "delete peers"
find /var/lib/rancher/k3s/storage/ -name 'peerID.txt' -exec rm -rf {} \;
find /var/lib/rancher/k3s/storage/ -name 'gen.gen' -exec rm -rf {} \;
echo "stop"
bash -c /usr/local/bin/k3s-killall.sh
killall k3s-server
