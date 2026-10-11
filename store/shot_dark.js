// Capture the surah list in DARK mode.
//
// The app's ThemeMode is driven by its own stored setting (systemTheme
// defaults to false), so emulating prefers-color-scheme does nothing. The
// setting lives in SharedPreferences -> localStorage as `flutter.dark`, so we
// seed it before the app boots and reload.
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

  // 1) establish origin so localStorage is writable
  await send('Page.navigate', { url: URL });
  await sleep(9000);

  // 2) seed the app's own dark setting (SharedPreferences web -> `flutter.<key>`)
  const r = await send('Runtime.evaluate', {
    expression: `(() => {
      localStorage.setItem('flutter.dark', 'true');
      localStorage.setItem('flutter.systemTheme', 'false');
      return localStorage.getItem('flutter.dark');
    })()`,
    returnByValue: true,
  });
  console.log('  seeded flutter.dark =', r.result.value);

  // 3) reload so the app reads it at boot
  await send('Page.navigate', { url: URL + '?dark=1' });
  await sleep(16000);
  await send('Runtime.evaluate', {
    expression: "(() => { const b=document.getElementById('apk-banner'); if(b) b.remove(); return 1; })()",
  });

  // 4) go to the Qur'an tab
  for (const type of ['mousePressed', 'mouseReleased'])
    await send('Input.dispatchMouseEvent', { type, x: NAV_QURAN_X, y: NAV_Y, button: 'left', clickCount: 1 });
  await sleep(3500);
  await sleep(1200);

  const { data } = await send('Page.captureScreenshot', { format: 'png' });
  const p = `${OUT}\\list-dark.png`;
  fs.writeFileSync(p, Buffer.from(data, 'base64'));
  console.log(`  list-dark.png (${fs.statSync(p).size}B)`);

  ws.close();
  process.exit(0);
})().catch((e) => { console.log('ERROR ' + e.message); process.exit(1); });
