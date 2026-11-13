/**
 * TeroVPN Chrome Extension - Popup Controller
 * Version: 1.2.0
 */

import { SERVERS, getServerById, getFlagUrl } from './servers.js';

// DOM Elements
const btnToggleVpn = document.getElementById('btn-toggle-vpn');
const glowRing = document.getElementById('glow-ring');
const statusText = document.getElementById('status-text');
const uptimeCounter = document.getElementById('uptime-counter');
const ipDisplay = document.getElementById('ip-display');
const ipValue = document.getElementById('ip-value');
const shieldIndicator = document.getElementById('shield-indicator');
const modeBadge = document.getElementById('mode-badge');

const activeFlag = document.getElementById('active-flag');
const activeCountry = document.getElementById('active-country');
const activeCity = document.getElementById('active-city');
const activePing = document.getElementById('active-ping');

const telemetryProtocol = document.getElementById('telemetry-protocol');
const telemetryCore = document.getElementById('telemetry-core');

const btnOpenServers = document.getElementById('btn-open-servers');
const btnCloseServers = document.getElementById('btn-close-servers');
const serverModal = document.getElementById('server-modal');
const serverSearchInput = document.getElementById('server-search-input');
const serverListContainer = document.getElementById('server-list-container');

const btnOpenSettings = document.getElementById('btn-open-settings');
const btnCloseSettings = document.getElementById('btn-close-settings');
const settingsModal = document.getElementById('settings-modal');
const btnSaveSettings = document.getElementById('btn-save-settings');

const settingRoutingMode = document.getElementById('setting-routing-mode');
const customProxyFields = document.getElementById('custom-proxy-fields');
const settingCustomHost = document.getElementById('setting-custom-host');
const settingCustomPort = document.getElementById('setting-custom-port');
const settingCustomScheme = document.getElementById('setting-custom-scheme');
const settingWebrtcShield = document.getElementById('setting-webrtc-shield');
const settingBypassLocal = document.getElementById('setting-bypass-local');
const settingAutoConnect = document.getElementById('setting-auto-connect');
const settingCoreApiPort = document.getElementById('setting-core-api-port');
const settingCoreProxyPort = document.getElementById('setting-core-proxy-port');

const toast = document.getElementById('toast');

// State
let currentState = null;
let uptimeInterval = null;

// Initialize
document.addEventListener('DOMContentLoaded', async () => {
  await refreshState();
  initEventListeners();
  renderServerList();
});

// Format seconds into HH:MM:SS
function formatUptime(ms) {
  if (!ms || ms <= 0) return '00:00:00';
  const totalSeconds = Math.floor(ms / 1000);
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;
  return [hours, minutes, seconds]
    .map(v => v < 10 ? '0' + v : v)
    .join(':');
}

// Start uptime counter timer
function startUptimeTimer(connectedAt) {
  stopUptimeTimer();
  if (!connectedAt) {
    uptimeCounter.textContent = '00:00:00';
    return;
  }
  const update = () => {
    const elapsed = Date.now() - connectedAt;
    uptimeCounter.textContent = formatUptime(elapsed);
  };
  update();
  uptimeInterval = setInterval(update, 1000);
}

function stopUptimeTimer() {
  if (uptimeInterval) {
    clearInterval(uptimeInterval);
    uptimeInterval = null;
  }
}

// Refresh state from background worker
async function refreshState() {
  return new Promise((resolve) => {
    chrome.runtime.sendMessage({ action: 'GET_STATUS' }, (state) => {
      if (!state) {
        console.warn('Failed to retrieve state from background worker');
        resolve();
        return;
      }
      currentState = state;
      updateUI(state);
      resolve(state);
    });
  });
}

// Update UI elements based on current state
function updateUI(state) {
  const isConnected = state.isConnected;
  const isConnecting = state.isConnecting;
  const server = getServerById(state.activeServerId);

  // Active Server Card
  activeFlag.src = getFlagUrl(server.countryCode);
  activeCountry.textContent = server.countryName;
  activeCity.textContent = server.cityName;
  activePing.textContent = `${server.defaultPing} ms`;

  // Status & Power Button
  glowRing.className = 'glow-ring';
  btnToggleVpn.className = 'power-btn';
  statusText.className = 'status-text';

  if (isConnecting) {
    glowRing.classList.add('connecting');
    btnToggleVpn.classList.add('connecting');
    statusText.classList.add('connecting');
    statusText.textContent = 'CONNECTING...';
    stopUptimeTimer();
  } else if (isConnected) {
    glowRing.classList.add('connected');
    btnToggleVpn.classList.add('connected');
    statusText.classList.add('connected');
    statusText.textContent = 'CONNECTED';
    startUptimeTimer(state.connectedAt);
  } else {
    statusText.classList.add('disconnected');
    statusText.textContent = 'DISCONNECTED';
    stopUptimeTimer();
    uptimeCounter.textContent = '00:00:00';
  }

  // Routing Mode Badge
  const mode = state.routingMode || 'auto';
  modeBadge.textContent = mode.toUpperCase();

  // Telemetry Grid
  if (state.coreOnline) {
    telemetryCore.textContent = `Online (${state.coreProxyPort || 10810})`;
    telemetryCore.style.color = '#10B981';
  } else {
    telemetryCore.textContent = 'Relay Ready';
    telemetryCore.style.color = '#94A3B8';
  }

  if (isConnected) {
    telemetryProtocol.textContent = state.effectiveMode === 'core' ? 'MASQUE / HTTP3' : 'HTTPS / RELAY';
  } else {
    telemetryProtocol.textContent = 'STANDBY';
  }

  // IP Display & Shield
  if (state.lastEgressIp) {
    ipValue.textContent = state.lastEgressIp;
    ipDisplay.classList.add('connected');
  } else if (isConnected) {
    ipValue.textContent = 'Checking IP...';
  } else {
    ipValue.textContent = 'Protected on connect';
    ipDisplay.classList.remove('connected');
  }

  if (state.webrtcShield !== false) {
    shieldIndicator.classList.add('active');
    shieldIndicator.style.display = 'flex';
  } else {
    shieldIndicator.classList.remove('active');
    shieldIndicator.style.display = 'none';
  }
}

// Render the server drawer list
function renderServerList(filter = '') {
  serverListContainer.innerHTML = '';
  const q = filter.trim().toLowerCase();

  const filtered = SERVERS.filter(s => {
    return s.countryName.toLowerCase().includes(q) ||
           s.cityName.toLowerCase().includes(q) ||
           s.region.toLowerCase().includes(q);
  });

  if (filtered.length === 0) {
    serverListContainer.innerHTML = '<div style="text-align:center; padding:20px; color:#64748B; font-size:12px;">No matching locations found</div>';
    return;
  }

  filtered.forEach(s => {
    const item = document.createElement('div');
    item.className = 'server-list-item';
    if (currentState && currentState.activeServerId === s.id) {
      item.classList.add('active');
    }

    item.innerHTML = `
      <img src="${getFlagUrl(s.countryCode)}" alt="${s.countryName}" class="item-flag">
      <div class="item-info">
        <div class="item-country">${s.countryName}</div>
        <div class="item-city">${s.cityName} • ${s.region}</div>
      </div>
      <div class="item-ping">${s.defaultPing} ms</div>
    `;

    item.addEventListener('click', () => {
      selectServer(s.id);
    });

    serverListContainer.appendChild(item);
  });
}

// Select a server
function selectServer(serverId) {
  serverModal.classList.add('hidden');
  chrome.runtime.sendMessage({ action: 'SET_SERVER', serverId }, async () => {
    showToast('Server location updated');
    await refreshState();
  });
}

// Show Toast message
function showToast(msg) {
  toast.textContent = msg;
  toast.classList.remove('hidden');
  setTimeout(() => {
    toast.classList.add('hidden');
  }, 2200);
}

// Event Listeners
function initEventListeners() {
  // Power Toggle
  btnToggleVpn.addEventListener('click', async () => {
    if (!currentState) return;
    if (currentState.isConnected) {
      // Disconnect
      updateUI({ ...currentState, isConnected: false, isConnecting: false });
      chrome.runtime.sendMessage({ action: 'DISCONNECT' }, async () => {
        await refreshState();
      });
    } else {
      // Connect
      updateUI({ ...currentState, isConnecting: true });
      chrome.runtime.sendMessage({ action: 'CONNECT' }, async () => {
        await refreshState();
      });
    }
  });

  // Open & Close Server Drawer
  btnOpenServers.addEventListener('click', () => {
    serverModal.classList.remove('hidden');
    serverSearchInput.value = '';
    renderServerList();
    serverSearchInput.focus();
  });

  btnCloseServers.addEventListener('click', () => {
    serverModal.classList.add('hidden');
  });

  // Server Search filter
  serverSearchInput.addEventListener('input', (e) => {
    renderServerList(e.target.value);
  });

  // IP refresh on click
  ipDisplay.addEventListener('click', () => {
    ipValue.textContent = 'Refreshing...';
    chrome.runtime.sendMessage({ action: 'REFRESH_IP' }, (res) => {
      if (res && res.ip) {
        ipValue.textContent = res.ip;
      } else {
        ipValue.textContent = 'IP verified';
      }
    });
  });

  // Settings Drawer Open & Close
  btnOpenSettings.addEventListener('click', () => {
    if (!currentState) return;
    settingRoutingMode.value = currentState.routingMode || 'auto';
    settingCustomHost.value = currentState.customProxyHost || '';
    settingCustomPort.value = currentState.customProxyPort || 8080;
    settingCustomScheme.value = currentState.customProxyScheme || 'https';
    settingWebrtcShield.checked = currentState.webrtcShield !== false;
    settingBypassLocal.checked = currentState.bypassLocal !== false;
    settingAutoConnect.checked = !!currentState.autoConnect;
    settingCoreApiPort.value = currentState.coreApiPort || 10820;
    settingCoreProxyPort.value = currentState.coreProxyPort || 10810;

    toggleCustomFields(settingRoutingMode.value);
    settingsModal.classList.remove('hidden');
  });

  btnCloseSettings.addEventListener('click', () => {
    settingsModal.classList.add('hidden');
  });

  settingRoutingMode.addEventListener('change', (e) => {
    toggleCustomFields(e.target.value);
  });

  function toggleCustomFields(mode) {
    if (mode === 'custom') {
      customProxyFields.classList.remove('hidden');
    } else {
      customProxyFields.classList.add('hidden');
    }
  }

  // Save Settings
  btnSaveSettings.addEventListener('click', () => {
    const updated = {
      routingMode: settingRoutingMode.value,
      customProxyHost: settingCustomHost.value.trim(),
      customProxyPort: Number(settingCustomPort.value) || 8080,
      customProxyScheme: settingCustomScheme.value,
      webrtcShield: settingWebrtcShield.checked,
      bypassLocal: settingBypassLocal.checked,
      autoConnect: settingAutoConnect.checked,
      coreApiPort: Number(settingCoreApiPort.value) || 10820,
      coreProxyPort: Number(settingCoreProxyPort.value) || 10810
    };

    chrome.runtime.sendMessage({ action: 'UPDATE_SETTINGS', settings: updated }, async () => {
      settingsModal.classList.add('hidden');
      showToast('Settings saved successfully');
      await refreshState();
    });
  });
}
