// 빌드한 웹 앱의 미리보기 화면(/#/demo/preview?kind=<종류>)을 찍어 랜딩의 미리보기 이미지로 둔다.
// 무엇을 어떤 크기로 찍을지는 빌드된 index.html의 data-preview 요소(width·height·src/srcset)가 정한다.
// 사용: node capture.mjs <웹 빌드 폴더>   (Chrome 경로: CHROME_PATH 또는 PUPPETEER_EXECUTABLE_PATH)
import { existsSync } from 'node:fs';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import http from 'node:http';
import path from 'node:path';
import puppeteer from 'puppeteer-core';

const SCALE = 3;
const READY_TIMEOUT_MS = 60000;

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript',
  '.mjs': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.webp': 'image/webp',
  '.ico': 'image/x-icon',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.woff2': 'font/woff2',
};

const root = path.resolve(process.argv[2] ?? '');
if (!process.argv[2] || !existsSync(path.join(root, 'index.html'))) {
  console.error('사용: node capture.mjs <index.html이 있는 웹 빌드 폴더>');
  process.exit(2);
}

function findChrome() {
  const fromEnv = process.env.CHROME_PATH || process.env.PUPPETEER_EXECUTABLE_PATH;
  if (fromEnv) return fromEnv;
  for (const name of ['google-chrome', 'chromium-browser', 'chromium']) {
    for (const dir of (process.env.PATH ?? '').split(path.delimiter)) {
      if (existsSync(path.join(dir, name))) return path.join(dir, name);
    }
  }
  throw new Error('Chrome을 찾지 못했습니다. CHROME_PATH에 실행 파일 경로를 주세요.');
}

// 빌드 폴더를 그대로 내보낸다. 앱 주소는 해시라 / 하나면 된다
function serve() {
  const server = http.createServer(async (req, res) => {
    const urlPath = decodeURIComponent(new URL(req.url, 'http://x').pathname);
    const file = path.join(root, urlPath === '/' ? 'index.html' : urlPath);
    if (!file.startsWith(root + path.sep)) return res.writeHead(403).end();
    try {
      const body = await readFile(file);
      res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] ?? 'application/octet-stream' });
      res.end(body);
    } catch {
      res.writeHead(404).end();
    }
  });
  return new Promise((resolve) => {
    server.listen(0, '127.0.0.1', () => resolve(server));
  });
}

// 스크립트를 끈 채 index.html을 열어 data-preview 요소(<img>, <picture>의 <source>)를 모은다
async function readSlots(browser, origin) {
  const page = await browser.newPage();
  await page.setJavaScriptEnabled(false);
  await page.goto(`${origin}/`);
  const slots = await page.$$eval('[data-preview]', (els) => els.map((el) => ({
    kind: el.getAttribute('data-preview'),
    width: Number(el.getAttribute('width')),
    height: Number(el.getAttribute('height')),
    url: (el.getAttribute('src') || el.getAttribute('srcset') || '').trim().split(/\s+/)[0],
  })));
  await page.close();
  if (slots.length === 0) throw new Error('index.html에 data-preview 요소가 없습니다.');
  for (const s of slots) {
    if (!Number.isInteger(s.width) || !Number.isInteger(s.height) || !s.url.startsWith('/')) {
      throw new Error(`data-preview="${s.kind}" 요소의 width·height·src(srcset)가 올바르지 않습니다: ${JSON.stringify(s)}`);
    }
  }
  return slots;
}

// WebP 머리에서 픽셀 크기를 읽는다 (VP8 손실, VP8L 무손실, VP8X 확장)
function webpSize(buf) {
  const chunk = buf.toString('ascii', 12, 16);
  if (chunk === 'VP8 ') return [buf.readUInt16LE(26) & 0x3fff, buf.readUInt16LE(28) & 0x3fff];
  if (chunk === 'VP8L') {
    const bits = buf.readUInt32LE(21);
    return [(bits & 0x3fff) + 1, ((bits >> 14) & 0x3fff) + 1];
  }
  if (chunk === 'VP8X') return [buf.readUIntLE(24, 3) + 1, buf.readUIntLE(27, 3) + 1];
  return [0, 0];
}

async function capture(browser, origin, { kind, width, height, url }) {
  const page = await browser.newPage();
  try {
    await page.setViewport({ width, height, deviceScaleFactor: SCALE });
    await page.goto(`${origin}/#/demo/preview?kind=${encodeURIComponent(kind)}`);
    await page.waitForFunction(
      (k) => window.__momeet && window.__momeet.previewReady === k,
      { timeout: READY_TIMEOUT_MS },
      kind,
    );
    await page.addStyleTag({ content: '#loading, #consent-banner { display: none !important; }' });
    // 앱이 빠진 글자의 대체 글꼴을 늦게 받을 수 있어 네트워크가 잠시 조용해질 때까지 기다린다
    await page.waitForNetworkIdle({ idleTime: 500 });
    const image = Buffer.from(await page.screenshot({ type: 'webp', quality: 90 }));
    const [w, h] = webpSize(image);
    if (w !== width * SCALE || h !== height * SCALE) {
      throw new Error(`찍힌 크기 ${w}×${h}가 ${width * SCALE}×${height * SCALE}와 다릅니다.`);
    }
    const file = path.join(root, url);
    await mkdir(path.dirname(file), { recursive: true });
    await writeFile(file, image);
    console.log(`${url}  ${kind} ${width}×${height}  ${Math.round(image.length / 1024)}KB`);
  } finally {
    await page.close();
  }
}

const server = await serve();
const origin = `http://127.0.0.1:${server.address().port}`;
const browser = await puppeteer.launch({ executablePath: findChrome(), args: ['--no-sandbox'] });
try {
  for (const slot of await readSlots(browser, origin)) {
    try {
      await capture(browser, origin, slot);
    } catch (e) {
      throw new Error(`${slot.url} (${slot.kind} ${slot.width}×${slot.height}): ${e.message}`);
    }
  }
} catch (e) {
  console.error(`미리보기를 찍지 못했습니다. ${e.message}`);
  process.exitCode = 1;
} finally {
  await browser.close();
  server.close();
}
