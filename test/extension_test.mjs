/**
 * Automated Test Suite for TeroVPN Chrome Extension v1.2.0
 * Run with: node test/extension_test.mjs
 */

import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';

const ROOT_DIR = process.cwd();
const EXT_DIR = path.join(ROOT_DIR, 'extension');

console.log('====================================================');
console.log('🧪 Running TeroVPN Chrome Extension Test Suite');
console.log(`📂 Extension directory: ${EXT_DIR}`);
console.log('====================================================\n');

let passedTests = 0;
let totalTests = 0;

function test(name, fn) {
  totalTests++;
  try {
    fn();
    console.log(`  ✅ PASS: ${name}`);
    passedTests++;
  } catch (err) {
    console.error(`  ❌ FAIL: ${name}`);
    console.error(err);
    process.exitCode = 1;
  }
}

async function runAsyncTest(name, fn) {
  totalTests++;
  try {
    await fn();
    console.log(`  ✅ PASS: ${name}`);
    passedTests++;
  } catch (err) {
    console.error(`  ❌ FAIL: ${name}`);
    console.error(err);
    process.exitCode = 1;
  }
}

// ----------------------------------------------------
// 1. Manifest V3 Schema & Asset Checks
// ----------------------------------------------------
console.log('--- 1. Manifest V3 & File Integrity ---');

test('manifest.json exists and is valid JSON', () => {
  const manifestPath = path.join(EXT_DIR, 'manifest.json');
  assert.ok(fs.existsSync(manifestPath), 'manifest.json must exist');
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  assert.equal(manifest.manifest_version, 3, 'Must be Manifest V3');
  assert.equal(manifest.version, '1.2.0', 'Version must be 1.2.0');
  assert.equal(manifest.name, 'TeroVPN - Secure High-Speed Proxy & VPN');
  assert.ok(manifest.permissions.includes('proxy'), 'Missing proxy permission');
  assert.ok(manifest.permissions.includes('storage'), 'Missing storage permission');
  assert.ok(manifest.permissions.includes('privacy'), 'Missing privacy permission');
  assert.ok(manifest.background.service_worker === 'background.js', 'Service worker missing');
  assert.ok(manifest.background.type === 'module', 'Background must be ES module');
});

test('Icons referenced in manifest exist on disk', () => {
  const manifest = JSON.parse(fs.readFileSync(path.join(EXT_DIR, 'manifest.json'), 'utf8'));
  for (const [size, iconPath] of Object.entries(manifest.icons)) {
    const fullPath = path.join(EXT_DIR, iconPath);
    assert.ok(fs.existsSync(fullPath), `Icon ${iconPath} (${size}px) not found`);
    const stat = fs.statSync(fullPath);
    assert.ok(stat.size > 100, `Icon ${iconPath} is suspiciously small (${stat.size} bytes)`);
  }
});

test('Action icons exist on disk', () => {
  const manifest = JSON.parse(fs.readFileSync(path.join(EXT_DIR, 'manifest.json'), 'utf8'));
  for (const [size, iconPath] of Object.entries(manifest.action.default_icon)) {
    const fullPath = path.join(EXT_DIR, iconPath);
    assert.ok(fs.existsSync(fullPath), `Action icon ${iconPath} (${size}px) not found`);
  }
});

test('HTML files and linked assets exist', () => {
  assert.ok(fs.existsSync(path.join(EXT_DIR, 'popup.html')), 'popup.html missing');
  assert.ok(fs.existsSync(path.join(EXT_DIR, 'popup.css')), 'popup.css missing');
  assert.ok(fs.existsSync(path.join(EXT_DIR, 'popup.js')), 'popup.js missing');
  assert.ok(fs.existsSync(path.join(EXT_DIR, 'options.html')), 'options.html missing');
  assert.ok(fs.existsSync(path.join(EXT_DIR, 'options.js')), 'options.js missing');
  assert.ok(fs.existsSync(path.join(EXT_DIR, 'servers.js')), 'servers.js missing');
  assert.ok(fs.existsSync(path.join(EXT_DIR, 'proxy-rules.js')), 'proxy-rules.js missing');
  assert.ok(fs.existsSync(path.join(EXT_DIR, 'background.js')), 'background.js missing');
});

// ----------------------------------------------------
// 2. Servers & Flags Validation
// ----------------------------------------------------
console.log('\n--- 2. Servers & Country Flags ---');

const { SERVERS, getDefaultServer, getServerById, getFlagUrl } = await import('../extension/servers.js');

test('Server list contains expected global locations', () => {
  assert.ok(Array.isArray(SERVERS) && SERVERS.length >= 10, 'Must have at least 10 server locations');
  const defaultServer = getDefaultServer();
  assert.ok(defaultServer, 'Default server must be defined');
  assert.equal(defaultServer.countryCode, 'nl', 'Default server should be Netherlands');

  const serverById = getServerById('us-nyc-01');
  assert.equal(serverById.cityName, 'New York');
});

test('Every server location has a matching SVG flag in extension/flags', () => {
  for (const server of SERVERS) {
    const flagRelPath = getFlagUrl(server.countryCode);
    const flagFullPath = path.join(EXT_DIR, flagRelPath);
    assert.ok(fs.existsSync(flagFullPath), `Flag not found for country ${server.countryCode}: ${flagRelPath}`);
    const content = fs.readFileSync(flagFullPath, 'utf8');
    assert.ok(content.includes('<svg'), `Flag file ${flagRelPath} is not valid SVG`);
  }
});

// ----------------------------------------------------
// 3. Proxy Rules Engine Validation
// ----------------------------------------------------
console.log('\n--- 3. Proxy Rules Engine ---');

const {
  buildDesktopCoreProxyConfig,
  buildRelayProxyConfig,
  buildDirectConfig,
  DEFAULT_BYPASS_LIST
} = await import('../extension/proxy-rules.js');

test('buildDirectConfig returns direct mode', () => {
  const config = buildDirectConfig();
  assert.deepEqual(config, { mode: 'direct' });
});

test('buildDesktopCoreProxyConfig generates valid PAC script with bypass', () => {
  const config = buildDesktopCoreProxyConfig('127.0.0.1', 10810, true);
  assert.equal(config.mode, 'pac_script');
  assert.ok(config.pacScript.data.includes('FindProxyForURL'), 'PAC script must define FindProxyForURL');
  assert.ok(config.pacScript.data.includes('127.0.0.1:10810'), 'PAC script must include core host and port');
  assert.ok(config.pacScript.data.includes('DIRECT'), 'PAC script must have fallback DIRECT');
  assert.ok(config.pacScript.data.includes('192.168.0.0'), 'PAC script must include RFC1918 bypass');
});

test('buildRelayProxyConfig generates valid config for HTTPS and SOCKS5', () => {
  const serverHttps = {
    host: 'nl.relay.terovpn.net',
    port: 443,
    scheme: 'https'
  };
  const configHttps = buildRelayProxyConfig(serverHttps, true);
  assert.equal(configHttps.mode, 'pac_script');
  assert.ok(configHttps.pacScript.data.includes('HTTPS nl.relay.terovpn.net:443'));

  const serverSocks = {
    host: 'us.relay.terovpn.net',
    port: 1080,
    scheme: 'socks5'
  };
  const configSocks = buildRelayProxyConfig(serverSocks, true);
  assert.equal(configSocks.mode, 'fixed_servers');
  assert.equal(configSocks.rules.singleProxy.scheme, 'socks5');
  assert.equal(configSocks.rules.singleProxy.host, 'us.relay.terovpn.net');
  assert.equal(configSocks.rules.singleProxy.port, 1080);
  assert.ok(configSocks.rules.bypassList.includes('localhost'));
});

// ----------------------------------------------------
// 4. DOM & Script IDs Cross-Consistency Check
// ----------------------------------------------------
console.log('\n--- 4. DOM Element & Script Consistency ---');

test('All element IDs queried in popup.js exist in popup.html', () => {
  const html = fs.readFileSync(path.join(EXT_DIR, 'popup.html'), 'utf8');
  const js = fs.readFileSync(path.join(EXT_DIR, 'popup.js'), 'utf8');

  // Regex to extract all document.getElementById('...')
  const idRegex = /document\.getElementById\(['"]([^'"]+)['"]\)/g;
  let match;
  const queriedIds = new Set();
  while ((match = idRegex.exec(js)) !== null) {
    queriedIds.add(match[1]);
  }

  assert.ok(queriedIds.size > 0, 'Should find queried IDs in popup.js');

  for (const id of queriedIds) {
    const hasId = html.includes(`id="${id}"`) || html.includes(`id='${id}'`);
    assert.ok(hasId, `ID '${id}' referenced in popup.js was NOT found in popup.html!`);
  }
});

test('All element IDs queried in options.js exist in options.html', () => {
  const html = fs.readFileSync(path.join(EXT_DIR, 'options.html'), 'utf8');
  const js = fs.readFileSync(path.join(EXT_DIR, 'options.js'), 'utf8');

  const idRegex = /document\.getElementById\(['"]([^'"]+)['"]\)/g;
  let match;
  const queriedIds = new Set();
  while ((match = idRegex.exec(js)) !== null) {
    queriedIds.add(match[1]);
  }

  assert.ok(queriedIds.size > 0, 'Should find queried IDs in options.js');

  for (const id of queriedIds) {
    const hasId = html.includes(`id="${id}"`) || html.includes(`id='${id}'`);
    assert.ok(hasId, `ID '${id}' referenced in options.js was NOT found in options.html!`);
  }
});

// ----------------------------------------------------
// 5. Simulated Chrome Runtime & Service Worker Message Flow
// ----------------------------------------------------
console.log('\n--- 5. Runtime & Proxy Simulation ---');

await runAsyncTest('Chrome Proxy & Storage messaging lifecycle simulation', async () => {
  // In-memory mock of Chrome extension APIs
  let mockStorage = {};
  let mockProxySettings = { value: { mode: 'direct' } };
  let mockPrivacyPolicy = { value: 'default' };
  let mockBadge = { text: '', color: '', title: '' };

  const mockChrome = {
    storage: {
      local: {
        get: async (keys) => {
          if (!keys) return { ...mockStorage };
          if (typeof keys === 'string') return { [keys]: mockStorage[keys] };
          return { ...mockStorage };
        },
        set: async (obj) => {
          Object.assign(mockStorage, obj);
        }
      }
    },
    proxy: {
      settings: {
        set: (details, callback) => {
          mockProxySettings = details;
          if (callback) callback();
        }
      }
    },
    privacy: {
      network: {
        webRTCIPHandlingPolicy: {
          set: async (details) => {
            mockPrivacyPolicy = details;
          }
        }
      }
    },
    action: {
      setBadgeText: (d) => { mockBadge.text = d.text; },
      setBadgeBackgroundColor: (d) => { mockBadge.color = d.color; },
      setTitle: (d) => { mockBadge.title = d.title; }
    },
    runtime: {
      lastError: null
    }
  };

  // 1. Initial State
  assert.equal(mockProxySettings.value.mode, 'direct');
  assert.equal(mockPrivacyPolicy.value, 'default');
  assert.equal(mockBadge.text, '');

  // 2. Simulate connect
  const server = getServerById('nl-ams-01');
  const proxyConfig = buildRelayProxyConfig(server, true);
  mockChrome.proxy.settings.set({ value: proxyConfig, scope: 'regular' });
  await mockChrome.privacy.network.webRTCIPHandlingPolicy.set({ value: 'disable_non_proxied_udp', scope: 'regular' });
  mockChrome.action.setBadgeText({ text: 'ON' });
  mockChrome.action.setBadgeBackgroundColor({ color: '#10B981' });
  await mockChrome.storage.local.set({ isConnected: true, activeServerId: 'nl-ams-01' });

  // Verification after Connect
  assert.equal(mockProxySettings.value.mode, 'pac_script');
  assert.equal(mockPrivacyPolicy.value, 'disable_non_proxied_udp');
  assert.equal(mockBadge.text, 'ON');
  assert.equal(mockBadge.color, '#10B981');
  const stored = await mockChrome.storage.local.get(null);
  assert.equal(stored.isConnected, true);

  // 3. Simulate disconnect
  const directConfig = buildDirectConfig();
  mockChrome.proxy.settings.set({ value: directConfig, scope: 'regular' });
  await mockChrome.privacy.network.webRTCIPHandlingPolicy.set({ value: 'default', scope: 'regular' });
  mockChrome.action.setBadgeText({ text: '' });
  await mockChrome.storage.local.set({ isConnected: false });

  // Verification after Disconnect
  assert.equal(mockProxySettings.value.mode, 'direct');
  assert.equal(mockPrivacyPolicy.value, 'default');
  assert.equal(mockBadge.text, '');
  const storedAfter = await mockChrome.storage.local.get(null);
  assert.equal(storedAfter.isConnected, false);
});

console.log('\n====================================================');
console.log(`📊 Test Results: ${passedTests} / ${totalTests} tests passed`);
console.log('====================================================\n');

if (passedTests !== totalTests) {
  process.exit(1);
}
