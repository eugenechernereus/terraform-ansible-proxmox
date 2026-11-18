#!/usr/bin/env python3

import json
import os
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer


class AppHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        response = {
            "message": "Hello from Python!",
            "hostname": socket.gethostname(),
            "path": self.path,
        }

        body = (json.dumps(response, ensure_ascii=False) + "\n").encode("utf-8")

        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    host = os.environ.get("APP_BIND_ADDRESS", "0.0.0.0")
    port = int(os.environ.get("APP_PORT", "3000"))

    server = HTTPServer((host, port), AppHandler)
    print(f"Server listening on http://{host}:{port}", flush=True)
    server.serve_forever()

