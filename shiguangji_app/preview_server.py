#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
食光记 Flutter Web 预览服务器（同源代理）：
- / 下静态资源 → shiguangji_app/build/web
- /api/* 与 /uploads/* 与 /actuator/health → 转发到后端 http://localhost:8080
让浏览器与 API 同源，彻底规避 CORS。

用法：python preview_server.py [port]   默认 8889
登录页「服务器地址」填：http://127.0.0.1:<port>
"""
import http.server
import os
import socketserver
import sys
import urllib.error
import urllib.request

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
WEB_DIR = os.path.join(BASE_DIR, 'build', 'web')
BACKEND = os.environ.get('SGJ_BACKEND', 'http://localhost:8080')

PROXY_PREFIXES = ('/api/', '/uploads/', '/actuator')


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=WEB_DIR, **k)

    def _is_proxy(self):
        return any(self.path.startswith(p) for p in PROXY_PREFIXES)

    def do_GET(self):
        if self._is_proxy():
            return self._proxy()
        return super().do_GET()

    def do_POST(self):
        if self._is_proxy():
            return self._proxy()
        self.send_error(405)

    def do_PUT(self):
        if self._is_proxy():
            return self._proxy()
        self.send_error(405)

    def do_DELETE(self):
        if self._is_proxy():
            return self._proxy()
        self.send_error(405)

    def do_OPTIONS(self):
        # 同源不需要预检，但兜底返回 204
        self.send_response(204)
        self.end_headers()

    def _proxy(self):
        url = BACKEND + self.path
        # 转发请求头（去掉 hop-by-hop）
        skip = ('host', 'content-length', 'connection', 'transfer-encoding',
                'accept-encoding')
        headers = {k: v for k, v in self.headers.items() if k.lower() not in skip}
        body = None
        length = self.headers.get('Content-Length')
        if length:
            body = self.rfile.read(int(length))
        req = urllib.request.Request(url, data=body, method=self.command, headers=headers)
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = resp.read()
                self.send_response(resp.status)
                for k, v in resp.headers.items():
                    if k.lower() in ('transfer-encoding', 'connection',
                                     'content-encoding', 'content-length'):
                        continue
                    self.send_header(k, v)
                self.send_header('Content-Length', str(len(data)))
                self.end_headers()
                self.wfile.write(data)
        except urllib.error.HTTPError as e:
            data = e.read()
            self.send_response(e.code)
            self.send_header('Content-Type', e.headers.get('Content-Type', 'application/json'))
            self.send_header('Content-Length', str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        except Exception as e:
            msg = ('{"code":-1,"message":"代理无法连接后端 ' + BACKEND +
                   '：' + str(e) + '"}').encode()
            self.send_response(502)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(msg)))
            self.end_headers()
            self.wfile.write(msg)

    def log_message(self, fmt, *args):
        sys.stderr.write("[preview] %s - %s\n" % (self.command, self.path))


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8889
    print('preview server on http://127.0.0.1:%d  (web=%s, backend=%s)' % (port, WEB_DIR, BACKEND))
    print('登录页服务器地址填：http://127.0.0.1:%d' % port)
    with Server(('127.0.0.1', port), Handler) as s:
        s.serve_forever()
