#!/usr/bin/env python3
# Mini-serveur local pour "Mon budget".
# Sert le dossier de l'app en empechant le cache du navigateur :
# ainsi un simple Cmd + R recharge toujours la toute derniere version.
import os
from http.server import HTTPServer, SimpleHTTPRequestHandler

PORT = 8910
DIRECTORY = os.path.dirname(os.path.abspath(__file__))


class NoCacheHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        # Force le navigateur a toujours redemander le fichier (pas de cache)
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

    def log_message(self, *args):
        pass  # silencieux


if __name__ == "__main__":
    HTTPServer(("127.0.0.1", PORT), NoCacheHandler).serve_forever()
