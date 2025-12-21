const roomInput = document.getElementById('room');
const stateEl = document.getElementById('state');
const saveBtn = document.getElementById('save');

chrome.storage.local.get({ ROOM_ID: '' }, (data) => {
  roomInput.value = data.ROOM_ID || '';
  updateState();
});

saveBtn.addEventListener('click', () => {
  const roomId = roomInput.value.trim();
  chrome.storage.local.set({ ROOM_ID: roomId }, () => {
    updateState(true);
  });
});

function updateState(saved = false) {
  if (roomInput.value.trim()) {
    stateEl.textContent = saved ? '🟢 Transmitiendo datos...' : '🟡 Configurado. Listo.';
  } else {
    stateEl.textContent = '⚪ Sin Room ID';
  }
}
