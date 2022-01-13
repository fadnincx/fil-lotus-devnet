#! /bin/bash
export LOTUS_SKIP_GENESIS_CHECK=_yes_
export LOTUS_PATH=~/.lotus
export LOTUS_MINER_PATH=~/.lotusminer
mkdir -p /root/.lotus
mkdir -p /root/.lotusminer
mkdir -p /root/.genesis-sectors

tmux new-session -s lotus -d
echo "\033[0;36mStart lotus\033[0;30m"


if [ "$HOSTNAME" == "lotus-node-0" ]; then
    echo "\033[0;36mNo genesis exists\033[0;30m"
    lotus-seed pre-seal --sector-size 2KiB --num-sectors 2 > preseal.out
    echo "pre-seal done"
    lotus-seed genesis new localnet.json > genesis.out
    echo "genesis done"
    lotus-seed genesis add-miner localnet.json ~/.genesis-sectors/pre-seal-t01000.json > genesis-miner.out
    echo "genesis miner done"
    tmux new-window -t lotus:1 lotus daemon --lotus-make-genesis=gen.gen --genesis-template=localnet.json --bootstrap=false
    echo "\033[0;36mdaemon started\033[0;30m"
    lotus wait-api > api-wait.out
    echo "Api waited"
    lotus wallet import --as-default ~/.genesis-sectors/pre-seal-t01000.key
    echo "Wallet imported"
    lotus net listen | head -n 1 > /config/peerID.txt
    echo "Written peerId"
    lotus-miner init --genesis-miner --actor=t01000 --sector-size=2KiB --pre-sealed-sectors=~/.genesis-sectors --pre-sealed-metadata=~/.genesis-sectors/pre-seal-t01000.json --nosync
    echo "Miner initialized"
    tmux new-window -t lotus:3 lotus-miner run --nosync
    echo "\033[0;36mminer started\033[0;30m"
    cp gen.gen /config/gen.gen
    echo "\033[0;36mgenesis copied\033[0;30m"
else
    until [ -f /config/gen.gen ]
    do
        sleep 5
    done
    echo "\033[0;36mgenesis exists\033[0;30m"
    cp /config/gen.gen gen.gen
    echo "\033[0;36mcopied genesis\033[0;30m"
    tmux new-window -t lotus:1 lotus daemon --genesis=gen.gen 
    echo "\033[0;36mstarted daemon\033[0;30m"
    lotus wait-api 
    echo "waited api"
    lotus net connect $(</config/peerID.txt)
    echo "\033[0;36mconnected to \033[0;30m"
fi

echo "\033[0;36mstart remote code execution\033[0;30m"
tmux new-window -t lotus:9 /rce.py

# Port Forward localhost bound port 1234
#socat tcp-listen:8000,reuseaddr,fork tcp:localhost:1234 &
# Run forever until exit
while :
do
	sleep 1
done
