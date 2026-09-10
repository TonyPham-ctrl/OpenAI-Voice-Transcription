const connectionStatus = document.getElementById('connectionStatus');
const voiceFile = document.getElementById('voiceFile');

const requestStatsBtn = document.getElementById('statsButton');
const requestUptimeBtn = document.getElementById('uptimeButton');
const requestShutdown = document.getElementById('shutdownButton');
const clearResponseBtn = document.getElementById('clearOutputButton');
const uploadVoiceBtn = document.getElementById('uploadButton');

const serverResponseForm = document.getElementById('serverOutput');




requestStatsBtn.addEventListener('click', async () => {
    serverResponseForm.textContent = 'Fetching stats...';
    const res = await fetch('/api/v1/global/stats', {
        method: 'GET'
    });

    const data = await res.json();
    serverResponseForm.textContent = `Stats: ${JSON.stringify(data)}`;
});


requestUptimeBtn.addEventListener('click', async () => {
    serverResponseForm.textContent = 'Fetching uptime...';
    const res = await fetch('/api/v1/admin/uptime', {
        method: 'GET'
    });

    const data = await res.json();
    serverResponseForm.textContent = `Uptime: ${data.serverUptimeSeconds}`;
});

requestShutdown.addEventListener('click', async () => {
    serverResponseForm.textContent = 'Sending shutdown request...';
    const res = await fetch('/api/v1/admin/shutdown', {
        method: 'POST'
    });

    const data = await res.json();
    serverResponseForm.textContent = `Shutdown request sent: ${data.message}`;
});

clearResponseBtn.addEventListener('click', async () => {
    serverResponseForm.textContent = '';
});

uploadVoiceBtn.addEventListener('click', async () => {
    serverResponseForm.textContent = 'Uploading voice file...';
    const formData = new FormData();
    formData.append('client_voice_input', voiceFile.files[0]);

    const res = await fetch('/api/v1/transcribe', {
        method: 'POST',
        body: formData
    });
    const data = await res.json();
    serverResponseForm.textContent = `Transcription: ${data.transcription}`;
});

async function checkServer() {
  const pill = document.getElementById('connectionStatus');

  try {
    const res = await fetch('/api/v1/admin/running');
    const isRunning = res.ok ? await res.json() : false;

    pill.textContent = isRunning ? 'Online' : 'Offline';
    pill.classList.toggle('online', isRunning);
  } catch (error) {
    pill.textContent = 'Offline';
    pill.classList.remove('online');
  }
}

setInterval(checkServer, 3000);
checkServer();