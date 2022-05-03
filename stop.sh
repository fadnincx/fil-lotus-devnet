#!/bin/sh
###################################################################################
#                                                                                 #
#  Lotus Testnet Stop Script - Marcel Wuersten - 2022 - University of Bern      #
#                                                                                 #
###################################################################################

# Scale down the lotus nods
kubectl scale --replicas=0 -f ./deploy/lotus.yaml

# Delete all deployments
echo "Delete all deployments"
k3s kubectl delete -f ./deploy/lotus.yaml --grace-period 0
k3s kubectl delete -f ./deploy/volume.yaml --grace-period 0
k3s kubectl delete -f ./deploy/redis.yaml --grace-period 0

# Delete all pods still there
echo "delete pods"
kubectl delete pod --all --grace-period 0

# Delete relevant files in persitent volume
echo "delete pvc data"
find /var/lib/rancher/k3s/storage/ -name 'fil-testnet.car' -exec rm -rf {} \;
find /var/lib/rancher/k3s/storage/ -name 'lotus-node-*' -exec rm -rf {} \;

