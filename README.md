
# FIL-Lotus-Devnet

This Repository is part of the master thesis of Marcel Würsten \"Filecoin Consensus Performance Analysis\"


## Installation

### K3s
Install k3s
> Linux amd64
```
curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_START=true INSTALL_K3S_SKIP_ENABLE=true sh -s
```

Similar steps for others platforms in https://rancher.com/docs/k3s/latest/en/quick-start/

### Golang

If you want/need to recompile the Go binaries, [Golang 1.18](https://go.dev/) is required

## Usage


### Start K3s
Start the k3s engine with 

```bash
./boot.sh
```

### Simple Network start
You can then tart a dev net with
```bash
./build_start.sh
```

Once all nodes are up and ready (can take a while), the script returns after printing a corresponding message

### Advanced Network start
You can additionaly specify how many nodes should be spawned and what topology should be used.

**Warning: not all topologies work with any number of nodes!**

Default values are 8 nodes in a `star` topology.

```
./build_start.sh <# of nodes> <topology>
```

### Supported topologies

* `star` default, all nodes connect to node-0
* `ring` all nodes have exactly two connection and form a ring
* `full` all nodes connect to all other nodes --> might lead to dropped connections
* `tree` the nodes form a tree with each node having 2 leafs if there are enough nodes


### Stop Network

To stop the network run
```bash
./stop.sh
```

### Kill k3s

To kill the k3s engine call
```bash
./kill.sh
```
**Warning: killing the k3s engine doesn't really cleanup the left over nodes**


### Reset Node Image
Since docker caches the image and we don't always want to rebuild the entire image, if you want to rebuild the image and download the new version after stopping everything just call 
```bash
docker system prune
```

With that you remove the chached data and on next run the image is rebuild entirely.
