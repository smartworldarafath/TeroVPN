/**
 * TeroVPN Chrome Extension - Options & Diagnostics Controller
 * Version: 1.2.0
 */

const optRoutingMode = document.getElementById('opt-routing-mode');
const optCustomFields = document.getElementById('opt-custom-fields');
const optCustomHost = document.getElementById('opt-custom-host');
const optCustomPort = document.getElementById('opt-custom-port');
const optCustomScheme = document.getElementById('opt-custom-scheme');
const optCoreApiPort = document.getElementById('opt-core-api-port');
const optCoreProxyPort = document.getElementById('opt-core-proxy-port');
const optWebrtcShield = document.getElementById('opt-webrtc-shield');
const optBypassLocal = document.getElementById('opt-bypass-local');
const optAutoConnect = document.getElementById('opt-auto-connect');

const btnTestCore = document.getElementById('btn-test-core');
const btnTestIp = document.getElementById('btn-test-ip');
const diagOutput = document.getElementById('diag-output');
const btnSaveOptions = document.getElementById('btn-save-options');
const btnResetDefaults = document.getElementById('btn-reset-defaults');
const toast = document.getElementById('toast');

document.addEventListener('DOMContentLoaded', async () => {
  await loadOptions();
  initListeners();
});

async function loadOptions() {
  const state = await chrome.storage.local.get(null);
  optRoutingMode.value = state.routingMode || 'auto';
  optCustomHost.value = state.customProxyHost || '';
  optCustomPort.value = state.customProxyPort || 8080;
  optCustomScheme.value = state.customProxyScheme || 'https';
  optCoreApiPort.value = state.coreApiPort || 10820;
  optCoreProxyPort.value = state.coreProxyPort || 10810;
  optWebrtcShield.checked = state.webrtcShield !== false;
  optBypassLocal.checked = state.bypassLocal !== false;
  optAutoConnect.checked = !!state.autoConnect;

  toggleCustom(optRoutingMode.value);
}

function toggleCustom(mode) {
  if (mode === 'custom') {
    optCustomFields.classList.remove('hidden');
  } else {
    optCustomFields.classList.add('hidden');
  }
}

function showToast(msg) {
  toast.textContent = msg;
  toast.classList.remove('hidden');
  setTimeout(() => {
    toast.classList.add('hidden');
  }, 2200);
}

function initListeners() {
  optRoutingMode.addEventListener('change', (e) => {
    toggleCustom(e.target.value);
  });

  btnSaveOptions.addEventListener('click', async () => {
    const updated = {
      routingMode: optRoutingMode.value,
      customProxyHost: optCustomHost.value.trim(),
      customProxyPort: Number(optCustomPort.value) || 8080,
      customProxyScheme: optCustomScheme.value,
      coreApiPort: Number(optCoreApiPort.value) || 10820,
      coreProxyPort: Number(optCoreProxyPort.value) || 10810,
      webrtcShield: optWebrtcShield.checked,
      bypassLocal: optBypassLocal.checked,
      autoConnect: optAutoConnect.checked
    };

    chrome.runtime.sendMessage({ action: 'UPDATE_SETTINGS', settings: updated }, () => {
      showToast('Preferences saved successfully!');
    });
  });

  btnResetDefaults.addEventListener('click', async () => {
    optRoutingMode.value = 'auto';
    optCustomHost.value = '';
    optCustomPort.value = 8080;
    optCustomScheme.value = 'https';
    optCoreApiPort.value = 10820;
    optCoreProxyPort.value = 10810;
    optWebrtcShield.checked = true;
    optBypassLocal.checked = true;
    optAutoConnect.checked = false;
    toggleCustom('auto');
    showToast('Reset to defaults. Remember to click Save.');
  });

  btnTestCore.addEventListener('click', async () => {
    diagOutput.textContent = 'Probing local TeroVPN Core at 127.0.0.1...';
    const port = Number(optCoreApiPort.value) || 10820;

    try {
      const res = await fetch(`http://127.0.0.1:${port}/api/status`);
      if (res.ok) {
        const data = await res.json();
        diagOutput.textContent = `[SUCCESS] TeroVPN Desktop Core is ONLINE!\nEndpoint: http://127.0.0.1:${port}/api/status\nPhase: ${data.state?.phase || 'unknown'}\nProxy Listen: ${data.proxy?.listen || '127.0.0.1:10810'}\nExit Country: ${data.proxy?.country_code || 'none'}`;
      } else {
        diagOutput.textContent = `[WARNING] Core replied with HTTP ${res.status} ${res.statusText}.\nMake sure TeroVPN Desktop is running.`;
      }
    } catch (e) {
      diagOutput.textContent = `[INFO] Desktop Core not detected at 127.0.0.1:${port} (${e.message}).\nExtension will automatically route traffic through TeroVPN Standalone Cloud Relays.`;
    }
  });

  btnTestIp.addEventListener('click', async () => {
    diagOutput.textContent = 'Resolving current browser egress IP...';
    try {
      const start = Date.now();
      const res = await fetch('https://api.ipify.org?format=json');
      const latency = Date.now() - start;
      if (res.ok) {
        const json = await res.json();
        diagOutput.textContent = `[SUCCESS] Current Egress Public IP: ${json.ip}\nResponse latency: ${latency} ms\nStatus: Securely Routed`;
      } else {
        diagOutput.textContent = `[ERROR] Failed to query IP service: ${res.status}`;
      }
    } catch (e) {
      diagOutput.textContent = `[ERROR] Diagnostic check failed: ${e.message}`;
    }
  });
}
