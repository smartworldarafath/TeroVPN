/**
 * TeroVPN Chrome Extension - Popup Controller
 * Full-featured UI matching TeroVPN Mobile & Desktop apps.
 * Version: 1.2.0
 */

import { DEFAULT_LOCATIONS, PROFILES, getFlagUrl, getLocationByCode } from './servers.js';
import { renderQrSvg } from './qrcode.js';

const $ = (id) => document.getElementById(id);

let currentState = null;
let uptimeTimer = null;
let qrPollTimer = null;
let qrCountdownTimer = null;
let activeQrSession = null;
let activeSignInId = null;
let emailLinkPollTimer = null;
let userSelectedAuthTab = false;

document.addEventListener('DOMContentLoaded', async () => {
  initNavigation();
  initHomeListeners();
  initCountriesListeners();
  initAccountsListeners();
  initSettingsListeners();
  renderProfiles();
  await refreshState();
});

function sendMsg(payload) {
  return new Promise((resolve) => {
    chrome.runtime.sendMessage(payload, (res) => {
      resolve(res || { success: false, error: 'No response from background worker' });
    });
  });
}

function showToast(msg, isError = false) {
  const toast = $('toast');
  toast.textContent = msg;
  toast.className = isError ? 'toast error' : 'toast';
  setTimeout(() => toast.classList.add('hidden'), 2600);
}

function formatUptime(ms) {
  if (!ms || ms <= 0) return '00:00:00';
  const totalSec = Math.floor(ms / 1000);
  const h = Math.floor(totalSec / 3600);
  const m = Math.floor((totalSec % 3600) / 60);
  const s = totalSec % 60;
  return [h, m, s].map((v) => String(v).padStart(2, '0')).join(':');
}

function formatBytes(bytes) {
  if (!bytes || bytes <= 0) return '0 GB';
  const gb = bytes / (1024 * 1024 * 1024);
  if (gb >= 1) return `${gb.toFixed(1)} GB`;
  const mb = bytes / (1024 * 1024);
  return `${mb.toFixed(0)} MB`;
}

// ---------------- Tab Navigation ----------------
function switchTab(tabId) {
  document.querySelectorAll('.tab-panel').forEach((p) => p.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach((b) => b.classList.remove('active'));
  $(tabId)?.classList.add('active');
  document.querySelector(`.nav-item[data-tab="${tabId}"]`)?.classList.add('active');

  if (tabId !== 'tab-accounts') {
    stopQrTimers();
  }
}

function initNavigation() {
  document.querySelectorAll('.nav-item').forEach((btn) => {
    btn.addEventListener('click', () => {
      switchTab(btn.dataset.tab);
    });
  });

  $('btn-theme-toggle').addEventListener('click', async () => {
    const html = document.documentElement;
    const next = html.getAttribute('data-theme') === 'light' ? 'dark' : 'light';
    html.setAttribute('data-theme', next);
    await sendMsg({ action: 'UPDATE_SETTINGS', settings: { theme: next } });
  });
}

// ---------------- State Refresh & Rendering ----------------
async function refreshState() {
  const state = await sendMsg({ action: 'GET_STATE' });
  if (!state) return;
  currentState = state;
  renderAll(state);
}

function renderAll(state) {
  // Theme
  document.documentElement.setAttribute('data-theme', state.theme || 'dark');

  // Core Pill
  const corePill = $('core-pill');
  corePill.className = `core-pill ${state.coreState || 'offline'}`;
  if (state.coreState === 'online') corePill.textContent = 'CORE: ONLINE';
  else if (state.coreState === 'unauthorized') corePill.textContent = 'CORE: PAIR TOKEN';
  else corePill.textContent = 'CORE: OFFLINE';

  // Alert Banner
  const banner = $('alert-banner');
  const bannerText = $('alert-banner-text');
  const bannerBtn = $('alert-banner-btn');
  const accounts = state.accounts || [];

  if (state.routingMode !== 'custom' && state.coreState === 'unauthorized') {
    banner.classList.remove('hidden');
    bannerText.textContent = 'Core found! Import local-api.token to control it.';
    bannerBtn.textContent = 'Pair';
    bannerBtn.onclick = () => switchTab('tab-settings');
  } else if (accounts.length === 0 && state.routingMode !== 'custom') {
    banner.classList.remove('hidden');
    bannerText.textContent = 'Sign in with Mozilla or QR Code to connect.';
    bannerBtn.textContent = 'Sign In';
    bannerBtn.onclick = () => {
      switchTab('tab-accounts');
      $('signin-panel').classList.remove('hidden');
    };
  } else {
    banner.classList.add('hidden');
  }

  // Power Hero
  const glow = $('glow-ring');
  const btn = $('btn-toggle-vpn');
  const statusEl = $('status-text');
  glow.className = 'glow-ring';
  btn.className = 'power-btn';
  statusEl.className = 'status-text';

  if (state.isConnecting) {
    glow.classList.add('connecting');
    btn.classList.add('connecting');
    statusEl.classList.add('connecting');
    statusEl.textContent = 'CONNECTING...';
    stopUptimeTimer();
  } else if (state.isConnected) {
    glow.classList.add('connected');
    btn.classList.add('connected');
    statusEl.classList.add('connected');
    statusEl.textContent = 'CONNECTED';
    startUptimeTimer(state.connectedAt);
  } else {
    statusEl.classList.add('disconnected');
    statusEl.textContent = 'DISCONNECTED';
    stopUptimeTimer();
    $('uptime-counter').textContent = '00:00:00';
  }

  // IP & Shield
  const ipDisplay = $('ip-display');
  const ipVal = $('ip-value');
  if (state.lastEgressIp) {
    const loc = state.lastEgressCountry ? ` (${state.lastEgressCountry})` : '';
    ipVal.textContent = `${state.lastEgressIp}${loc}`;
    ipDisplay.classList.toggle('connected', Boolean(state.isConnected));
  } else {
    ipVal.textContent = 'Tap to check IP';
    ipDisplay.classList.remove('connected');
  }

  const shieldOn = state.webrtcShield !== false;
  $('shield-indicator').style.display = shieldOn ? 'flex' : 'none';
  $('telemetry-shield').textContent = shieldOn ? 'WebRTC ON' : 'WebRTC OFF';

  // Active Country Card
  const locs = state.locations && state.locations.length ? state.locations : DEFAULT_LOCATIONS;
  const activeLoc = getLocationByCode(state.activeCountryCode, locs);
  $('active-flag').src = getFlagUrl(activeLoc.code);
  $('active-country').textContent = activeLoc.name;
  $('active-city').textContent = activeLoc.city || activeLoc.code.toUpperCase();
  $('active-ping').textContent = activeLoc.ping_ms > 0 ? `${activeLoc.ping_ms} ms` : 'Auto';

  // Active Account Mini Card
  const activeAcc = accounts.find((a) => a.active) || accounts[0];
  if (activeAcc) {
    $('mini-account-avatar').textContent = (activeAcc.email || 'U')[0].toUpperCase();
    $('mini-account-email').textContent = activeAcc.email;
    const rem = activeAcc.usage
      ? activeAcc.usage.unlimited
        ? 'Unlimited Quota'
        : `${formatBytes(activeAcc.usage.remaining_bytes)} remaining`
      : activeAcc.status || 'Ready';
    $('mini-account-quota').textContent = rem;
  } else {
    $('mini-account-avatar').textContent = '?';
    $('mini-account-email').textContent = 'Not signed in';
    $('mini-account-quota').textContent = 'Tap to sign in with Mozilla or QR';
  }

  // Telemetry Grid
  const transportMap = { auto: 'SMART', h3: 'MASQUE H3', h2: 'HTTP/2' };
  $('telemetry-protocol').textContent = transportMap[state.transport] || 'SMART';
  $('telemetry-exit').textContent = state.lastEgressCity || activeLoc.city || activeLoc.code.toUpperCase();

  // Render lists & forms
  renderCountries(locs, state.activeCountryCode, $('country-search-input').value);
  renderAccounts(accounts, state.coreState);
  populateSettingsForm(state);
}

function startUptimeTimer(connectedAt) {
  stopUptimeTimer();
  if (!connectedAt) {
    $('uptime-counter').textContent = '00:00:00';
    return;
  }
  const tick = () => {
    $('uptime-counter').textContent = formatUptime(Date.now() - connectedAt);
  };
  tick();
  uptimeTimer = setInterval(tick, 1000);
}

function stopUptimeTimer() {
  if (uptimeTimer) {
    clearInterval(uptimeTimer);
    uptimeTimer = null;
  }
}

// ---------------- Home Listeners ----------------
function initHomeListeners() {
  $('btn-toggle-vpn').addEventListener('click', async () => {
    if (!currentState) return;
    if (currentState.isConnected) {
      await sendMsg({ action: 'DISCONNECT' });
      showToast('Disconnected');
      await refreshState();
    } else {
      $('status-text').textContent = 'CONNECTING...';
      $('status-text').className = 'status-text connecting';
      $('glow-ring').className = 'glow-ring connecting';
      const res = await sendMsg({ action: 'CONNECT' });
      if (!res.success) {
        showToast(res.error || 'Connection failed', true);
      } else {
        showToast('Connected securely!');
      }
      await refreshState();
    }
  });

  $('btn-quick-country').addEventListener('click', () => switchTab('tab-countries'));
  $('btn-quick-account').addEventListener('click', () => switchTab('tab-accounts'));

  $('ip-display').addEventListener('click', async () => {
    $('ip-value').textContent = 'Checking IP...';
    const res = await sendMsg({ action: 'REFRESH_IP' });
    if (res && res.ip) {
      const loc = res.country ? ` (${res.country})` : '';
      $('ip-value').textContent = `${res.ip}${loc}`;
    } else {
      $('ip-value').textContent = 'IP check failed';
    }
  });

  $('btn-test-conn').addEventListener('click', async () => {
    $('btn-test-conn').textContent = '...';
    const res = await sendMsg({ action: 'TEST_CONNECTION' });
    $('btn-test-conn').textContent = 'Test';
    if (res.success) {
      showToast('Connection test passed!');
      await refreshState();
    } else {
      showToast(res.error || 'Connection test failed', true);
    }
  });
}

// ---------------- Countries Tab ----------------
function renderCountries(locations, activeCode, filter = '') {
  const container = $('country-list-container');
  container.innerHTML = '';
  const q = (filter || '').trim().toLowerCase();
  const filtered = locations.filter(
    (l) =>
      (l.name || '').toLowerCase().includes(q) ||
      (l.city || '').toLowerCase().includes(q) ||
      (l.code || '').toLowerCase().includes(q)
  );

  if (filtered.length === 0) {
    container.innerHTML = '<div style="text-align:center; padding:24px; color:var(--text-muted); font-size:12px;">No matching countries</div>';
    return;
  }

  filtered.forEach((loc) => {
    const code = (loc.code || '').toLowerCase();
    const el = document.createElement('div');
    el.className = `list-item ${code === (activeCode || '').toLowerCase() ? 'active' : ''}`;
    el.innerHTML = `
      <img src="${getFlagUrl(code)}" alt="${loc.name}" class="item-flag">
      <div class="item-info">
        <div class="item-title">${loc.name} ${loc.recommended ? '★' : ''}</div>
        <div class="item-sub">${loc.city || code.toUpperCase()}</div>
      </div>
      <div class="item-ping">${loc.ping_ms > 0 ? `${loc.ping_ms} ms` : 'Select'}</div>
    `;
    el.addEventListener('click', async () => {
      const res = await sendMsg({ action: 'SELECT_LOCATION', countryCode: code });
      if (res.success) {
        showToast(`Location set to ${loc.name}`);
        await refreshState();
        switchTab('tab-home');
      } else {
        showToast(res.error || 'Failed to set location', true);
      }
    });
    container.appendChild(el);
  });
}

function initCountriesListeners() {
  $('country-search-input').addEventListener('input', (e) => {
    const locs = currentState?.locations || DEFAULT_LOCATIONS;
    renderCountries(locs, currentState?.activeCountryCode, e.target.value);
  });

  $('btn-ping-all').addEventListener('click', async () => {
    $('btn-ping-all').textContent = 'Pinging...';
    const res = await sendMsg({ action: 'PING_LOCATIONS' });
    $('btn-ping-all').textContent = 'Ping All';
    if (res.success) {
      showToast('Latencies updated');
      await refreshState();
    } else {
      showToast(res.error || 'Ping requires Core online', true);
    }
  });
}

// ---------------- Profiles Tab ----------------
function renderProfiles() {
  const container = $('profiles-list-container');
  container.innerHTML = '';
  PROFILES.forEach((p) => {
    const el = document.createElement('div');
    el.className = 'list-item';
    el.innerHTML = `
      <div class="account-avatar" style="background:${p.color}; width:32px; height:32px;">${p.name[0]}</div>
      <div class="item-info">
        <div class="item-title">${p.name}</div>
        <div class="item-sub">${p.subtitle}</div>
      </div>
      <span class="mini-pill-btn">Connect</span>
    `;
    el.addEventListener('click', async () => {
      showToast(`Applying ${p.name} profile...`);
      const res = await sendMsg({ action: 'APPLY_PROFILE', profileId: p.id });
      if (res.success) {
        showToast(`${p.name} connected!`);
        switchTab('tab-home');
      } else {
        showToast(res.error || 'Failed to apply profile', true);
      }
      await refreshState();
    });
    container.appendChild(el);
  });
}

// ---------------- Accounts & Sign-In Tab ----------------
function renderAccounts(accounts) {
  const offlineBanner = $('signin-core-offline-banner');
  if (offlineBanner) {
    offlineBanner.classList.add('hidden');
  }
  const credFields = $('signin-credentials-fields');
  if (credFields) {
    credFields.classList.remove('hidden');
  }
  const container = $('accounts-list-container');
  container.innerHTML = '';

  if (!accounts || accounts.length === 0) {
    $('signin-panel').classList.remove('hidden');
    container.innerHTML = '<div style="text-align:center; padding:14px; color:var(--text-muted); font-size:11.5px;">No accounts signed in yet. Sign in with Mozilla Email & Password or scan the QR Code with your phone.</div>';
    return;
  }

  accounts.forEach((acc) => {
    const usedPct = Math.min(100, Math.max(0, Math.round(acc.used_percent || 0)));
    const quotaText = acc.usage
      ? acc.usage.unlimited
        ? 'Unlimited'
        : `${formatBytes(acc.usage.remaining_bytes)} left of ${formatBytes(acc.usage.limit_bytes)}`
      : acc.status || 'Ready';

    const card = document.createElement('div');
    card.className = `account-card ${acc.active ? 'active' : ''}`;
    card.innerHTML = `
      <div class="account-top">
        <span class="account-email">${acc.email}</span>
        <span class="account-badge">${acc.active ? 'ACTIVE' : (acc.status || 'READY').toUpperCase()}</span>
      </div>
      <div style="font-size:10.5px; color:var(--text-secondary);">${quotaText}</div>
      <div class="quota-bar-bg"><div class="quota-bar-fill" style="width:${100 - usedPct}%"></div></div>
      <div class="account-actions">
        ${acc.active ? '' : '<button class="secondary-btn flex-1 btn-acc-activate">Activate</button>'}
        <button class="secondary-btn flex-1 btn-acc-refresh">Refresh</button>
        <button class="secondary-btn flex-1 btn-acc-remove" style="color:var(--accent-red);">Sign Out</button>
      </div>
    `;

    card.querySelector('.btn-acc-activate')?.addEventListener('click', async () => {
      const res = await sendMsg({ action: 'ACCOUNT_ACTIVATE', id: acc.id });
      showToast(res.success ? `Switched to ${acc.email}` : (res.error || 'Failed to switch account'), !res.success);
      await refreshState();
    });

    card.querySelector('.btn-acc-refresh')?.addEventListener('click', async () => {
      const res = await sendMsg({ action: 'ACCOUNT_REFRESH', id: acc.id });
      showToast(res.success ? 'Quota refreshed' : (res.error || 'Failed to refresh quota'), !res.success);
      await refreshState();
    });

    card.querySelector('.btn-acc-remove')?.addEventListener('click', async () => {
      const res = await sendMsg({ action: 'ACCOUNT_REMOVE', id: acc.id });
      showToast(res.success ? 'Account removed' : (res.error || 'Failed to remove account'), !res.success);
      await refreshState();
    });

    container.appendChild(card);
  });
}

function initAccountsListeners() {
  $('btn-toggle-signin-panel').addEventListener('click', () => {
    $('signin-panel').classList.toggle('hidden');
  });

  $('seg-btn-password').addEventListener('click', () => {
    userSelectedAuthTab = true;
    $('seg-btn-password').classList.add('active');
    $('seg-btn-qr').classList.remove('active');
    $('signin-password-view').classList.remove('hidden');
    $('signin-qr-view').classList.add('hidden');
    stopQrTimers();
  });

  $('seg-btn-qr').addEventListener('click', () => {
    userSelectedAuthTab = true;
    $('seg-btn-qr').classList.add('active');
    $('seg-btn-password').classList.remove('active');
    $('signin-qr-view').classList.remove('hidden');
    $('signin-password-view').classList.add('hidden');
    startQrFlow();
  });

  $('btn-toggle-pw').addEventListener('click', () => {
    const pw = $('signin-password');
    pw.type = pw.type === 'password' ? 'text' : 'password';
  });

  $('btn-signin-submit').addEventListener('click', submitSignIn);
  $('btn-verify-submit').addEventListener('click', submitVerification);
  $('btn-email-link-confirmed').addEventListener('click', () => submitVerification('continue'));
  $('btn-verify-cancel').addEventListener('click', cancelSignInFlow);
  $('btn-qr-refresh').addEventListener('click', startQrFlow);

  $('btn-switch-to-qr')?.addEventListener('click', () => {
    $('seg-btn-qr').click();
  });

  $('btn-download-desktop')?.addEventListener('click', () => {
    chrome.tabs.create({ url: 'https://github.com/smartworldarafath/TeroVPN/releases/tag/v1.3.0' });
  });

  $('btn-retry-core-signin')?.addEventListener('click', async () => {
    const state = await refreshState();
    if (state?.coreState === 'online') {
      showToast('TeroVPN Core connected!');
    } else if (state?.coreState === 'unauthorized') {
      showToast('Core found, but token needed in Settings.', true);
    } else {
      showToast('Core still offline. Start TeroVPN Desktop first.', true);
    }
  });
}

async function submitSignIn() {
  const email = $('signin-email').value.trim();
  const password = $('signin-password').value;
  $('signin-error').classList.add('hidden');
  $('signin-success').classList.add('hidden');

  if (!email || !email.includes('@')) {
    $('signin-error').textContent = 'Enter a valid Mozilla email address.';
    $('signin-error').classList.remove('hidden');
    return;
  }
  if (!password) {
    $('signin-error').textContent = 'Enter your password.';
    $('signin-error').classList.remove('hidden');
    return;
  }

  $('btn-signin-submit').textContent = 'Signing in...';
  $('btn-signin-submit').disabled = true;

  const res = await sendMsg({ action: 'SIGN_IN_START', email, password });
  $('btn-signin-submit').textContent = 'Sign In to Mozilla';
  $('btn-signin-submit').disabled = false;

  if (!res.success) {
    $('signin-error').textContent = res.error || 'Sign-in failed';
    $('signin-error').classList.remove('hidden');
    return;
  }
  handleSignInState(res.signInState);
}

function handleSignInState(state) {
  if (!state) return;
  activeSignInId = state.id;
  stopEmailLinkPolling();

  if (state.step === 'done') {
    $('signin-step-credentials').classList.remove('hidden');
    $('signin-step-verify').classList.add('hidden');
    $('signin-success').classList.remove('hidden');
    $('signin-email').value = '';
    $('signin-password').value = '';
    showToast('Signed in successfully!');
    refreshState();
    return;
  }

  if (state.step === 'error') {
    $('signin-error').textContent = state.error || 'Authentication error';
    $('signin-error').classList.remove('hidden');
    $('signin-step-credentials').classList.remove('hidden');
    $('signin-step-verify').classList.add('hidden');
    return;
  }

  // Verification steps
  $('signin-step-credentials').classList.add('hidden');
  $('signin-step-verify').classList.remove('hidden');
  $('verify-captcha-img').classList.add('hidden');
  $('verify-code-input').classList.remove('hidden');
  $('btn-verify-submit').classList.remove('hidden');
  $('btn-email-link-confirmed').classList.add('hidden');

  if (state.step === 'need_email_link') {
    $('verify-title').textContent = 'Confirm Sign In via Email';
    $('verify-desc').textContent = 'Click the confirmation link sent to your email, then tap below.';
    $('verify-code-input').classList.add('hidden');
    $('btn-verify-submit').classList.add('hidden');
    $('btn-email-link-confirmed').classList.remove('hidden');
    startEmailLinkPolling(state.id);
  } else if (state.step === 'need_totp') {
    $('verify-title').textContent = '2FA Authenticator Code';
    $('verify-desc').textContent = 'Enter the 6-digit code from your authenticator app.';
    $('verify-code-input').placeholder = '6-digit TOTP code';
    $('verify-code-input').setAttribute('inputmode', 'numeric');
  } else if (state.step === 'need_unblock_code') {
    $('verify-title').textContent = 'Mozilla Unblock Code';
    $('verify-desc').textContent = 'Enter the 8-character alphanumeric unblock code sent to your Gmail.';
    $('verify-code-input').placeholder = '8-character unblock code';
    $('verify-code-input').setAttribute('inputmode', 'text');
  } else if (state.step === 'need_captcha') {
    $('verify-title').textContent = 'Security Check (CAPTCHA)';
    $('verify-desc').textContent = 'Enter the characters shown in the image below.';
    $('verify-code-input').placeholder = 'Enter characters shown above';
    $('verify-code-input').setAttribute('inputmode', 'text');
    if (state.captcha_image) {
      $('verify-captcha-img').src = state.captcha_image;
      $('verify-captcha-img').classList.remove('hidden');
    }
  } else {
    $('verify-title').textContent = '6-Digit Gmail Verification Code';
    $('verify-desc').textContent = 'Mozilla sent a 6-digit security code to your Gmail. Enter that 6-digit code below.';
    $('verify-code-input').placeholder = 'Enter 6-digit code from Gmail';
    $('verify-code-input').setAttribute('inputmode', 'numeric');
    $('verify-captcha-img').classList.add('hidden');
  }
}

async function submitVerification(overrideVal = null) {
  if (!activeSignInId) return;
  const value = overrideVal !== null ? overrideVal : $('verify-code-input').value.trim();
  if (!value) return;

  const res = await sendMsg({ action: 'SIGN_IN_ANSWER', id: activeSignInId, value });
  if (!res.success) {
    $('signin-error').textContent = res.error || 'Verification failed';
    $('signin-error').classList.remove('hidden');
    return;
  }
  $('verify-code-input').value = '';
  handleSignInState(res.signInState);
}

function startEmailLinkPolling(id) {
  stopEmailLinkPolling();
  emailLinkPollTimer = setInterval(async () => {
    const res = await sendMsg({ action: 'SIGN_IN_POLL', id });
    if (res.success && res.signInState && res.signInState.step !== 'need_email_link') {
      stopEmailLinkPolling();
      handleSignInState(res.signInState);
    }
  }, 2500);
}

function stopEmailLinkPolling() {
  if (emailLinkPollTimer) {
    clearInterval(emailLinkPollTimer);
    emailLinkPollTimer = null;
  }
}

async function cancelSignInFlow() {
  stopEmailLinkPolling();
  if (activeSignInId) {
    await sendMsg({ action: 'SIGN_IN_CANCEL', id: activeSignInId });
    activeSignInId = null;
  }
  $('signin-step-verify').classList.add('hidden');
  $('signin-step-credentials').classList.remove('hidden');
}

// ---------------- QR Flow ----------------
async function startQrFlow() {
  stopQrTimers();
  $('qr-status-text').textContent = 'Generating encrypted session...';
  const res = await sendMsg({ action: 'QR_START_SESSION' });
  if (!res.success || !res.session) {
    $('qr-status-text').textContent = 'Failed to create QR session';
    return;
  }
  activeQrSession = res.session;
  $('qr-svg-container').innerHTML = renderQrSvg(activeQrSession.payload, 165);
  $('qr-status-text').textContent = 'Waiting for mobile scan...';

  let secondsLeft = 300;
  $('qr-countdown').textContent = '05:00';
  qrCountdownTimer = setInterval(() => {
    secondsLeft--;
    if (secondsLeft <= 0) {
      stopQrTimers();
      $('qr-status-text').textContent = 'QR expired. Tap Refresh.';
      return;
    }
    const m = String(Math.floor(secondsLeft / 60)).padStart(2, '0');
    const s = String(secondsLeft % 60).padStart(2, '0');
    $('qr-countdown').textContent = `${m}:${s}`;
  }, 1000);

  qrPollTimer = setInterval(async () => {
    if (!activeQrSession) return;
    const pollRes = await sendMsg({
      action: 'QR_POLL_SESSION',
      sessionId: activeQrSession.sessionId,
      secretKey: activeQrSession.secretKey
    });
    if (pollRes && pollRes.authorized) {
      stopQrTimers();
      $('qr-status-text').textContent = `Synced: ${pollRes.email}`;
      showToast(`Signed in via QR as ${pollRes.email}!`);
      if (pollRes.coreSignInState && pollRes.coreSignInState.step !== 'done') {
        $('seg-btn-password').click();
        handleSignInState(pollRes.coreSignInState);
      }
      await refreshState();
    }
  }, 800);
}

function stopQrTimers() {
  if (qrPollTimer) { clearInterval(qrPollTimer); qrPollTimer = null; }
  if (qrCountdownTimer) { clearInterval(qrCountdownTimer); qrCountdownTimer = null; }
  if (activeQrSession?.sessionId) {
    sendMsg({ action: 'QR_STOP_SESSION', sessionId: activeQrSession.sessionId }).catch(() => {});
  }
}

// ---------------- Settings Tab ----------------
function populateSettingsForm(state) {
  $('setting-routing-mode').value = state.routingMode || 'core';
  $('setting-core-api-port').value = state.coreApiPort || 10820;
  $('setting-core-proxy-port').value = state.coreProxyPort || 10810;
  $('setting-core-token').value = state.coreToken || '';
  $('setting-custom-host').value = state.customProxyHost || '';
  $('setting-custom-port').value = state.customProxyPort || 8080;
  $('setting-custom-scheme').value = state.customProxyScheme || 'https';
  $('setting-transport').value = state.transport || 'auto';
  $('setting-dns-preset').value = state.dnsPreset || 'system';
  $('setting-webrtc-shield').checked = state.webrtcShield !== false;
  $('setting-bypass-local').checked = state.bypassLocal !== false;
  $('setting-auto-connect').checked = Boolean(state.autoConnect);
  $('setting-bypass-domains').value = (state.splitBypassDomains || []).join(', ');

  const isCustom = $('setting-routing-mode').value === 'custom';
  $('core-config-fields').classList.toggle('hidden', isCustom);
  $('custom-proxy-fields').classList.toggle('hidden', !isCustom);
}

function initSettingsListeners() {
  $('btn-open-options-page').addEventListener('click', () => {
    chrome.runtime.openOptionsPage();
  });

  $('setting-routing-mode').addEventListener('change', (e) => {
    const isCustom = e.target.value === 'custom';
    $('core-config-fields').classList.toggle('hidden', isCustom);
    $('custom-proxy-fields').classList.toggle('hidden', !isCustom);
  });

  $('input-token-file').addEventListener('change', (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      const token = String(reader.result || '').trim();
      if (token) {
        $('setting-core-token').value = token;
        showToast('Token loaded from file!');
      }
    };
    reader.readAsText(file);
  });

  $('btn-test-core').addEventListener('click', async () => {
    const out = $('core-test-result');
    out.classList.remove('hidden');
    out.textContent = 'Testing connection to Core...';
    out.style.color = 'var(--text-secondary)';
    const res = await sendMsg({
      action: 'TEST_CORE',
      port: Number($('setting-core-api-port').value) || 10820,
      token: $('setting-core-token').value.trim()
    });
    if (res.state === 'online') {
      out.textContent = '✅ Core Online & Authorized!';
      out.style.color = 'var(--accent-emerald)';
    } else if (res.state === 'unauthorized') {
      out.textContent = '⚠ Core running, but token is invalid or missing.';
      out.style.color = 'var(--accent-amber)';
    } else {
      out.textContent = '❌ Core offline on 127.0.0.1:' + ($('setting-core-api-port').value || 10820);
      out.style.color = 'var(--accent-red)';
    }
  });

  $('btn-save-settings').addEventListener('click', async () => {
    const rawDomains = $('setting-bypass-domains').value
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);

    const updated = {
      routingMode: $('setting-routing-mode').value,
      coreApiPort: Number($('setting-core-api-port').value) || 10820,
      coreProxyPort: Number($('setting-core-proxy-port').value) || 10810,
      coreToken: $('setting-core-token').value.trim(),
      customProxyHost: $('setting-custom-host').value.trim(),
      customProxyPort: Number($('setting-custom-port').value) || 8080,
      customProxyScheme: $('setting-custom-scheme').value,
      transport: $('setting-transport').value,
      dnsPreset: $('setting-dns-preset').value,
      webrtcShield: $('setting-webrtc-shield').checked,
      bypassLocal: $('setting-bypass-local').checked,
      autoConnect: $('setting-auto-connect').checked,
      splitBypassDomains: rawDomains
    };

    await sendMsg({ action: 'UPDATE_SETTINGS', settings: updated });
    showToast('Settings saved!');
    await refreshState();
  });
}
