package main

import (
	"bytes"
	"fmt"
	"github.com/go-redis/redis"
	"log"
	"os"
	"os/exec"
	"strconv"
	"strings"
)

var redisClient *redis.Client = nil

func cmd(command string) (error, string, string) {
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd := exec.Command("bash", "-c", command)
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	err := cmd.Run()
	return err, stdout.String(), stderr.String()
}
func whoami() string {
	err, out, _ := cmd("whoami")
	if err != nil {
		log.Printf("error getting pod amount: %v\n", err)
	}
	return strings.TrimSuffix(out, "\n")
}
func getRedisNode() string {

	err, out, _ := cmd("kubectl get pods -o wide | grep lotus-redis | awk '{print $6}' | wc -l")
	if err != nil {
		log.Printf("error getting pod amount: %v\n", err)
	}
	amount, _ := strconv.Atoi(strings.TrimSuffix(out, "\n"))

	if amount > 0 {
		err, ip, _ := cmd(fmt.Sprintf("kubectl get pods -o wide | grep lotus-redis-0 | awk '{print $6}'"))
		if err != nil {
			log.Printf("error: %v\n", err)
		}
		return strings.TrimSuffix(ip, "\n")
	}

	return ""
}

func main() {

	addr, exist := os.LookupEnv("LOTUS_REDIS_ADDR")
	if !exist {
		// Check that benchmark is run as root, as commands needed to be executed as root
		if whoami() != "root" {
			fmt.Printf("NEED TO RUN AS ROOT!\n")
			return
		}
		addr = getRedisNode() + ":6379"
	}

	redisClient = redis.NewClient(&redis.Options{
		Addr:     addr,
		Password: "",
		DB:       0,
	})
	args := os.Args[1:]

	if args[0] == "r" {
		if len(args) != 2 {
			fmt.Fprintln(os.Stderr, "Need  params: r key")
			os.Exit(1)
			return
		}
		val, err := redisClient.Get(args[1]).Result()
		if err != nil {
			if err != redis.Nil {
				fmt.Fprintf(os.Stderr, "Error reading value to read value: %v\n", err)
				os.Exit(1)
				return
			}
			os.Exit(1)
			return

		} else {
			fmt.Printf("%v\n", val)
		}
	} else if args[0] == "w" {
		if len(args) != 3 {
			fmt.Fprintln(os.Stderr, "Need 3 params: w key value")
			os.Exit(1)
			return
		}
		err := redisClient.Set(args[1], args[2], 0).Err()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error saving value to redis: %v\n", err)
			os.Exit(1)
			return
		}
	} else if args[0] == "d" {
		if len(args) != 2 {
			fmt.Fprintf(os.Stderr, "Need 2 params: d key")
			os.Exit(1)
			return
		}
		err := redisClient.Del(args[1]).Err()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error deleting value from redis: %v\n", err)
			os.Exit(1)
			return
		}
	} else {
		fmt.Fprintf(os.Stderr, "1 param needs to be 'r' to read or 'w' to write")
		os.Exit(1)
		return
	}

}
