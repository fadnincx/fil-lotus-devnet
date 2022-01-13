#!/usr/bin/python3

##############################################################
# Filecoin testbed RCE, University of Bern, Marcel Wuersten  #
##############################################################

import http.server
import urllib.parse as urlparse
import logging
import os
import subprocess

class Handler(http.server.BaseHTTPRequestHandler):
    """
    Handler Class for Python HTTP Server
    """

    def do_GET(self):
        """
        Method answering GET Requests
        """

        # print some logging informations
        logging.info("GET request, \nPath: %s\nHeaders:\n%s\n", str(self.path),str(self.headers))

        # send header (status 200 and content-type plaintext)
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin","*")
        

        # split path into path and params
        qs = ''
        path = self.path
        if "?" in path:
            path, qs = path.split("?", 1)
            
        if len(qs) == 0:
            if path == '/commandcenter.html':
              with open('commandcenter.html', 'rb') as file: 
                self.send_header("Content-type", "text/html")
                self.end_headers()
                self.wfile.write(file.read()) # Read the file and send the contents 
            else: 
                self.send_header("Content-type", "text/plain")
                self.end_headers() 
                self.wfile.write("No Command given!".encode("utf-8"))
        else:
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            process = subprocess.Popen(urlparse.unquote(qs), shell=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            self.wfile.write(process.communicate()[0].encode("utf-8"))


def run(server_class=http.server.HTTPServer, handler_class=Handler, port=80):
    """
    Basic function to start/run a http server
    """

    # define logging level
    logging.basicConfig(level=logging.INFO)

    # define servers listening address and port
    server_address = ('0.0.0.0', port)

    # define http server
    http = server_class(server_address, handler_class)

    # print info that server is started
    logging.info('Starting http server...\n')

    # try to server server until stopped
    try:
        http.serve_forever()
    except KeyboardInterrupt:
        pass

    # shutdown http servver
    http.server_close()

    # print info that server is stopped
    logging.info('Stopping http server...\n')


# basic python startup with optional port as param
if __name__ == '__main__':
    from sys import argv

    if len(argv) == 2:
        run(port=int(argv[1]))
    else:
        run()

