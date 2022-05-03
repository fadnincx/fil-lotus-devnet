# Redis Cli

This Repository is part of the master thesis of Marcel Würsten \"Filecoin Consensus Performance Analysis\"

## Purpose

A small cli wrapper to read/write data from redis.

## Usage

### Read

To read the key `alicesKey`
```bash
./rediscli r "alicesKey"
```

### Write
To write a value for a key to redis
```bash
./rediscli w "alicesKey" "My secret about Bob"
```

### Scan
If you want to know the keys available in redis you can scan for them
```bash
./rediscli a "alice*"
```
would return all keys starting with `alice`

## Requirements

To build this program from you need [Golang 1.18](https://go.dev/)

