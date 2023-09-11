from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse
import json
import requests
import os
import sys

address = ('0.0.0.0', 80)

baseurl_get=os.getenv('BASEURL_GET','http://webgateway')
baseurl_post=os.getenv('BASEURL_POST','http://webgateway')

class MyHTTPRequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # flush=trueを付けないとファイル書き出しが遅延する。
        print('GET reuqest', flush=True)
        parsed_path = urlparse(self.path)
        self.send_response(200)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.end_headers()

        # answer loadbalancer
        if parsed_path.path=="/":
            result = { 'Status':'OK' }
            self.wfile.write(json.dumps(result).encode())
        else:
            url=baseurl_get+parsed_path.path
            print('Sending GET reuqest',flush=True)
            response=requests.get(url,headers=self.headers)
            print('Writing response',flush=True)

            self.wfile.write(response.content)
            #result = { 'Result': {'Status': 1, 'version': 1.0} }
            #self.wfile.write(json.dumps(result).encode())

        self.wfile.flush()

    def do_POST(self):
        print('path = {}'.format(self.path),flush=True)

        parsed_path = urlparse(self.path)
        content_length = int(self.headers['content-length'])
        body=self.rfile.read(content_length).decode('utf-8')
        #result = { 'Result': {'Status': 1, 'version': 1.0} }
        #body=self.wfile.write(json.dumps(result).encode())

        url=baseurl_post+parsed_path.path
        response=requests.post(url,headers=self.headers,json=body)

        self.send_response(200)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.end_headers()

        self.wfile.write(response.content)
        self.wfile.flush()

sys.stdout = open('debug.log', 'a+')
# ThreadingHTTPServerを使用しないとservice(type:LoadBalancer)使用時に、Recv-Qがあふれてパフォーマンスが大幅劣化する。
with ThreadingHTTPServer(address, MyHTTPRequestHandler) as server:
    server.serve_forever()