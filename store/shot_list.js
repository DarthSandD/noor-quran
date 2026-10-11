// Verify the surah-list row layout in BOTH light and dark mode.
// Drives headless Chrome over raw CDP (the browser-use daemon and Playwright
// both hang on this box; plain Chrome + WebSocket is reliable).
const http = require('http');
const WebSocket = require('ws');
const fs = require('fs');

const OUT = 'C:\\Users\\USER\\quran_app\\store\\qa';
const URL = 'https://noor-quran-wheat.vercel.app/';
const PORT = 9222;
const VW = 1080, VH = 1920;
const NAV_Y = 1856, NAV_QURAN_X = 324;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function getJSON(path) {
  return new Promise((res, rej) => {
    http.get({ host: '127.0.0.1', port: PORT, path }, (r) => {
      let d = '';
      r.on('data', (c) => (d += c));
      r.on('end', () => res(JSON.parse(d)));
    }).on('error', rej);
  });
}

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const targets = await getJSON('/json/list');
  const page = targets.find((t) => t.type === 'page');
  const ws = new WebSocket(page.webSocketDebuggerUrl, { perMessageDeflate: false });
  let id = 0;
  const pending = new Map();
  const send = (method, params = {}) =>
    new Promise((res, rej) => {
      const mid = ++id;
      pending.set(mid, { res, rej });
      ws.send(JSON.stringify({ id: mid, method, params }));
    });
  ws.on('message', (m) => {
    const msg = JSON.parse(m);
    if (msg.id && pending.has(msg.id)) {
      const { res, rej } = pending.get(msg.id);
      pending.delete(msg.id);
      msg.error ? rej(new Error(msg.error.message)) : res(msg.result);
    }
  });
  await new Promise((r) => ws.on('open', r));

  await send('Page.enable');
  await send('Emulation.setDeviceMetricsOverride', { width: VW, height: VH, deviceScaleFactor: 1, mobile: true });

  const tap = async (x, y, wait) => {
    for (const type of ['mousePressed', 'mouseReleased'])
      await send('Input.dispatchMouseEvent', { type, x, y, button: 'left', clickCount: 1 });
    await sleep(wait);
  };
  const shot = async (name) => {
    const { data } = await send('Page.captureScreenshot', { format: 'png' });
    const p = `${OUT}\\${name}.png`;
    fs.writeFileSync(p, Buffer.from(data, 'base64'));
    console.log(`  ${name}.png (${fs.statSync(p).size}B)`);
  };

  for (const scheme of ['light', 'dark']) {
    await send('Emulation.setEmulatedMedia', {
      media: 'screen',
      features: [{ name: 'prefers-color-scheme', value: scheme }],
    });
    // Cache-buster forces a genuine reload so Flutter re-reads the colour scheme.
    await send('Page.navigate', { url: URL + '?theme=' + scheme });
    await sleep(16000);
    await send('Runtime.evaluate', {
      expression: "(() => { const b=document.getElementById('apk-banner'); if(b) b.remove(); return 1; })()",
    });
    await tap(NAV_QURAN_X, NAV_Y, 3500); // Qur'an tab
    await sleep(1200);
    await shot(`list-${scheme}`);
  }

  ws.close();
  console.log('done');
  process.exit(0);
})().catch((e) => { console.log('ERROR ' + e.message); process.exit(1); });
