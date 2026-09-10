const connectionStatus = document.getElementById('connectionStatus');
const recordButton = document.getElementById('recordButton');
const finishButton = document.getElementById('finishButton');
const uploadButton = document.getElementById('uploadButton');

const requestStatsBtn = document.getElementById('statsButton');
const requestUptimeBtn = document.getElementById('uptimeButton');
const requestShutdown = document.getElementById('shutdownButton');
const clearResponseBtn = document.getElementById('clearOutputButton');

const serverResponseForm = document.getElementById('serverOutput');
const recordingText = document.getElementById('recordingText');
const recordingCard = document.querySelector('.recording-card');

let mediaRecorder = null;
let mediaStream = null;
let recordedChunks = [];
let isRecording = false;
let recordedBlob = null;

function updateRecordingUi(recording) {
    isRecording = recording;
    recordingCard.classList.toggle('recording', recording);
    recordingText.textContent = recording ? 'Recording in progress...' : 'Ready to record';

    recordButton.disabled = recording;
    finishButton.disabled = !recording;
    uploadButton.disabled = !recordedBlob;

    recordButton.textContent = recording ? 'Recording...' : 'Start Recording';
    finishButton.textContent = recording ? 'Stop Recording' : 'Stop Recording';
}

function resetRecorderState() {
    if (mediaStream) {
        mediaStream.getTracks().forEach((track) => track.stop());
    }

    mediaStream = null;
    mediaRecorder = null;
    recordedChunks = [];
    recordedBlob = null;
    updateRecordingUi(false);
}

async function uploadRecordedVoice() {
    if (!recordedBlob || recordedBlob.size === 0) {
        serverResponseForm.textContent = 'No recorded audio available to upload.';


        return;
    }

    const formData = new FormData();
    const ext = recordedBlob.type.split(';')[0].split('/')[1] || 'webm';
    formData.append('file', recordedBlob, `recording.${ext}`);

    serverResponseForm.textContent = 'Uploading recorded voice...';

    try {
        const res = await fetch('/api/v1/transcribe', {
            method: 'POST',
            body: formData
        });
        if (!res.ok) {
            throw new Error(`Server responded with status ${res.status}`);
        } else{
            serverResponseForm.textContent = 'Upload successful. Awaiting transcription...';
        }
        const data = await res.json();
        serverResponseForm.textContent = `Transcription: ${data.transcribedText}`;
    } catch (error) {
        serverResponseForm.textContent = `Upload failed: ${error.message}`;
    }
}

recordButton.addEventListener('click', async () => {
    if (isRecording) {
        serverResponseForm.textContent = 'Recording is already in progress.';
        return;
    }

    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        serverResponseForm.textContent = 'This browser does not support microphone access.';
        return;
    }

    try {
        mediaStream = await navigator.mediaDevices.getUserMedia({ audio: true });
        recordedChunks = [];
        recordedBlob = null;

        mediaRecorder = new MediaRecorder(mediaStream);

        mediaRecorder.ondataavailable = (event) => {
            if (event.data.size > 0) {
                recordedChunks.push(event.data);
            }
        };

        mediaRecorder.onstop = () => {
            recordedBlob = new Blob(recordedChunks, {
                type: mediaRecorder.mimeType || 'audio/webm'
            });

            serverResponseForm.textContent = 'Recording stopped. Ready to upload.';
            
            updateRecordingUi(false);
            uploadButton.disabled = !recordedBlob || recordedBlob.size === 0;
        };

        mediaRecorder.start();
        updateRecordingUi(true);
        serverResponseForm.textContent = 'Recording started.';
    } catch (error) {
        serverResponseForm.textContent = `${error.message}`;
        resetRecorderState();
    }
});

finishButton.addEventListener('click', () => {
    if (!isRecording || !mediaRecorder) {
        serverResponseForm.textContent = 'You are not currently recording, so there is nothing to stop.';
        return;
    }

    mediaRecorder.stop();
    if (mediaStream) {
        mediaStream.getTracks().forEach((track) => track.stop());
    }
});

uploadButton.addEventListener('click', async () => {
    if (!recordedBlob || recordedBlob.size === 0) {
        serverResponseForm.textContent = 'Please record audio before attempting to upload.';
        return;
    }

    await uploadRecordedVoice();
});

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

updateRecordingUi(false);
setInterval(checkServer, 3000);
checkServer();