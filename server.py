#!/usr/bin/env python3
import subprocess
import json
import os
from http.server import HTTPServer, SimpleHTTPRequestHandler

scanner_process = None

class DashboardHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.path = '/index.html'
        return SimpleHTTPRequestHandler.do_GET(self)
    
    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        self.rfile.read(content_length)
        
        if self.path == '/api/start':
            self.start_scanner()
        elif self.path == '/api/stop':
            self.stop_scanner()
        else:
            self.send_response(404)
            self.end_headers()
    
    def start_scanner(self):
        global scanner_process
        try:
            if scanner_process is None or scanner_process.poll() is not None:
                scanner_process = subprocess.Popen(
                    ['python3', 'sds200_scanner.py'],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE
                )
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "started"}).encode())
            else:
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "already running"}).encode())
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"error": str(e)}).encode())
    
    def stop_scanner(self):
        global scanner_process
        try:
            if scanner_process is not None:
                scanner_process.terminate()
                scanner_process.wait(timeout=5)
                scanner_process = None
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "stopped"}).encode())
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"error": str(e)}).encode())

if __name__ == '__main__':
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    server = HTTPServer(('0.0.0.0', 8000), DashboardHandler)
    print('Dashboard running on http://localhost:8000')
    server.serve_forever()
