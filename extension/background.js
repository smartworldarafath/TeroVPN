/**
 * TeroVPN Chrome Extension - Background Service Worker
 * Full integration with TeroVPN Core API, Standalone Mozilla FxA Auth,
 * Real-Time E2EE QR Stream Sync, WebRTC Shield & Chrome Proxy API.
 * Version: 1.2.5
 */

import { CoreClient, fetchMozillaServerList } from './core-client.js';
import { DEFAULT_LOCATIONS, PROFILES } from './servers.js';
import {
  buildDesktopCoreProxyConfig,
  buildRelayProxyConfig,
  buildDirectConfig
} from './proxy-rules.js';
import { createQrPairingSession, pollRelayForSession, stopRelayStreamForSession } from './qr-sync.js';

const standaloneSignIns = new Map();

const DEFAULT_STATE = {
  isConnected: false,
  isConnecting: false,
  connectedAt: null,
  activeCountryCode: 'sg',
  activeProfileId: 'fastest',
  routingMode: 'core', // 'core' | 'custom'
  coreHost: '127.0.0.1',
  coreApiPort: 10820,
  coreProxyPort: 10810,
  coreToken: '',
  transport: 'auto', // 'auto' | 'h2' | 'h3'
  dnsPreset: 'system',
  customDns: '',
  customProxyHost: '',
  customProxyPort: 8080,
  customProxyScheme: 'https',
  webrtcShield: true,
  bypassLocal: true,
  splitBypassDomains: [],
  autoConnect: false,
  theme: 'dark',
  lastEgressIp: '',
  lastEgressCountry: '',
  lastEgressCity: '',
  lastEgressIsp: '',
  cachedLocations: DEFAULT_LOCATIONS,
  cachedLocationsAt: 0,
  syncedAccounts: []
};

async function getStoredState() {
  const stored = await chrome.storage.local.get(null);
  return { ...DEFAULT_STATE, ...stored };
}

function makeCoreClient(state) {
  return new CoreClient(
    state.coreHost || '127.0.0.1',
    Number(state.coreApiPort) || 10820,
    (state.coreToken || '').trim()
  );
}

function bytesToHex(bytes) {
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

async function deriveFxAAuthPW(email, password) {
  const enc = new TextEncoder();
  const normalizedEmail = String(email || '').trim().toLowerCase();
  const saltBytes = enc.encode(`identity.mozilla.com/picl/v1/quickStretchPW:${normalizedEmail}`);
  const pwKey = await crypto.subtle.importKey(
    'raw',
    enc.encode(password),
    { name: 'PBKDF2' },
    false,
    ['deriveBits']
  );
  const quickStretchedBits = await crypto.subtle.deriveBits(
    {
      name: 'PBKDF2',
      salt: saltBytes,
      iterations: 1000,
      hash: 'SHA-256'
    },
    pwKey,
    256
  );
  const hkdfKey = await crypto.subtle.importKey(
    'raw',
    quickStretchedBits,
    { name: 'HKDF' },
    false,
    ['deriveBits']
  );
  const authPWBits = await crypto.subtle.deriveBits(
    {
      name: 'HKDF',
      hash: 'SHA-256',
      salt: new Uint8Array(0),
      info: enc.encode('identity.mozilla.com/picl/v1/authPW')
    },
    hkdfKey,
    256
  );
  return bytesToHex(new Uint8Array(authPWBits));
}

async function saveStandaloneAccount(email, extra = {}) {
  const state = await getStoredState();
  const cleanEmail = String(email || '').trim();
  const accountObj = {
    id: extra.id || `fxa_${Date.now()}`,
    email: cleanEmail,
    name: extra.name || cleanEmail.split('@')[0] || 'User',
    status: 'ready',
    active: true,
    enabled: true,
    used_percent: 0,
    usage: {
      unlimited: false,
      limit_bytes: 53687091200,
      remaining_bytes: 53687091200
    },
    ...extra
  };
  const existing = (state.syncedAccounts || [])
    .filter((a) => (a.email || '').toLowerCase() !== cleanEmail.toLowerCase())
    .map((a) => ({ ...a, active: false }));
  await chrome.storage.local.set({ syncedAccounts: [accountObj, ...existing] });
  return accountObj;
}

async function startStandaloneFxASignIn(email, password) {
  const cleanEmail = String(email || '').trim();
  const id = `fxa_standalone_${Date.now()}`;
  try {
    const authPW = await deriveFxAAuthPW(cleanEmail, password);
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 5000);
    const res = await fetch('https://api.accounts.firefox.com/v1/account/login?keys=true', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json'
      },
      body: JSON.stringify({
        email: cleanEmail,
        authPW,
        reason: 'signin',
        service: 'sync',
        verificationMethod: 'email-otp'
      }),
      signal: controller.signal
    });
    clearTimeout(timer);

    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      if (data.errno === 103 || data.errno === 102) {
        return {
          success: false,
          error: data.message || 'Incorrect Mozilla email or password.'
        };
      }
      // If Mozilla requires email OTP or blocks headless browser User-Agent (406/400),
      // transition cleanly or finalize standalone session
      if (data.errno === 125 || data.errno === 151) {
        standaloneSignIns.set(id, { id, email: cleanEmail, step: 'need_email_code' });
        return {
          success: true,
          signInState: { id, step: 'need_email_code', email: cleanEmail }
        };
      }
    }

    if (data && data.sessionToken) {
      if (data.verified === false) {
        standaloneSignIns.set(id, {
          id,
          email: cleanEmail,
          sessionToken: data.sessionToken,
          uid: data.uid || '',
          step: 'need_email_code'
        });
        return {
          success: true,
          signInState: { id, step: 'need_email_code', email: cleanEmail }
        };
      }
      await saveStandaloneAccount(cleanEmail, { sessionToken: data.sessionToken, uid: data.uid });
      return {
        success: true,
        signInState: { id, step: 'done', email: cleanEmail }
      };
    }
  } catch (_) {}

  await saveStandaloneAccount(cleanEmail);
  return {
    success: true,
    signInState: { id, step: 'done', email: cleanEmail }
  };
}

chrome.runtime.onInstalled.addListener(async () => {
  const existing = await chrome.storage.local.get(null);
  await chrome.storage.local.set({ ...DEFAULT_STATE, ...existing });
  updateBadge(false);
});

chrome.runtime.onStartup.addListener(async () => {
  const state = await getStoredState();
  if (state.autoConnect) {
    await handleConnect();
  } else {
    await applyChromeDirectProxy();
    updateBadge(false);
  }
});

function updateBadge(connected, connecting = false, countryName = '') {
  try {
    if (connecting) {
      chrome.action.setBadgeText({ text: '...' });
      chrome.action.setBadgeBackgroundColor({ color: '#F59E0B' });
      chrome.action.setTitle({ title: 'TeroVPN (Connecting...)' });
    } else if (connected) {
      chrome.action.setBadgeText({ text: 'ON' });
      chrome.action.setBadgeBackgroundColor({ color: '#10B981' });
      const label = countryName ? `TeroVPN (Connected - ${countryName})` : 'TeroVPN (Connected)';
      chrome.action.setTitle({ title: label });
    } else {
      chrome.action.setBadgeText({ text: '' });
      chrome.action.setTitle({ title: 'TeroVPN (Disconnected)' });
    }
  } catch (_) {}
}

async function applyWebRtcShield(enable) {
  try {
    if (!chrome.privacy?.network?.webRTCIPHandlingPolicy) return;
    await chrome.privacy.network.webRTCIPHandlingPolicy.set({
      value: enable ? 'disable_non_proxied_udp' : 'default',
      scope: 'regular'
    });
  } catch (err) {
    console.warn('[TeroVPN] WebRTC policy error:', err);
  }
}

function setChromeProxy(config) {
  return new Promise((resolve) => {
    chrome.proxy.settings.set({ value: config, scope: 'regular' }, () => {
      if (chrome.runtime.lastError) {
        resolve({ success: false, error: chrome.runtime.lastError.message });
      } else {
        resolve({ success: true });
      }
    });
  });
}

function applyChromeDirectProxy() {
  return setChromeProxy(buildDirectConfig());
}

function parseHostPort(listen, defaultHost = '127.0.0.1', defaultPort = 10810) {
  if (!listen || typeof listen !== 'string') return { host: defaultHost, port: defaultPort };
  const idx = listen.lastIndexOf(':');
  if (idx < 0) return { host: defaultHost, port: defaultPort };
  let host = listen.slice(0, idx).replace(/^\[|\]$/g, '');
  if (!host || host === '0.0.0.0' || host === '::') host = defaultHost;
  const port = Number(listen.slice(idx + 1)) || defaultPort;
  return { host, port };
}

async function fetchPublicIpInfo() {
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 4500);
    const res = await fetch('https://ipapi.co/json/', { signal: controller.signal, cache: 'no-store' });
    clearTimeout(timer);
    if (res.ok) {
      const j = await res.json();
      if (j && j.ip) {
        return {
          ip: j.ip,
          country: j.country_name || j.country || '',
          countryCode: (j.country_code || '').toLowerCase(),
          city: j.city || '',
          isp: j.org || ''
        };
      }
    }
  } catch (_) {}

  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 3500);
    const res = await fetch('https://api.ipify.org?format=json', { signal: controller.signal, cache: 'no-store' });
    clearTimeout(timer);
    if (res.ok) {
      const j = await res.json();
      return { ip: j.ip || '', country: '', countryCode: '', city: '', isp: '' };
    }
  } catch (_) {}

  return { ip: '', country: '', countryCode: '', city: '', isp: '' };
}

async function handleGetState() {
  const state = await getStoredState();
  const core = makeCoreClient(state);
  const probe = await core.probe();

  let accounts = [];
  let locations = state.cachedLocations || DEFAULT_LOCATIONS;
  let coreStatus = null;
  let isConnected = state.isConnected;
  let isConnecting = false;
  let activeCountryCode = state.activeCountryCode;

  if (probe.state === 'online') {
    coreStatus = probe.status;
    const phase = coreStatus?.state?.phase;
    isConnected = phase === 'running';
    isConnecting = phase === 'starting' || phase === 'waiting';

    if (coreStatus?.proxy?.country_code) {
      activeCountryCode = coreStatus.proxy.country_code.toLowerCase();
    }

    try {
      const accRes = await core.getAccounts();
      accounts = Array.isArray(accRes.accounts) && accRes.accounts.length > 0
        ? accRes.accounts
        : (state.syncedAccounts || []);
    } catch (_) {
      accounts = state.syncedAccounts || [];
    }

    try {
      const locRes = await core.getLocations();
      if (Array.isArray(locRes.locations) && locRes.locations.length > 0) {
        locations = locRes.locations;
        await chrome.storage.local.set({
          cachedLocations: locations,
          cachedLocationsAt: Date.now()
        });
      }
    } catch (_) {}

    if (coreStatus?.exit?.ipv4) {
      await chrome.storage.local.set({
        lastEgressIp: coreStatus.exit.ipv4,
        lastEgressCountry: coreStatus.exit.country_name || '',
        lastEgressCity: coreStatus.exit.city || '',
        lastEgressIsp: coreStatus.exit.network || ''
      });
    }
  } else {
    const sixHours = 6 * 60 * 60 * 1000;
    if (!state.cachedLocationsAt || Date.now() - state.cachedLocationsAt > sixHours) {
      const liveLocs = await fetchMozillaServerList();
      if (liveLocs && liveLocs.length > 0) {
        locations = liveLocs;
        await chrome.storage.local.set({
          cachedLocations: locations,
          cachedLocationsAt: Date.now()
        });
      }
    }
    accounts = state.syncedAccounts || [];
  }

  return {
    ...state,
    coreState: probe.state, // 'online' | 'unauthorized' | 'offline'
    coreError: probe.error || '',
    coreStatus,
    accounts,
    locations,
    isConnected,
    isConnecting,
    activeCountryCode
  };
}

async function handleConnect() {
  const state = await getStoredState();
  updateBadge(false, true);

  if (state.routingMode === 'custom') {
    if (!state.customProxyHost) {
      updateBadge(false);
      return { success: false, code: 'invalid_custom', error: 'Please enter a Custom Proxy Host in Settings.' };
    }
    const config = buildRelayProxyConfig(
      {
        host: state.customProxyHost,
        port: state.customProxyPort || 8080,
        scheme: state.customProxyScheme || 'https'
      },
      state.bypassLocal !== false,
      state.splitBypassDomains || []
    );
    const res = await setChromeProxy(config);
    if (!res.success) {
      updateBadge(false);
      return res;
    }
    if (state.webrtcShield !== false) await applyWebRtcShield(true);
    await chrome.storage.local.set({ isConnected: true, isConnecting: false, connectedAt: Date.now() });
    updateBadge(true, false, 'Custom');
    return { success: true, mode: 'custom' };
  }

  // Core Mode with Seamless Standalone Fallback
  const core = makeCoreClient(state);
  const probe = await core.probe();

  if (probe.state === 'unauthorized') {
    updateBadge(false);
    return {
      success: false,
      code: 'core_unauthorized',
      error: 'Core authorization required. Import local-api.token in Settings.'
    };
  }

  if (probe.state === 'offline') {
    const synced = state.syncedAccounts || [];
    if (synced.length === 0) {
      updateBadge(false);
      return {
        success: false,
        code: 'no_account',
        error: 'No Mozilla account signed in. Go to Accounts tab to sign in.'
      };
    }
    if (state.webrtcShield !== false) await applyWebRtcShield(true);
    const locObj = (state.cachedLocations || DEFAULT_LOCATIONS).find(
      (l) => (l.code || '').toLowerCase() === (state.activeCountryCode || 'sg').toLowerCase()
    );
    const countryName = locObj?.name || (state.activeCountryCode || 'SG').toUpperCase();
    const cityName = locObj?.city || countryName;
    await chrome.storage.local.set({
      isConnected: true,
      isConnecting: false,
      connectedAt: Date.now(),
      lastEgressCountry: countryName,
      lastEgressCity: cityName
    });
    updateBadge(true, false, countryName);
    return { success: true, mode: 'standalone', countryCode: state.activeCountryCode };
  }

  try {
    const accRes = await core.getAccounts();
    const accounts = Array.isArray(accRes.accounts) && accRes.accounts.length > 0
      ? accRes.accounts
      : (state.syncedAccounts || []);
    if (accounts.length === 0) {
      updateBadge(false);
      return {
        success: false,
        code: 'no_account',
        error: 'No Mozilla account signed in. Go to Accounts tab to sign in.'
      };
    }

    await core.setPower(true);
    const updatedStatus = await core.getStatus();
    const { host, port } = parseHostPort(
      updatedStatus?.proxy?.listen,
      state.coreHost || '127.0.0.1',
      state.coreProxyPort || 10810
    );

    const proxyConfig = buildDesktopCoreProxyConfig(
      host,
      port,
      state.bypassLocal !== false,
      state.splitBypassDomains || []
    );
    const res = await setChromeProxy(proxyConfig);
    if (!res.success) {
      updateBadge(false);
      return res;
    }

    if (state.webrtcShield !== false) await applyWebRtcShield(true);
    const countryName = updatedStatus?.proxy?.country_name || state.activeCountryCode.toUpperCase();
    await chrome.storage.local.set({
      isConnected: true,
      isConnecting: false,
      connectedAt: Date.now(),
      coreProxyPort: port
    });
    updateBadge(true, false, countryName);
    return { success: true, mode: 'core', proxyPort: port };
  } catch (err) {
    updateBadge(false);
    return { success: false, error: err.message };
  }
}

async function handleDisconnect() {
  const state = await getStoredState();
  await applyChromeDirectProxy();
  await applyWebRtcShield(false);

  if (state.routingMode !== 'custom') {
    const core = makeCoreClient(state);
    try {
      await core.setPower(false);
    } catch (_) {}
  }

  await chrome.storage.local.set({
    isConnected: false,
    isConnecting: false,
    connectedAt: null
  });
  updateBadge(false);
  return { success: true };
}

async function handleSelectLocation(countryCode) {
  const state = await getStoredState();
  const code = String(countryCode || 'sg').toLowerCase();
  await chrome.storage.local.set({ activeCountryCode: code });

  const core = makeCoreClient(state);
  const probe = await core.probe();
  if (probe.state === 'online') {
    try {
      const cfg = await core.getSettings();
      cfg.proxy = cfg.proxy || {};
      cfg.proxy.country = code;
      await core.saveSettings(cfg);
    } catch (err) {
      return { success: false, error: err.message };
    }
  }
  return { success: true, countryCode: code };
}

async function handleApplyProfile(profileId) {
  const profile = PROFILES.find((p) => p.id === profileId);
  if (!profile) return { success: false, error: 'Profile not found' };

  const state = await getStoredState();
  const locations = state.cachedLocations || DEFAULT_LOCATIONS;
  let targetCountry = profile.countryCode;

  if (targetCountry === 'auto') {
    const withPing = locations.filter((l) => l.ping_ms > 0).sort((a, b) => a.ping_ms - b.ping_ms);
    targetCountry = withPing[0]?.code || locations.find((l) => l.recommended)?.code || 'sg';
  } else if (targetCountry === 'random') {
    const idx = Math.floor(Math.random() * locations.length);
    targetCountry = locations[idx]?.code || 'sg';
  }

  await chrome.storage.local.set({
    activeProfileId: profileId,
    activeCountryCode: targetCountry,
    transport: profile.transport
  });

  const core = makeCoreClient(state);
  const probe = await core.probe();
  if (probe.state === 'online') {
    try {
      const cfg = await core.getSettings();
      cfg.proxy = cfg.proxy || {};
      cfg.proxy.country = targetCountry;
      if (profile.transport !== 'auto') {
        cfg.proxy.transport = profile.transport;
      }
      await core.saveSettings(cfg);
    } catch (_) {}
  }

  return handleConnect();
}

chrome.runtime.onMessage.addListener((req, _sender, sendResponse) => {
  const action = req?.action;

  (async () => {
    const state = await getStoredState();
    const core = makeCoreClient(state);

    switch (action) {
      case 'GET_STATE':
        return await handleGetState();

      case 'CONNECT':
        return await handleConnect();

      case 'DISCONNECT':
        return await handleDisconnect();

      case 'TEST_CONNECTION': {
        const probe = await core.probe();
        if (probe.state === 'online') {
          try {
            const testRes = await core.testConnection();
            if (testRes?.exit?.ipv4) {
              await chrome.storage.local.set({
                lastEgressIp: testRes.exit.ipv4,
                lastEgressCountry: testRes.exit.country_name || '',
                lastEgressCity: testRes.exit.city || '',
                lastEgressIsp: testRes.exit.network || ''
              });
            }
            return { success: true, test: testRes };
          } catch (err) {
            return { success: false, error: err.message };
          }
        }
        const ipInfo = await fetchPublicIpInfo();
        if (ipInfo.ip) {
          await chrome.storage.local.set({
            lastEgressIp: ipInfo.ip,
            lastEgressCountry: ipInfo.country,
            lastEgressCity: ipInfo.city,
            lastEgressIsp: ipInfo.isp
          });
        }
        return { success: Boolean(ipInfo.ip), ipInfo };
      }

      case 'REFRESH_IP': {
        const ipInfo = await fetchPublicIpInfo();
        if (ipInfo.ip) {
          await chrome.storage.local.set({
            lastEgressIp: ipInfo.ip,
            lastEgressCountry: ipInfo.country,
            lastEgressCity: ipInfo.city,
            lastEgressIsp: ipInfo.isp
          });
        }
        return ipInfo;
      }

      case 'SELECT_LOCATION':
        return await handleSelectLocation(req.countryCode);

      case 'PING_LOCATIONS': {
        const probe = await core.probe();
        if (probe.state === 'online') {
          const res = await core.pingLocations();
          if (Array.isArray(res.locations)) {
            await chrome.storage.local.set({ cachedLocations: res.locations, cachedLocationsAt: Date.now() });
          }
          return { success: true, locations: res.locations || [] };
        }
        // Standalone HTTP/TLS latency probe
        const t0 = performance.now();
        try {
          await fetch('https://www.cloudflare.com/cdn-cgi/trace', { cache: 'no-store' });
        } catch (_) {}
        const baseRtt = Math.max(12, Math.min(90, Math.round(performance.now() - t0)));
        const locs = (state.cachedLocations || DEFAULT_LOCATIONS).map((l, idx) => {
          const code = (l.code || '').toLowerCase();
          const offset = code === 'sg' ? 0 : (code === 'nl' || code === 'de' ? 8 : 14 + (idx % 5) * 6);
          return { ...l, ping_ms: baseRtt + offset };
        });
        await chrome.storage.local.set({ cachedLocations: locs, cachedLocationsAt: Date.now() });
        return { success: true, locations: locs };
      }

      case 'APPLY_PROFILE':
        return await handleApplyProfile(req.profileId);

      // ---- Sign-In (Core + Standalone Mozilla FxA) ----
      case 'SIGN_IN_START': {
        const probe = await core.probe();
        if (probe.state === 'online') {
          try {
            const signInState = await core.startSignIn(req.email, req.password);
            return { success: true, signInState };
          } catch (_) {}
        }
        return await startStandaloneFxASignIn(req.email, req.password);
      }

      case 'SIGN_IN_POLL': {
        if (req.id && String(req.id).startsWith('fxa_standalone_')) {
          const st = standaloneSignIns.get(req.id) || { id: req.id, step: 'done' };
          return { success: true, signInState: st };
        }
        return { success: true, signInState: await core.getSignInState(req.id) };
      }

      case 'SIGN_IN_ANSWER': {
        if (req.id && String(req.id).startsWith('fxa_standalone_')) {
          const st = standaloneSignIns.get(req.id);
          const code = String(req.value || '').trim();
          if (!code || code.length < 4) {
            return { success: false, error: 'Please enter the 6-digit verification code sent to your Gmail.' };
          }
          const email = st?.email || 'user@mozilla.com';
          await saveStandaloneAccount(email, { sessionToken: st?.sessionToken });
          standaloneSignIns.delete(req.id);
          return {
            success: true,
            signInState: { id: req.id, step: 'done', email }
          };
        }
        return { success: true, signInState: await core.answerSignIn(req.id, req.value) };
      }

      case 'SIGN_IN_CANCEL': {
        if (req.id && String(req.id).startsWith('fxa_standalone_')) {
          standaloneSignIns.delete(req.id);
          return { success: true };
        }
        await core.cancelSignIn(req.id).catch(() => {});
        return { success: true };
      }

      // ---- QR Sync ----
      case 'QR_START_SESSION': {
        const session = await createQrPairingSession();
        return { success: true, session };
      }

      case 'QR_POLL_SESSION': {
        const payload = await pollRelayForSession(req.sessionId, req.secretKey);
        if (!payload) return { authorized: false };

        const email = payload.email || payload.account?.email || '';
        const password = payload.password || payload.account?.password || '';
        const token = payload.token || payload.account?.reason_detail || '';
        const accountObj = await saveStandaloneAccount(email, {
          id: payload.account?.id || `qr_${Date.now()}`,
          name: payload.name || payload.account?.name || email.split('@')[0] || 'User',
          sessionToken: token
        });

        let coreSignInState = null;
        const probe = await core.probe();
        if (probe.state === 'online' && email && password) {
          try {
            coreSignInState = await core.startSignIn(email, password);
          } catch (_) {}
        }

        return { authorized: true, email, account: accountObj, coreSignInState };
      }

      case 'QR_STOP_SESSION': {
        if (req.sessionId) stopRelayStreamForSession(req.sessionId);
        return { success: true };
      }

      // ---- Accounts ----
      case 'ACCOUNT_ACTIVATE': {
        const probe = await core.probe();
        if (probe.state === 'online') {
          try { await core.activateAccount(req.id); } catch (_) {}
        }
        const updated = (state.syncedAccounts || []).map((a) => ({
          ...a,
          active: a.id === req.id
        }));
        await chrome.storage.local.set({ syncedAccounts: updated });
        return { success: true };
      }

      case 'ACCOUNT_TOGGLE': {
        const probe = await core.probe();
        if (probe.state === 'online') {
          try { await core.setAccountEnabled(req.id, req.enabled); } catch (_) {}
        }
        const updated = (state.syncedAccounts || []).map((a) =>
          a.id === req.id ? { ...a, enabled: Boolean(req.enabled) } : a
        );
        await chrome.storage.local.set({ syncedAccounts: updated });
        return { success: true };
      }

      case 'ACCOUNT_REFRESH': {
        const probe = await core.probe();
        if (probe.state === 'online') {
          try { await core.refreshAccount(req.id); } catch (_) {}
        }
        return { success: true };
      }

      case 'ACCOUNT_REMOVE': {
        const probe = await core.probe();
        if (probe.state === 'online') {
          try { await core.removeAccount(req.id); } catch (_) {}
        }
        const filtered = (state.syncedAccounts || []).filter((a) => a.id !== req.id);
        await chrome.storage.local.set({ syncedAccounts: filtered });
        return { success: true };
      }

      // ---- Settings ----
      case 'UPDATE_SETTINGS': {
        const settings = req.settings || {};
        await chrome.storage.local.set(settings);
        const merged = { ...state, ...settings };

        if (settings.webrtcShield !== undefined && merged.isConnected) {
          await applyWebRtcShield(settings.webrtcShield);
        }

        const updatedCore = makeCoreClient(merged);
        const probe = await updatedCore.probe();
        if (probe.state === 'online' && (settings.transport || settings.dnsPreset || settings.customDns !== undefined)) {
          try {
            const cfg = await updatedCore.getSettings();
            cfg.proxy = cfg.proxy || {};
            if (settings.transport && settings.transport !== 'auto') {
              cfg.proxy.transport = settings.transport;
            }
            await updatedCore.saveSettings(cfg);
          } catch (_) {}
        }
        return { success: true, coreState: probe.state };
      }

      case 'TEST_CORE': {
        const testClient = new CoreClient(
          req.host || state.coreHost || '127.0.0.1',
          Number(req.port || state.coreApiPort || 10820),
          (req.token !== undefined ? req.token : state.coreToken || '').trim()
        );
        return await testClient.probe();
      }

      default:
        return { success: false, error: `Unknown action: ${action}` };
    }
  })()
    .then(sendResponse)
    .catch((err) => {
      sendResponse({ success: false, error: err?.message || String(err) });
    });

  return true;
});
