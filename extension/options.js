/**
 * TeroVPN Chrome Extension - Options & Diagnostics Controller
 * Version: 1.2.0
 */

const $ = (id) => document.getElementById(id);

document.addEventListener('DOMContentLoaded', async () => {
  await loadOptions();
  initListeners();
});

function sendMsg(payload) {
  return new Promise((resolve) => {
    chrome.runtime.sendMessage(payload, (res) => resolve(res || {}));
  });
}

async function loadOptions() {
  const state = await chrome.storage.local.get(null);
  document.documentElement.setAttribute('data-theme', state.theme || 'dark');
  $('opt-routing-mode').value = state.routingMode || 'core';
  $('opt-core-api-port').value = state.coreApiPort || 10820;
  $('opt-core-proxy-port').value = state.coreProxyPort || 10810;
  $('opt-core-token').value = state.coreToken || '';
  $('opt-custom-host').value = state.customProxyHost || '';
  $('opt-custom-port').value = state.customProxyPort || 8080;
  $('opt-custom-scheme').value = state.customProxyScheme || 'https';
  $('opt-transport').value = state.transport || 'auto';
  $('opt-dns-preset').value = state.dnsPreset || 'system';
  $('opt-webrtc-shield').checked = state.webrtcShield !== false;
  $('opt-bypass-local').checked = state.bypassLocal !== false;
  $('opt-auto-connect').checked = Boolean(state.autoConnect);
  $('opt-bypass-domains').value = (state.splitBypassDomains || []).join(', ');
  toggleModeFields($('opt-routing-mode').value);
}

function toggleModeFields(mode) {
  const isCustom = mode === 'custom';
  $('opt-core-fields').classList.toggle('hidden', isCustom);
  $('opt-custom-fields').classList.toggle('hidden', !isCustom);
}

function showToast(msg) {
  const toast = $('toast');
  toast.textContent = msg;
  toast.classList.remove('hidden');
  setTimeout(() => toast.classList.add('hidden'), 2400);
}

function initListeners() {
  $('opt-routing-mode').addEventListener('change', (e) => {
    toggleModeFields(e.target.value);
  });

  $('opt-token-file').addEventListener('change', (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      const token = String(reader.result || '').trim();
      if (token) {
        $('opt-core-token').value = token;
        showToast('Token imported from file');
      }
    };
    reader.readAsText(file);
  });

  $('btn-save-options').addEventListener('click', async () => {
    const rawDomains = $('opt-bypass-domains').value
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);

    const updated = {
      routingMode: $('opt-routing-mode').value,
      coreApiPort: Number($('opt-core-api-port').value) || 10820,
      coreProxyPort: Number($('opt-core-proxy-port').value) || 10810,
      coreToken: $('opt-core-token').value.trim(),
      customProxyHost: $('opt-custom-host').value.trim(),
      customProxyPort: Number($('opt-custom-port').value) || 8080,
      customProxyScheme: $('opt-custom-scheme').value,
      transport: $('opt-transport').value,
      dnsPreset: $('opt-dns-preset').value,
      webrtcShield: $('opt-webrtc-shield').checked,
      bypassLocal: $('opt-bypass-local').checked,
      autoConnect: $('opt-auto-connect').checked,
      splitBypassDomains: rawDomains
    };

    await sendMsg({ action: 'UPDATE_SETTINGS', settings: updated });
    showToast('Preferences saved successfully!');
  });

  $('btn-reset-defaults').addEventListener('click', () => {
    $('opt-routing-mode').value = 'core';
    $('opt-core-api-port').value = 10820;
    $('opt-core-proxy-port').value = 10810;
    $('opt-custom-host').value = '';
    $('opt-custom-port').value = 8080;
    $('opt-custom-scheme').value = 'https';
    $('opt-transport').value = 'auto';
    $('opt-dns-preset').value = 'system';
    $('opt-webrtc-shield').checked = true;
    $('opt-bypass-local').checked = true;
    $('opt-auto-connect').checked = false;
    $('opt-bypass-domains').value = '';
    toggleModeFields('core');
    showToast('Reset to defaults. Click Save Preferences to apply.');
  });

  $('btn-test-core').addEventListener('click', async () => {
    const out = $('diag-output');
    out.textContent = 'Probing TeroVPN Core on 127.0.0.1...';
    const port = Number($('opt-core-api-port').value) || 10820;
    const token = $('opt-core-token').value.trim();

    const res = await sendMsg({ action: 'TEST_CORE', port, token });
    if (res.state === 'online') {
      const s = res.status || {};
      out.textContent =
        `[SUCCESS] TeroVPN Core is ONLINE & AUTHORIZED\n` +
        `Phase: ${s.state?.phase || 'unknown'}\n` +
        `Proxy Listen: ${s.proxy?.listen || '127.0.0.1:10810'}\n` +
        `Country: ${s.proxy?.country_name || s.proxy?.country_code || 'auto'}\n` +
        `Transport: ${s.proxy?.transport || 'smart'}`;
    } else if (res.state === 'unauthorized') {
      out.textContent =
        `[UNAUTHORIZED] Core responded on port ${port}, but X-Local-Token was rejected.\n` +
        `Import your local-api.token file above and click Save Preferences.`;
    } else {
      out.textContent =
        `[OFFLINE] Could not reach TeroVPN Core on 127.0.0.1:${port}.\n` +
        `Please make sure TeroVPN Desktop is running.`;
    }
  });

  $('btn-test-ip').addEventListener('click', async () => {
    const out = $('diag-output');
    out.textContent = 'Checking browser egress IP...';
    const start = Date.now();
    const res = await sendMsg({ action: 'REFRESH_IP' });
    const ms = Date.now() - start;
    if (res && res.ip) {
      out.textContent =
        `[SUCCESS] Public Egress IP: ${res.ip}\n` +
        `Location: ${res.city ? res.city + ', ' : ''}${res.country || 'Unknown'}\n` +
        `ISP / Network: ${res.isp || 'Unknown'}\n` +
        `Latency: ${ms} ms`;
    } else {
      out.textContent = '[ERROR] Unable to resolve public IP.';
    }
  });
}
