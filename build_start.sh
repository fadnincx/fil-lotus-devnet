#!/bin/bash
###################################################################################
#                                                                                 #
#  Lotus Devnet Start Script - Marcel Wuersten - 2022 - University of Bern        #
#                                                                                 #
###################################################################################

killall k3s-server
k3s server --docker > /dev/null 2>&1 &

# Build the docker image
docker image build -t marcelwuersten/filecoin-lotus:latest -f lotus.dockerfile .

# Apply deployment
k3s kubectl apply -f ./deploy
echo "Applied deployment"

# Scale the number of nodes
echo "Scale param is $1"

# If given argument and it's an integer us it
if [[ $1 =~ ^[0-9]+$ ]]; then
 scale="$1"

# if it's my poor notebook, default to 3
elif [[ $(hostname) == 'marcel-ThinkPad-X1' ]]; then
 scale="3"

# else default to 8 nodes
else
 scale="8"
fi

# Definei the network topology
echo "network param is $2"
if [[ $2 =~ "ring" ]] || [[ $2 =~ "full" ]] || [[ $2 =~ "tree" ]]; then
 topology="$2"

# default to start topology if no valid value is given
else
 topology="star"
fi
echo "Network topology set to $topology"


# Wait for the redis node
echo "Wait for redis"
sleep 30
kubectl wait --for=condition=ready pod -l app=redisnode

# Scale the lotus nodes
echo "scale to ${scale}"
kubectl scale --replicas="${scale}" -f ./deploy/lotus.yaml

# Save values in redis for the nodes to read
./redis-cli/rediscli w nettopology "$topology"
./redis-cli/rediscli w fil-nodes "$(($scale - 1))"

if [[ $3 =~ "true" ]]; then
  ./redis-cli/rediscli w SingleBlock "true"
fi


# Wait for all nodes
echo "Wait for all node ready"


for i in $(seq 0 $(($scale - 1)))
do
  # sleep until the node reports it self as started
  while ! ./redis-cli/rediscli r lotus-node-${i}-started; do
      sleep 1
  done
done

echo "All nodes ready"
