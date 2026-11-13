/**
 * TeroVPN Chrome Extension - Background Service Worker
 * Full integration with TeroVPN Core API, E2EE QR Sync, WebRTC Shield & Chrome Proxy API.
 * Version: 1.2.0
 */

import { CoreClient, fetchMozillaServerList } from './core-client.js';
import { DEFAULT_LOCATIONS, PROFILES } from './servers.js';
import {
  buildDesktopCoreProxyConfig,
  buildRelayProxyConfig,
  buildDirectConfig
} from './proxy-rules.js';
import { createQrPairingSession, pollRelayForSession } from './qr-sync.js';

const DEFAULT_STATE = {
  isConnected: false,
  isConnecting: false,
  connectedAt: null,
  activeCountryCode: 'nl',
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
      accounts = Array.isArray(accRes.accounts) ? accRes.accounts : [];
    } catch (_) {}

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
    // Refresh Mozilla Remote Settings server list every 6 hours when Core is offline
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

  // Core Mode
  const core = makeCoreClient(state);
  const probe = await core.probe();
  if (probe.state === 'offline') {
    updateBadge(false);
    return {
      success: false,
      code: 'core_offline',
      error: 'TeroVPN Core not running on 127.0.0.1:' + (state.coreApiPort || 10820) + '. Start TeroVPN Desktop first.'
    };
  }
  if (probe.state === 'unauthorized') {
    updateBadge(false);
    return {
      success: false,
      code: 'core_unauthorized',
      error: 'Core authorization required. Import local-api.token in Settings.'
    };
  }

  try {
    const accRes = await core.getAccounts();
    const accounts = Array.isArray(accRes.accounts) ? accRes.accounts : [];
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
  const code = String(countryCode || 'nl').toLowerCase();
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
    targetCountry = withPing[0]?.code || locations.find((l) => l.recommended)?.code || 'nl';
  } else if (targetCountry === 'random') {
    const idx = Math.floor(Math.random() * locations.length);
    targetCountry = locations[idx]?.code || 'nl';
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
        if (probe.state !== 'online') {
          return { success: false, error: 'Core offline; cannot run native ICMP/TLS ping.' };
        }
        const res = await core.pingLocations();
        if (Array.isArray(res.locations)) {
          await chrome.storage.local.set({ cachedLocations: res.locations, cachedLocationsAt: Date.now() });
        }
        return { success: true, locations: res.locations || [] };
      }

      case 'APPLY_PROFILE':
        return await handleApplyProfile(req.profileId);

      // ---- Sign-In ----
      case 'SIGN_IN_START': {
        const probe = await core.probe();
        if (probe.state !== 'online') {
          return {
            success: false,
            error:
              probe.state === 'unauthorized'
                ? 'Core token invalid. Import local-api.token in Settings.'
                : 'TeroVPN Core must be running on 127.0.0.1:' + (state.coreApiPort || 10820) + ' to perform Mozilla FxA sign-in.'
          };
        }
        const signInState = await core.startSignIn(req.email, req.password);
        return { success: true, signInState };
      }

      case 'SIGN_IN_POLL':
        return { success: true, signInState: await core.getSignInState(req.id) };

      case 'SIGN_IN_ANSWER':
        return { success: true, signInState: await core.answerSignIn(req.id, req.value) };

      case 'SIGN_IN_CANCEL':
        await core.cancelSignIn(req.id).catch(() => {});
        return { success: true };

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
        const accountObj = payload.account || {
          id: `qr_${Date.now()}`,
          email,
          name: payload.name || email.split('@')[0] || 'User',
          status: 'ready',
          active: true,
          enabled: true
        };

        const existing = (state.syncedAccounts || []).filter((a) => a.email !== email);
        await chrome.storage.local.set({ syncedAccounts: [accountObj, ...existing] });

        let coreSignInState = null;
        const probe = await core.probe();
        if (probe.state === 'online' && email && password) {
          try {
            coreSignInState = await core.startSignIn(email, password);
          } catch (_) {}
        }

        return { authorized: true, email, account: accountObj, coreSignInState };
      }

      // ---- Accounts ----
      case 'ACCOUNT_ACTIVATE':
        await core.activateAccount(req.id);
        return { success: true };

      case 'ACCOUNT_TOGGLE':
        await core.setAccountEnabled(req.id, req.enabled);
        return { success: true };

      case 'ACCOUNT_REFRESH':
        await core.refreshAccount(req.id);
        return { success: true };

      case 'ACCOUNT_REMOVE': {
        const probe = await core.probe();
        if (probe.state === 'online') {
          await core.removeAccount(req.id);
        } else {
          const filtered = (state.syncedAccounts || []).filter((a) => a.id !== req.id);
          await chrome.storage.local.set({ syncedAccounts: filtered });
        }
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
