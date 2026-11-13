/**
 * TeroVPN Chrome Extension - Background Service Worker
 * Version: 1.2.0
 */

import { SERVERS, getDefaultServer, getServerById } from './servers.js';
import {
  buildDesktopCoreProxyConfig,
  buildRelayProxyConfig,
  buildDirectConfig
} from './proxy-rules.js';

const DEFAULT_STATE = {
  isConnected: false,
  isConnecting: false,
  connectedAt: null,
  activeServerId: 'nl-ams-01',
  routingMode: 'auto', // 'auto' | 'core' | 'relay' | 'custom'
  coreHost: '127.0.0.1',
  coreApiPort: 10820,
  coreProxyPort: 10810,
  customProxyHost: '',
  customProxyPort: 8080,
  customProxyScheme: 'https',
  webrtcShield: true,
  bypassLocal: true,
  autoConnect: false,
  lastEgressIp: '',
  lastEgressCountry: ''
};

// Initialize default storage on install
chrome.runtime.onInstalled.addListener(async (details) => {
  const existing = await chrome.storage.local.get(null);
  const initial = { ...DEFAULT_STATE, ...existing };
  await chrome.storage.local.set(initial);
  updateBadge(false);
  console.log('[TeroVPN] Extension installed/updated, version 1.2.0');
});

// Auto-connect on browser startup if enabled
chrome.runtime.onStartup.addListener(async () => {
  const state = await chrome.storage.local.get(null);
  if (state.autoConnect) {
    console.log('[TeroVPN] Auto-connect enabled, initiating connection...');
    await handleConnect();
  } else {
    // Ensure clean direct state on browser start
    await handleDisconnect();
  }
});

// Keep badge synced
function updateBadge(connected, connecting = false, serverName = '') {
  try {
    if (connecting) {
      chrome.action.setBadgeText({ text: '...' });
      chrome.action.setBadgeBackgroundColor({ color: '#F59E0B' });
      chrome.action.setTitle({ title: 'TeroVPN (Connecting...)' });
    } else if (connected) {
      chrome.action.setBadgeText({ text: 'ON' });
      chrome.action.setBadgeBackgroundColor({ color: '#10B981' });
      const title = serverName ? `TeroVPN (Connected - ${serverName})` : 'TeroVPN (Connected)';
      chrome.action.setTitle({ title });
    } else {
      chrome.action.setBadgeText({ text: '' });
      chrome.action.setTitle({ title: 'TeroVPN (Disconnected)' });
    }
  } catch (err) {
    console.warn('[TeroVPN] Failed to update badge:', err);
  }
}

// Check if local desktop core is running and responding
async function probeDesktopCore(apiPort = 10820) {
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 1200);
    const res = await fetch(`http://127.0.0.1:${apiPort}/api/status`, {
      method: 'GET',
      signal: controller.signal
    });
    clearTimeout(timeoutId);
    if (res.ok) {
      const data = await res.json();
      return { online: true, data };
    }
  } catch (_) {}
  return { online: false, data: null };
}

// Set WebRTC IP handling policy to prevent IP leaks
async function applyWebRtcShield(enable) {
  try {
    if (!chrome.privacy || !chrome.privacy.network || !chrome.privacy.network.webRTCIPHandlingPolicy) {
      return;
    }
    const policy = enable ? 'disable_non_proxied_udp' : 'default';
    await chrome.privacy.network.webRTCIPHandlingPolicy.set({
      value: policy,
      scope: 'regular'
    });
    console.log(`[TeroVPN] WebRTC shield policy set to: ${policy}`);
  } catch (err) {
    console.warn('[TeroVPN] WebRTC policy error:', err);
  }
}

// Perform external IP verification
async function fetchEgressInfo() {
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 4000);
    const res = await fetch('https://api.ipify.org?format=json', {
      signal: controller.signal
    });
    clearTimeout(timeoutId);
    if (res.ok) {
      const json = await res.json();
      return { ip: json.ip || '' };
    }
  } catch (_) {}
  return { ip: '' };
}

// Main Connect Handler
async function handleConnect() {
  const state = await chrome.storage.local.get(null);
  const server = getServerById(state.activeServerId);
  updateBadge(false, true);

  await chrome.storage.local.set({ isConnecting: true });

  let config;
  let usedMode = state.routingMode;

  if (state.routingMode === 'auto') {
    const coreProbe = await probeDesktopCore(state.coreApiPort || 10820);
    if (coreProbe.online) {
      usedMode = 'core';
      console.log('[TeroVPN] Local desktop core detected at 127.0.0.1');
      config = buildDesktopCoreProxyConfig(
        state.coreHost || '127.0.0.1',
        state.coreProxyPort || 10810,
        state.bypassLocal !== false
      );
    } else {
      usedMode = 'relay';
      console.log('[TeroVPN] Desktop core not running, falling back to Standalone Cloud Relay');
      config = buildRelayProxyConfig(server, state.bypassLocal !== false);
    }
  } else if (state.routingMode === 'core') {
    config = buildDesktopCoreProxyConfig(
      state.coreHost || '127.0.0.1',
      state.coreProxyPort || 10810,
      state.bypassLocal !== false
    );
  } else if (state.routingMode === 'custom' && state.customProxyHost) {
    config = buildRelayProxyConfig({
      host: state.customProxyHost,
      port: state.customProxyPort || 8080,
      scheme: state.customProxyScheme || 'https'
    }, state.bypassLocal !== false);
  } else {
    config = buildRelayProxyConfig(server, state.bypassLocal !== false);
  }

  return new Promise((resolve) => {
    chrome.proxy.settings.set({ value: config, scope: 'regular' }, async () => {
      if (chrome.runtime.lastError) {
        console.error('[TeroVPN] Error setting proxy:', chrome.runtime.lastError);
        updateBadge(false);
        await chrome.storage.local.set({
          isConnected: false,
          isConnecting: false
        });
        resolve({ success: false, error: chrome.runtime.lastError.message });
        return;
      }

      // Apply WebRTC leak protection
      if (state.webrtcShield !== false) {
        await applyWebRtcShield(true);
      }

      const connectedAt = Date.now();
      await chrome.storage.local.set({
        isConnected: true,
        isConnecting: false,
        connectedAt,
        effectiveMode: usedMode
      });

      updateBadge(true, false, server.countryName);

      // Async IP verification (doesn't block connect return)
      fetchEgressInfo().then(async (info) => {
        if (info.ip) {
          await chrome.storage.local.set({ lastEgressIp: info.ip });
        }
      });

      resolve({ success: true, effectiveMode: usedMode });
    });
  });
}

// Main Disconnect Handler
async function handleDisconnect() {
  const directConfig = buildDirectConfig();

  return new Promise((resolve) => {
    chrome.proxy.settings.set({ value: directConfig, scope: 'regular' }, async () => {
      // Revert WebRTC policy
      await applyWebRtcShield(false);

      await chrome.storage.local.set({
        isConnected: false,
        isConnecting: false,
        connectedAt: null,
        lastEgressIp: ''
      });

      updateBadge(false);
      resolve({ success: true });
    });
  });
}

// Unified message router
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  const action = request.action;

  if (action === 'CONNECT') {
    handleConnect().then(sendResponse);
    return true; // Keep channel open for async response
  }

  if (action === 'DISCONNECT') {
    handleDisconnect().then(sendResponse);
    return true;
  }

  if (action === 'GET_STATUS') {
    chrome.storage.local.get(null).then(async (state) => {
      const coreProbe = await probeDesktopCore(state.coreApiPort || 10820);
      sendResponse({
        ...state,
        coreOnline: coreProbe.online,
        coreStatus: coreProbe.data
      });
    });
    return true;
  }

  if (action === 'SET_SERVER') {
    const serverId = request.serverId;
    chrome.storage.local.set({ activeServerId: serverId }).then(async () => {
      const state = await chrome.storage.local.get(null);
      if (state.isConnected) {
        // Re-route with new server seamlessly
        await handleConnect();
      }
      sendResponse({ success: true });
    });
    return true;
  }

  if (action === 'CHECK_CORE') {
    probeDesktopCore(request.port || 10820).then(sendResponse);
    return true;
  }

  if (action === 'REFRESH_IP') {
    fetchEgressInfo().then(async (res) => {
      if (res.ip) {
        await chrome.storage.local.set({ lastEgressIp: res.ip });
      }
      sendResponse(res);
    });
    return true;
  }

  if (action === 'UPDATE_SETTINGS') {
    chrome.storage.local.set(request.settings || {}).then(async () => {
      if (request.settings && request.settings.webrtcShield !== undefined) {
        const state = await chrome.storage.local.get(null);
        if (state.isConnected) {
          await applyWebRtcShield(request.settings.webrtcShield);
        }
      }
      sendResponse({ success: true });
    });
    return true;
  }

  sendResponse({ error: 'Unknown action' });
});
