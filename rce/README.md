
# RCE (Remote Code Execution)

This Repository is part of the master thesis of Marcel Würsten \"Filecoin Consensus Performance Analysis\"

## Usage

** Warning! Never run this program on a public accessible host!**

Once this program is running, it exposes a port which can be called to execute any bash command!

Additionally, it proxies the local TCP port 127.0.0.1:1234 to the general TCP port 0.0.0.0:3000

### Example Usage

When `192.168.1.2` is the host your running RCE, you can execute

```bash
curl http://192.168.1.2?whoami
```
this should return the user running rce.

Generally sou can call
```bash
curl http://<ip>?<urlencoded command>
```


## Requirements

To build this program from you need [Golang 1.18](https://go.dev/)