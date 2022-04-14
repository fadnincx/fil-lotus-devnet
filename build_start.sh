#!/bin/bash

docker image build -t marcelwuersten/filecoin-lotus:latest -f lotus.dockerfile .
nohup bash -c "k3s server --docker &"
sleep 5
k3s kubectl apply -f ./deploy
echo "Applied deployment"
echo "Scale param is $1"
if [[ $1 =~ ^[0-9]+$ ]]; then
 scale=$1
elif [[ $(hostname) == 'marcel-ThinkPad-X1' ]]; then
 scale=3
else
 scale=8
fi
echo "network param is $2"
if [[ $2 =~ "ring" ]] || [[ $2 =~ "full" ]] || [[ $2 =~ "tree" ]]; then
 topology=$2
else
 topology="star"
fi
echo "Network topology set to $topology"
echo "Wait for redis"
sleep 30
k3s kubectl wait --for=condition=ready pod -l app=redisnode
echo "scale to ${scale}"
k3s kubectl scale --replicas=${scale} -f ./deploy/deployment.yaml
./redis-cli/rediscli w nettopology $topology
./redis-cli/rediscli w fil-nodes $(($scale - 1))
echo "Wait for all node ready"

for i in $(seq 0 $(($scale - 1)))
do
  while ! ./redis-cli/rediscli r lotus-node-${i}-started; do
      sleep 1
  done
done

echo "All nodes ready"
