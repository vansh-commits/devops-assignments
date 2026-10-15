from http.server import BaseHTTPRequestHandler, HTTPServer

class HelloHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        self.end_headers()
        self.wfile.write(b"<h1>Hello World from Python app running in Docker!</h1>")

    def log_message(self, fmt, *args):
        pass

if __name__ == "__main__":
    print("Python app listening on port 5000")
    HTTPServer(("0.0.0.0", 5000), HelloHandler).serve_forever()
