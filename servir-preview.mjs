// Servidor estático mínimo (só Node, sem dependências) para a preview do app.
//
// Uso: node servir-preview.mjs <pasta> [porta]

import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname, join, normalize } from 'node:path';

const raiz = normalize(process.argv[2]);
const porta = Number(process.argv[3] ?? 8123);

const tipos = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.map': 'application/json',
};

const servidor = http.createServer(async (req, res) => {
  try {
    let caminho = decodeURIComponent(new URL(req.url, 'http://local').pathname);
    if (caminho === '/') caminho = '/index.html';

    const arquivo = normalize(join(raiz, caminho));
    if (!arquivo.startsWith(raiz)) {
      res.writeHead(403).end('fora da pasta');
      return;
    }

    const dados = await readFile(arquivo);
    res.writeHead(200, {
      'Content-Type': tipos[extname(arquivo)] ?? 'application/octet-stream',
      'Cache-Control': 'no-store',
    });
    res.end(dados);
  } catch {
    res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('nao encontrado');
  }
});

servidor.listen(porta, '127.0.0.1', () => {
  console.log(`[preview] servindo ${raiz}`);
  console.log(`[preview] abra: http://127.0.0.1:${porta}`);
});
