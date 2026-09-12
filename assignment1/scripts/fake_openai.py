"""Stand-in for OpenAI's transcription endpoint so the tests are fast, free, and repeatable,
"""
import json
import os
import sys
import time
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler

DELAY = float(os.environ.get("FAKE_DELAY", "0"))
EXPECTED_AUTH = "Bearer " + os.environ["EXPECTED_KEY"]


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self._send(200, {"ok": True})

    def do_POST(self):
        body = self._read_body()
        if self.headers.get("Authorization") != EXPECTED_AUTH:
            return self._send(401, {"error": {"message": "Incorrect API key provided."}})
        for code in (401, 429, 500):
            if f"TRIGGER_{code}".encode() in body:
                return self._send(code, {"error": {"message": f"Simulated upstream {code}"}})
        time.sleep(DELAY)
        self._send(200, {
            "text": "hello from fake openai",
            "usage": {"input_tokens": 10, "output_tokens": 2, "total_tokens": 12},
        })

    def _read_body(self):
        if self.headers.get("Transfer-Encoding", "").lower() != "chunked":
            return self.rfile.read(int(self.headers.get("Content-Length", 0)))
        data = b""
        while True:
            size = int(self.rfile.readline().split(b";")[0].strip(), 16)
            if size == 0:
                while self.rfile.readline().strip():  # skip trailers
                    pass
                return data
            data += self.rfile.read(size)
            self.rfile.readline()

    def _send(self, status, payload):
        data = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt, *args):
        pass


class Server(ThreadingHTTPServer):
    request_queue_size = 128  # default of 5 would stall bursts of concurrent uploads


Server(("127.0.0.1", int(sys.argv[1])), Handler).serve_forever()
