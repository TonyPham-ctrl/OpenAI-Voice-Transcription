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

});


requestUptimeBtn.addEventListener('click', async () => {

    serverResponseForm.textContent = 'Fetching uptime...';

});

requestShutdown.addEventListener('click', async () => {

    serverResponseForm.textContent = 'Sending shutdown request...';

});

clearResponseBtn.addEventListener('click', async () => {
    
    serverResponseForm.textContent = '';
});

uploadVoiceBtn.addEventListener('click', async () => {
    serverResponseForm.textContent = 'Uploading voice file...';
});