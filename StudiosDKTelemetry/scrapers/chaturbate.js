// Lee balance de tokens cada 5s y envía al background
const SELECTORS = [
  '.token-balance',
  '.js-token-balance',
  '[data-role="token-balance"]'
];

function parseTokens(text) {
  if (!text) return null;
  const clean = text.replace(/[^0-9.]/g, '');
  const val = parseFloat(clean);
  return Number.isFinite(val) ? val : null;
}

function readTokens() {
  for (const sel of SELECTORS) {
    const el = document.querySelector(sel);
    if (el && el.textContent) {
      const tokens = parseTokens(el.textContent);
      if (tokens !== null) return tokens;
    }
  }
  return null;
}

function tick() {
  const tokens = readTokens();
  if (tokens !== null) {
    chrome.runtime.sendMessage({
      type: 'TELEMETRY_UPDATE',
      platform: 'chaturbate',
      tokens,
      ts: Date.now()
    });
  }
}

setInterval(tick, 5000);
tick();
