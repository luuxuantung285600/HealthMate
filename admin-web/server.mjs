import http from 'node:http';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('./dist/', import.meta.url));
const types = { '.html':'text/html; charset=utf-8', '.css':'text/css; charset=utf-8', '.mjs':'text/javascript; charset=utf-8', '.js':'text/javascript; charset=utf-8', '.ttf':'font/ttf', '.woff2':'font/woff2', '.txt':'text/plain; charset=utf-8' };
const server = http.createServer(async (request,response) => {
  try {
    const pathname = decodeURIComponent(new URL(request.url,'http://localhost').pathname);
    const file = path.resolve(root,'.'+(pathname === '/' ? '/index.html' : pathname));
    if (!file.startsWith(root) || !types[path.extname(file)] || !['GET','HEAD'].includes(request.method)) { response.writeHead(404).end(); return; }
    const data = await readFile(file);
    response.writeHead(200,{
      'Content-Type':types[path.extname(file)],'Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Referrer-Policy':'no-referrer',
      'Content-Security-Policy': "default-src 'self'; script-src 'self' https://www.gstatic.com https://www.google.com https://www.recaptcha.net https://apis.google.com; style-src 'self'; font-src 'self'; img-src 'self' data:; connect-src 'self' http://127.0.0.1:8092 http://127.0.0.1:9098 https://*.googleapis.com https://*.firebaseio.com https://*.firebaseapp.com https://www.gstatic.com https://www.google.com; frame-src https://*.firebaseapp.com https://www.google.com https://www.recaptcha.net; object-src 'none'; base-uri 'self'; frame-ancestors 'none'"
    });
    response.end(request.method === 'HEAD' ? undefined : data);
  } catch { response.writeHead(404).end('Not found'); }
});
server.listen(4173,'127.0.0.1',() => process.stdout.write('HealthMate Admin: http://127.0.0.1:4173\n'));
for (const signal of ['SIGINT','SIGTERM']) process.on(signal,() => server.close(() => process.exit()));
