// Captures the app screens from a demo-mode web build.
//
//   node capture.mjs <build/web> <out-dir>
//
// Each screen is opened through the demo launch options in the URL, at the
// device-frames viewport: 430x878 CSS pixels at 3x (a Pro Max screen minus
// the status bar), so the frames add their own status bar.
import { mkdirSync } from 'node:fs';
import { readFile } from 'node:fs/promises';
import { createServer } from 'node:http';
import { extname, join, normalize, resolve } from 'node:path';
import puppeteer from 'puppeteer-core';

const [root = '../../build/web', outDir = 'screenshots-raw'] = process.argv.slice(2);
const webRoot = resolve(root);
mkdirSync(outDir, { recursive: true });

const screens = [
  ['market_data', '?tab=market&theme=dark'],
  ['market_detail', '?tab=market&theme=dark&symbol=BTC%2FUSD'],
  ['analytics', '?tab=analytics&theme=dark'],
  ['portfolio', '?tab=portfolio&theme=dark'],
  ['light_mode', '?tab=portfolio&theme=light'],
];

const types = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.json': 'application/json', '.wasm': 'application/wasm', '.png': 'image/png',
  '.otf': 'font/otf', '.ttf': 'font/ttf', '.css': 'text/css', '.frag': 'application/octet-stream',
};
const server = createServer(async (req, res) => {
  const path = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  const file = normalize(join(webRoot, path === '/' ? 'index.html' : path));
  if (!file.startsWith(webRoot)) return res.writeHead(403).end();
  try {
    const body = await readFile(file);
    res.writeHead(200, { 'Content-Type': types[extname(file)] ?? 'application/octet-stream' });
    res.end(body);
  } catch {
    res.writeHead(404).end();
  }
});
await new Promise((r) => server.listen(8080, r));

const browser = await puppeteer.launch({
  executablePath: process.env.CHROME ?? '/usr/bin/google-chrome',
  headless: true,
  args: ['--no-sandbox', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--hide-scrollbars'],
});
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

try {
  for (const [name, query] of screens) {
    const page = await browser.newPage();
    page.on('pageerror', (e) => console.error(`[${name}] page error: ${e.message}`));
    await page.setViewport({ width: 430, height: 878, deviceScaleFactor: 3, isMobile: true, hasTouch: true });
    await page.goto(`http://localhost:8080/${query}`, { waitUntil: 'networkidle0', timeout: 120000 });
    await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 60000 });
    // Data loads, skeletons fade and chart animations finish.
    await sleep(4000);
    await page.screenshot({ path: join(outDir, `${name}.png`) });
    console.log(`captured ${name}`);
    await page.close();
  }
} finally {
  await browser.close();
  server.close();
}
