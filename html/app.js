console.log('[distortionz_assassin] app.js loaded');

const app = document.getElementById('app');
const activeContract = document.getElementById('activeContract');

const closeBtn = document.getElementById('closeBtn');
const acceptBtn = document.getElementById('acceptBtn');

const targetAlias = document.getElementById('targetAlias');
const targetZone = document.getElementById('targetZone');
const behavior = document.getElementById('behavior');
const policeRisk = document.getElementById('policeRisk');
const timeLimit = document.getElementById('timeLimit');
const searchRadius = document.getElementById('searchRadius');
const rewardAmount = document.getElementById('rewardAmount');
const rewardType = document.getElementById('rewardType');
const intelText = document.getElementById('intelText');
const errorText = document.getElementById('errorText');

const activeTimer = document.getElementById('activeTimer');
const activeAlias = document.getElementById('activeAlias');
const activeZone = document.getElementById('activeZone');
const activeBehavior = document.getElementById('activeBehavior');
const activeReward = document.getElementById('activeReward');

function formatMoney(value) {
    const number = Number(value) || 0;

    return '$' + number.toLocaleString('en-US', {
        maximumFractionDigits: 0
    });
}

function formatMinutes(seconds) {
    const sec = Number(seconds) || 0;
    const minutes = Math.floor(sec / 60);

    return `${minutes} Min`;
}

function formatTimer(seconds) {
    const sec = Math.max(0, Number(seconds) || 0);
    const minutes = Math.floor(sec / 60);
    const remaining = sec % 60;

    return `${String(minutes).padStart(2, '0')}:${String(remaining).padStart(2, '0')}`;
}

function titleCase(value) {
    if (!value) return 'Unknown';

    return String(value)
        .replace(/_/g, ' ')
        .replace(/\w\S*/g, function(word) {
            return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
        });
}

function getResourceName() {
    if (typeof GetParentResourceName === 'function') {
        return GetParentResourceName();
    }

    return 'distortionz_assassin';
}

function postNui(name, data = {}) {
    return fetch(`https://${getResourceName()}/${name}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8'
        },
        body: JSON.stringify(data)
    }).then(function(response) {
        return response.json();
    });
}

function setError(message) {
    if (!errorText) return;
    errorText.textContent = message || '';
}

function openUI(data) {
    console.log('[distortionz_assassin] openUI called', data);

    if (!app) {
        console.error('[distortionz_assassin] #app not found');
        return;
    }

    targetAlias.textContent = data.targetAlias || 'Unknown';
    targetZone.textContent = data.targetZone || 'Unknown Zone';
    behavior.textContent = titleCase(data.behavior);
    policeRisk.textContent = data.policeRisk || 'Unknown';
    timeLimit.textContent = formatMinutes(data.timeLimit);
    searchRadius.textContent = `${Number(data.searchRadius) || 0}m`;
    rewardAmount.textContent = formatMoney(data.rewardAmount);
    rewardType.textContent = data.rewardItemLabel || 'Dirty Money';
    intelText.textContent = data.intel || 'Encrypted intel unavailable.';

    acceptBtn.disabled = false;
    setError('');

    app.classList.remove('hidden');
    app.style.display = 'grid';
}

function closeUI() {
    if (!app) return;

    app.classList.add('hidden');
    app.style.display = 'none';

    setError('');
}

function openActive(data) {
    if (!activeContract) return;

    activeAlias.textContent = data.targetAlias || 'Unknown Target';
    activeZone.textContent = data.targetZone || 'Unknown Zone';
    activeBehavior.textContent = titleCase(data.behavior);
    activeReward.textContent = formatMoney(data.rewardAmount);
    activeTimer.textContent = formatTimer(data.remainingSeconds);

    activeContract.classList.remove('hidden');
    activeContract.style.display = 'block';
}

function updateActive(data) {
    if (!activeContract) return;

    activeAlias.textContent = data.targetAlias || 'Unknown Target';
    activeZone.textContent = data.targetZone || 'Unknown Zone';
    activeBehavior.textContent = titleCase(data.behavior);
    activeReward.textContent = formatMoney(data.rewardAmount);
    activeTimer.textContent = formatTimer(data.remainingSeconds);
}

function closeActive() {
    if (!activeContract) return;

    activeContract.classList.add('hidden');
    activeContract.style.display = 'none';
}

window.addEventListener('message', function(event) {
    const payload = event.data;

    console.log('[distortionz_assassin] NUI message received', payload);

    if (!payload || !payload.action) return;

    if (payload.action === 'open') {
        openUI(payload.data || {});
    }

    if (payload.action === 'close') {
        closeUI();
    }

    if (payload.action === 'activeOpen') {
        openActive(payload.data || {});
    }

    if (payload.action === 'activeUpdate') {
        updateActive(payload.data || {});
    }

    if (payload.action === 'activeClose') {
        closeActive();
    }
});

if (closeBtn) {
    closeBtn.addEventListener('click', function() {
        postNui('cancelContract').then(function() {
            closeUI();
        });
    });
}

if (acceptBtn) {
    acceptBtn.addEventListener('click', function() {
        acceptBtn.disabled = true;
        setError('');

        postNui('acceptContract').then(function(result) {
            if (!result || !result.success) {
                setError(result && result.message ? result.message : 'Unable to accept contract.');
                acceptBtn.disabled = false;
                return;
            }

            closeUI();
        }).catch(function(error) {
            console.error('[distortionz_assassin] acceptContract failed', error);
            setError('NUI callback failed.');
            acceptBtn.disabled = false;
        });
    });
}

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        postNui('cancelContract').then(function() {
            closeUI();
        });
    }
});