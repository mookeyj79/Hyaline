import http.server,sys
class H(http.server.BaseHTTPRequestHandler):
    def _r(self):
        sys.stderr.write(f"{self.command} {self.path}\n"); sys.stderr.flush()
        self.send_response(404); self.send_header("Content-Length","0"); self.end_headers()
    do_GET=do_POST=do_HEAD=_r
http.server.ThreadingHTTPServer(("127.0.0.1",8787),H).serve_forever()
