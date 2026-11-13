/**
 * Comprehensive Automated Test Suite for TeroVPN Chrome Extension v1.2.0
 * Run with: node test/extension_test.mjs
 */

import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import assert from 'node:assert/strict';

const ROOT_DIR = process.cwd();
const EXT_DIR = path.join(ROOT_DIR, 'extension');

console.log('====================================================');
console.log('🧪 Running TeroVPN Chrome Extension v1.2.0 Test Suite');
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
// 1. Manifest V3 & File Integrity
// ----------------------------------------------------
console.log('--- 1. Manifest V3 & File Integrity ---');

test('manifest.json exists and has valid Manifest V3 fields', () => {
  const manifest = JSON.parse(fs.readFileSync(path.join(EXT_DIR, 'manifest.json'), 'utf8'));
  assert.equal(manifest.manifest_version, 3);
  assert.equal(manifest.version, '1.2.0');
  assert.ok(manifest.permissions.includes('proxy'));
  assert.ok(manifest.permissions.includes('storage'));
  assert.ok(manifest.permissions.includes('privacy'));
  assert.equal(manifest.background.service_worker, 'background.js');
  assert.equal(manifest.background.type, 'module');
});

test('All required extension modules and HTML/CSS files exist', () => {
  const required = [
    'manifest.json', 'background.js', 'core-client.js', 'proxy-rules.js',
    'servers.js', 'qr-sync.js', 'qrcode.js',
    'popup.html', 'popup.css', 'popup.js',
    'options.html', 'options.js',
    'icons/icon16.png', 'icons/icon32.png', 'icons/icon48.png', 'icons/icon128.png'
  ];
  for (const f of required) {
    assert.ok(fs.existsSync(path.join(EXT_DIR, f)), `Missing file: ${f}`);
  }
});

// ----------------------------------------------------
// 2. Locations, Profiles, DNS & Flags
// ----------------------------------------------------
console.log('\n--- 2. Locations, Profiles, DNS & Flags ---');

const { DEFAULT_LOCATIONS, PROFILES, DNS_PRESETS, getFlagUrl, getLocationByCode } = await import('../extension/servers.js');

test('DEFAULT_LOCATIONS, PROFILES, and DNS_PRESETS are properly populated', () => {
  assert.ok(DEFAULT_LOCATIONS.length >= 15);
  assert.equal(PROFILES.length, 5);
  assert.ok(DNS_PRESETS.length >= 4);
  assert.equal(getLocationByCode('us').name, 'United States');
});

test('Every default location has a valid SVG flag', () => {
  for (const loc of DEFAULT_LOCATIONS) {
    const flagPath = path.join(EXT_DIR, getFlagUrl(loc.code));
    assert.ok(fs.existsSync(flagPath), `Missing flag SVG for ${loc.code}`);
  }
});

// ----------------------------------------------------
// 3. QR Code Generator & E2EE QR Sync
// ----------------------------------------------------
console.log('\n--- 3. QR Code Generator & AES-256 E2EE Sync ---');

const { generateQrMatrix, renderQrSvg } = await import('../extension/qrcode.js');
const { createQrPairingSession, encryptPayload, decryptPayload } = await import('../extension/qr-sync.js');

test('Pure JS QR Code generator produces valid matrix and SVG for terovpn://pair URI', () => {
  const sampleUri = 'terovpn://pair?sid=tero_0123456789abcdef_123456&k=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=&relay=ntfy.sh&t=1700000000000';
  const matrix = generateQrMatrix(sampleUri);
  assert.ok(Array.isArray(matrix) && matrix.length >= 21, 'QR matrix must be >= 21x21');
  assert.equal(matrix.length, matrix[0].length, 'QR matrix must be square');
  const svg = renderQrSvg(sampleUri, 165);
  assert.ok(svg.startsWith('<svg ') && svg.includes('<rect '), 'Rendered output must be valid SVG');
});

await runAsyncTest('E2EE QR Pairing Session & AES-256-CBC + HMAC-SHA256 round-trip', async () => {
  const session = await createQrPairingSession();
  assert.ok(session.sessionId.startsWith('tero_'));
  assert.ok(session.secretKey.length >= 40);
  assert.ok(session.payload.startsWith('terovpn://pair?sid='));

  const secretPayload = { email: 'user@example.com', password: 'PLACEHOLDER_PASSWORD' };
  const envelope = await encryptPayload(secretPayload, session.secretKey);
  assert.equal(envelope.e2ee, true);
  assert.ok(envelope.cipher && envelope.iv && envelope.mac);

  const decrypted = await decryptPayload(envelope, session.secretKey);
  assert.deepEqual(decrypted, secretPayload);

  // Tampered MAC must fail verification
  const tampered = { ...envelope, mac: '0'.repeat(64) };
  const failed = await decryptPayload(tampered, session.secretKey);
  assert.equal(failed, null);
});

// ----------------------------------------------------
// 4. Proxy Rules Engine
// ----------------------------------------------------
console.log('\n--- 4. Proxy Rules & Split Tunneling ---');

const { buildDesktopCoreProxyConfig, buildRelayProxyConfig, buildDirectConfig } = await import('../extension/proxy-rules.js');

test('buildDesktopCoreProxyConfig includes core port and custom bypass domains', () => {
  const cfg = buildDesktopCoreProxyConfig('127.0.0.1', 10810, true, ['*.internal.corp']);
  assert.equal(cfg.mode, 'pac_script');
  assert.ok(cfg.pacScript.data.includes('SOCKS5 127.0.0.1:10810'));
  assert.ok(cfg.pacScript.data.includes('*.internal.corp'));
});

test('buildRelayProxyConfig and buildDirectConfig work cleanly', () => {
  const socksCfg = buildRelayProxyConfig({ host: '10.0.0.5', port: 1080, scheme: 'socks5' }, true);
  assert.equal(socksCfg.mode, 'fixed_servers');
  assert.equal(socksCfg.rules.singleProxy.scheme, 'socks5');
  assert.deepEqual(buildDirectConfig(), { mode: 'direct' });
});

// ----------------------------------------------------
// 5. CoreClient Live HTTP Integration Test
// ----------------------------------------------------
console.log('\n--- 5. CoreClient Live HTTP Integration Test ---');

const { CoreClient } = await import('../extension/core-client.js');

await runAsyncTest('CoreClient communicates with local HTTP Core API & enforces X-Local-Token', async () => {
  const expectedToken = 'test_local_token_123';
  const server = http.createServer((req, res) => {
    if (req.headers['x-local-token'] !== expectedToken) {
      res.writeHead(401, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Unauthorized' }));
      return;
    }
    res.writeHead(200, { 'Content-Type': 'application/json' });
    if (req.url === '/api/status') {
      res.end(JSON.stringify({
        state: { phase: 'running' },
        proxy: { listen: '127.0.0.1:10810', country_code: 'nl', country_name: 'Netherlands' }
      }));
    } else if (req.url === '/api/accounts') {
      res.end(JSON.stringify({
        accounts: [{ id: 'acc1', email: 'test@example.com', active: true, status: 'ready' }]
      }));
    } else if (req.url === '/api/signin' && req.method === 'POST') {
      res.end(JSON.stringify({ id: 'si_1', step: 'need_totp' }));
    } else if (req.url === '/api/signin/si_1' && req.method === 'POST') {
      res.end(JSON.stringify({ id: 'si_1', step: 'done' }));
    } else if (req.url === '/api/power' && req.method === 'POST') {
      res.end(JSON.stringify({ ok: true }));
    } else {
      res.end(JSON.stringify({ ok: true }));
    }
  });

  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const port = server.address().port;

  try {
    // 1. Wrong token -> unauthorized
    const badClient = new CoreClient('127.0.0.1', port, 'wrong');
    const badProbe = await badClient.probe();
    assert.equal(badProbe.state, 'unauthorized');

    // 2. Valid token -> online + accounts + signin flow
    const client = new CoreClient('127.0.0.1', port, expectedToken);
    const okProbe = await client.probe();
    assert.equal(okProbe.state, 'online');
    assert.equal(okProbe.status.proxy.country_code, 'nl');

    const accs = await client.getAccounts();
    assert.equal(accs.accounts.length, 1);
    assert.equal(accs.accounts[0].email, 'test@example.com');

    const si1 = await client.startSignIn('test@example.com', 'PLACEHOLDER');
    assert.equal(si1.step, 'need_totp');

    const si2 = await client.answerSignIn('si_1', '123456');
    assert.equal(si2.step, 'done');

    await client.setPower(true);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});

// ----------------------------------------------------
// 6. DOM Element IDs Consistency
// ----------------------------------------------------
console.log('\n--- 6. DOM Element & Script Consistency ---');

function checkDomIds(htmlFile, jsFile) {
  const html = fs.readFileSync(path.join(EXT_DIR, htmlFile), 'utf8');
  const js = fs.readFileSync(path.join(EXT_DIR, jsFile), 'utf8');
  const regex = /\$\(['"]([^'"]+)['"]\)|document\.getElementById\(['"]([^'"]+)['"]\)/g;
  let m;
  const ids = new Set();
  while ((m = regex.exec(js)) !== null) {
    ids.add(m[1] || m[2]);
  }
  assert.ok(ids.size > 0);
  for (const id of ids) {
    assert.ok(html.includes(`id="${id}"`) || html.includes(`id='${id}'`), `Missing id="${id}" in ${htmlFile}`);
  }
}

test('All DOM IDs in popup.js exist in popup.html', () => checkDomIds('popup.html', 'popup.js'));
test('All DOM IDs in options.js exist in options.html', () => checkDomIds('options.html', 'options.js'));

console.log('\n====================================================');
console.log(`📊 Test Results: ${passedTests} / ${totalTests} tests passed`);
console.log('====================================================\n');
