from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlparse
import json
import sys

address = ('0.0.0.0', 8080)

class MyHTTPRequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # flush=trueを付けないとファイル書き出しが遅延する。
        print('GET reuqest', flush=True)
        parsed_path = urlparse(self.path)
        self.send_response(200)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.end_headers()

        print('Writing response',flush=True)

        result = { 'Result': {'Status': 1, 'version': 1.0} }
        self.wfile.write(json.dumps(result).encode())

        self.wfile.flush()

sys.stdout = open('debug.log', 'a+')
with HTTPServer(address, MyHTTPRequestHandler) as server:
    server.serve_forever()