// Recibe datos de los content scripts y los envía al backend local
const ENDPOINT = 'http://localhost:8080/api/tracking/telemetry';

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message?.type === 'TELEMETRY_UPDATE') {
    forwardTelemetry(message)
      .then(() => sendResponse({ ok: true }))
      .catch((err) => sendResponse({ ok: false, error: String(err) }));
    // Mantener canal abierto para respuesta async
    return true;
  }
  return false;
});

async function getRoomId() {
  return new Promise((resolve) => {
    chrome.storage.local.get({ ROOM_ID: null }, (data) => resolve(data.ROOM_ID));
  });
}

async function forwardTelemetry(msg) {
  const roomId = await getRoomId();
  if (!roomId) throw new Error('ROOM_ID not configured');

  const payload = {
    room_id: roomId,
    platforms: {
      [msg.platform]: msg.tokens
    }
  };

  const res = await fetch(ENDPOINT, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });

  if (!res.ok) throw new Error(`HTTP ${res.status}`);
}
