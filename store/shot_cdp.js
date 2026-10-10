// Capture Play Store phone screenshots with plain headless Chrome + CDP.
//
// The browser-use daemon and Playwright both hung on this box, but Chrome's own
// --headless=new + --screenshot is reliable. To reach other tabs we drive the
// page over the DevTools WebSocket (Input.dispatchMouseEvent), which needs no
// extra daemon.
const http = require('http');
const WebSocket = require('ws');
const fs = require('fs');

const OUT = 'C:\\Users\\USER\\quran_app\\store\\screenshots';
const URL = 'https://noor-quran-wheat.vercel.app/';
const PORT = 9222;
const VW = 1080, VH = 1920;

const NAV_Y = 1856;
const NAV_X = [108, 324, 540, 756, 972];

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
  const targets = await getJSON('/json/list');
  const page = targets.find((t) => t.type === 'page');
  if (!page) throw new Error('no page target');
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

  await send('Emulation.setDeviceMetricsOverride', { width: VW, height: VH, deviceScaleFactor: 1, mobile: true });
  await send('Page.enable');
  await send('Page.navigate', { url: URL });
  await sleep(16000);

  // Drop the Android-only APK banner (it overlays the nav bar).
  await send('Runtime.evaluate', {
    expression: "(() => { const b=document.getElementById('apk-banner'); if(b) b.remove(); return 1; })()",
  });

  const tap = async (x, y, wait) => {
    for (const type of ['mousePressed', 'mouseReleased']) {
      await send('Input.dispatchMouseEvent', { type, x, y, button: 'left', clickCount: 1 });
    }
    await sleep(wait);
  };
  const shot = async (name) => {
    const { data } = await send('Page.captureScreenshot', { format: 'png' });
    const p = `${OUT}\\${name}.png`;
    fs.writeFileSync(p, Buffer.from(data, 'base64'));
    fs.appendFileSync(OUT + '\\_capture.log', `  ${name}.png (${fs.statSync(p).size}B)\n`);
  };

  fs.writeFileSync(OUT + '\\_capture.log', 'start ' + new Date().toISOString() + '\n');
  await shot('01-home');
  await tap(NAV_X[1], NAV_Y, 3200); await shot('02-surah-list');
  await tap(NAV_X[2], NAV_Y, 3200); await shot('03-kiblat');
  await tap(NAV_X[3], NAV_Y, 3200); await shot('04-doa');
  await tap(NAV_X[4], NAV_Y, 3200); await shot('05-more');

  ws.close();
  fs.appendFileSync(OUT + '\\_capture.log', 'done\n');
  process.exit(0);
})().catch((e) => {
  fs.appendFileSync(OUT + '\\_capture.log', 'ERROR ' + e.message + '\n');
  process.exit(1);
});
