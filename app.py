"""A very small web server for the secure deployment pipeline project."""

import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class WebsiteHandler(BaseHTTPRequestHandler):
    """Handle HTTP GET requests sent to the website."""

    def do_GET(self) -> None:
        """Return a response based on the requested URL path."""
        if self.path == "/":
            self.send_text(200, "Secure Pipeline Application is Running\n")
        elif self.path == "/healthz":
            self.send_text(200, "OK\n")
        else:
            self.send_text(404, "Not Found\n")

    def send_text(self, status_code: int, text: str) -> None:
        """Send a plain-text HTTP response."""
        response_body = text.encode("utf-8")

        self.send_response(status_code)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(response_body)))
        self.end_headers()
        self.wfile.write(response_body)


def main() -> None:
    """Start the web server."""
    port = int(os.environ.get("PORT", "8080"))
    server = ThreadingHTTPServer(("0.0.0.0", port), WebsiteHandler)

    print(f"Server running on http://0.0.0.0:{port}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
