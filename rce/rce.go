package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os/exec"
	"strconv"
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

func getUrlParam(r *http.Request, key string) (string, bool) {
	values, ok := r.URL.Query()[key]

	if !ok || len(values[0]) < 1 {
		fmt.Printf("Url Param '%v' is missing\n", key)
		return "", false
	}

	return values[0], true
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

var sendMsgAtRateLastStopChannel chan bool = nil
var sendMsgAtRateLastResultChannel chan avgDelayResult = nil
var sendMsgAtRateLastRate float64 = 0.0

func sendMsgAtRate(w http.ResponseWriter, r *http.Request) {
	fmt.Println("send MsgAtRate")
	destWallet, ok := getUrlParam(r, "dest")
	if !ok {
		fmt.Fprintf(w, "Url Param 'dest' is missing")
	}
	amount, ok := getUrlParam(r, "amount")
	if !ok {
		fmt.Fprintf(w, "Url Param 'amount' is missing")
	}
	rateS, ok := getUrlParam(r, "rate")
	if !ok {
		fmt.Fprintf(w, "Url Param 'rate' is missing")
	}
	rate, err := strconv.ParseFloat(rateS, 64)
	if err != nil {
		fmt.Fprintf(w, "Rate is not a float: %v", err)
	}

	if sendMsgAtRateLastStopChannel != nil {
		fmt.Println("Stop channel is not nil")
		sendMsgAtRateLastStopChannel <- true
		fmt.Println("Wait for results")
		result := <-sendMsgAtRateLastResultChannel
		fmt.Fprintf(w, "Last Result: @%f msg/s over %d msg avg delay is %f\n", sendMsgAtRateLastRate, result.amount, result.avgDelay)
		close(sendMsgAtRateLastStopChannel)
		close(sendMsgAtRateLastResultChannel)
	}
	sendMsgNewResultChannel := make(chan avgDelayResult)
	sendMsgNewStopChannel := make(chan bool)

	go sendAtRate(destWallet, amount, rate, sendMsgNewStopChannel, sendMsgNewResultChannel)
	fmt.Println("Started new Rate")

	sendMsgAtRateLastRate = rate
	sendMsgAtRateLastStopChannel = sendMsgNewStopChannel
	sendMsgAtRateLastResultChannel = sendMsgNewResultChannel
	fmt.Println("Request done")
}

func handleRequests() {
	http.HandleFunc("/", rceRequest)
	log.Fatal(http.ListenAndServe(":80", nil))
}

func main() {
	go rpcExposer(":3000")
	handleRequests()
}
