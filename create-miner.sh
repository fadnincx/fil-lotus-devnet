#!/bin/bash

echo -n "Create Miner on lotus-node-#: "
read nodeId


# create wallets
ownerWallet=$(k3s kubectl exec --stdin --tty lotus-node-${nodeId} -- lotus wallet new bls)
workerWallet=$(k3s kubectl exec --stdin --tty lotus-node-${nodeId} -- lotus wallet new bls)

# transfer funds
fundOwner=$(k3s kubectl exec --stdin --tty lotus-node-0 -- lotus send ${ownerWallet} 1000)
fundWorker=$(k3s kubectl exec --stdin --tty lotus-node-0 -- lotus send ${workerWallet} 1000)
k3s kubectl exec --stdin --tty lotus-node-0 -- lotus state wait-msg ${fundOwner}
k3s kubectl exec --stdin --tty lotus-node-0 -- lotus state wait-msg ${fundWorker}

# init miner
k3s kubectl exec --stdin --tty lotus-node-${nodeId} -- lotus-miner init --sector-size=2KiB --owner=${ownerWallet}  --worker=$workerWallet --no-local-storage --nosync


k3s kubectl exec --stdin --tty lotus-node-${nodeId} -- lotus-miner run

k3s kubectl exec --stdin --tty lotus-node-${nodeId} -- lotus-miner sectors pledge


