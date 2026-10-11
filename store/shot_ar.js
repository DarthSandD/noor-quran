// Capture the surah list in BOTH themes, driving the app's own dark setting.
//
// ThemeMode is driven by the app's stored pref (`systemTheme` defaults false),
// so prefers-color-scheme emulation does nothing. The pref lives in
// SharedPreferences -> localStorage as `flutter.dark`; seed it and reload.
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

  for (const dark of [false, true]) {
    const tag = dark ? 'dark' : 'light';

    await send('Page.navigate', { url: URL });
    await sleep(9000);
    const r = await send('Runtime.evaluate', {
      expression: `(() => { localStorage.setItem('flutter.dark', '${dark}'); localStorage.setItem('flutter.systemTheme','false'); return localStorage.getItem('flutter.dark'); })()`,
      returnByValue: true,
    });
    console.log(`  seeded flutter.dark = ${r.result.value}`);

    await send('Page.navigate', { url: URL + '?t=' + tag });
    await sleep(16000);
    await send('Runtime.evaluate', {
      expression: "(() => { const b=document.getElementById('apk-banner'); if(b) b.remove(); return 1; })()",
    });

    for (const type of ['mousePressed', 'mouseReleased'])
      await send('Input.dispatchMouseEvent', { type, x: NAV_QURAN_X, y: NAV_Y, button: 'left', clickCount: 1 });
    await sleep(4000);

    const { data } = await send('Page.captureScreenshot', { format: 'png' });
    const p = `${OUT}\\list-${tag}.png`;
    fs.writeFileSync(p, Buffer.from(data, 'base64'));
    console.log(`  list-${tag}.png (${fs.statSync(p).size}B)`);
  }

  ws.close();
  process.exit(0);
})().catch((e) => { console.log('ERROR ' + e.message); process.exit(1); });
