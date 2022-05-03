package main

import (
	"fmt"
	"io"
	"net"
)

func rpcExposer(internalAddr string, exposeAddr string) {
	ln, err := net.Listen("tcp", exposeAddr)
	if err != nil {
		panic(err)
	}

	for {
		conn, err := ln.Accept()
		if err != nil {
			panic(err)
		}

		go handlerRcpRequest(conn, internalAddr)
	}
}

func handlerRcpRequest(conn net.Conn, addr string) {
	fmt.Println("new client")

	proxy, err := net.Dial("tcp", addr)
	if err != nil {
		panic(err)
	}

	fmt.Println("proxy connected")
	go copyIO(conn, proxy)
	go copyIO(proxy, conn)
}

func copyIO(src, dest net.Conn) {
	defer src.Close()
	defer dest.Close()
	io.Copy(src, dest)
}
