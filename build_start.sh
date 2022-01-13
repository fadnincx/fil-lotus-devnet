#!/bin/bash

docker image build -t marcelwuersten/filecoin-lotus:latest -f lotus.dockerfile .
nohup bash -c "k3s server --docker &"
sleep 5
k3s kubectl apply -f ./deploy
k3s kubectl scale --replicas=3 -f ./deploy/deployment.yaml
