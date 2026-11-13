/**
 * TeroVPN Chrome Extension - E2EE Cross-Device QR Authorization Sync
 * Exact Web Crypto API (AES-256-CBC + HMAC-SHA256) compatible with TeroVPN Mobile & Desktop.
 * Version: 1.2.0
 */

function toBase64Url(bytes) {
  let binary = '';
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function fromBase64(b64) {
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

function fromBase64Url(b64u) {
  let b64 = b64u.replace(/-/g, '+').replace(/_/g, '/');
  while (b64.length % 4 !== 0) b64 += '=';
  return fromBase64(b64);
}

function bytesToHex(bytes) {
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

export async function generateSecureSecretKey() {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return toBase64Url(bytes);
}

export async function generateSessionId(secretKey) {
  const data = new TextEncoder().encode(secretKey);
  const hashBuf = await crypto.subtle.digest('SHA-256', data);
  const hashHex = bytesToHex(new Uint8Array(hashBuf)).substring(0, 16);
  const randBytes = new Uint32Array(1);
  crypto.getRandomValues(randBytes);
  const rand6 = 100000 + (randBytes[0] % 900000);
  return `tero_${hashHex}_${rand6}`;
}

export async function createQrPairingSession() {
  const secretKey = await generateSecureSecretKey();
  const sessionId = await generateSessionId(secretKey);
  const payload = `terovpn://pair?sid=${sessionId}&k=${secretKey}&relay=ntfy.sh&t=${Date.now()}`;
  return {
    sessionId,
    secretKey,
    payload,
    topic: `terovpn_auth_${sessionId}`,
    createdAt: Date.now()
  };
}

export async function encryptPayload(plainObj, secretKey) {
  const keyBytes = fromBase64Url(secretKey);
  const iv = new Uint8Array(16);
  crypto.getRandomValues(iv);

  const aesKey = await crypto.subtle.importKey(
    'raw',
    keyBytes,
    { name: 'AES-CBC' },
    false,
    ['encrypt']
  );
  const plainBytes = new TextEncoder().encode(JSON.stringify(plainObj));
  const cipherBuf = await crypto.subtle.encrypt(
    { name: 'AES-CBC', iv },
    aesKey,
    plainBytes
  );
  const cipherBytes = new Uint8Array(cipherBuf);

  const hmacKey = await crypto.subtle.importKey(
    'raw',
    keyBytes,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const macBuf = await crypto.subtle.sign('HMAC', hmacKey, cipherBytes);
  const macHex = bytesToHex(new Uint8Array(macBuf));

  let cipherB64 = '';
  for (let i = 0; i < cipherBytes.length; i++) cipherB64 += String.fromCharCode(cipherBytes[i]);
  let ivB64 = '';
  for (let i = 0; i < iv.length; i++) ivB64 += String.fromCharCode(iv[i]);

  return {
    e2ee: true,
    cipher: btoa(cipherB64),
    iv: btoa(ivB64),
    mac: macHex
  };
}

export async function decryptPayload(envelope, secretKey) {
  try {
    if (!envelope || !envelope.cipher || !envelope.iv || !envelope.mac) {
      return null;
    }
    const keyBytes = fromBase64Url(secretKey);
    const cipherBytes = fromBase64(envelope.cipher);
    const ivBytes = fromBase64(envelope.iv);

    const hmacKey = await crypto.subtle.importKey(
      'raw',
      keyBytes,
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    );
    const macBuf = await crypto.subtle.sign('HMAC', hmacKey, cipherBytes);
    const computedMac = bytesToHex(new Uint8Array(macBuf));
    if (computedMac !== envelope.mac) {
      return null;
    }

    const aesKey = await crypto.subtle.importKey(
      'raw',
      keyBytes,
      { name: 'AES-CBC' },
      false,
      ['decrypt']
    );
    const plainBuf = await crypto.subtle.decrypt(
      { name: 'AES-CBC', iv: ivBytes },
      aesKey,
      cipherBytes
    );
    const plainText = new TextDecoder().decode(plainBuf);
    return JSON.parse(plainText);
  } catch (err) {
    console.warn('[TeroVPN QR] Decryption failed:', err);
    return null;
  }
}

export async function pollRelayForSession(sessionId, secretKey) {
  const topic = `terovpn_auth_${sessionId}`;
  const url = `https://ntfy.sh/${topic}/json?poll=1&since=all`;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 4500);
  try {
    const res = await fetch(url, { signal: controller.signal, cache: 'no-store' });
    clearTimeout(timer);
    if (!res.ok) return null;
    const text = await res.text();
    if (!text) return null;
    const lines = text.split('\n');
    for (const line of lines) {
      if (!line.trim()) continue;
      try {
        const entry = JSON.parse(line);
        if (entry.event !== 'message' || !entry.message) continue;
        const payload = JSON.parse(entry.message);
        let decrypted = payload;
        if (payload.e2ee === true && payload.cipher) {
          decrypted = await decryptPayload(payload, secretKey);
          if (!decrypted) continue;
        }
        if (decrypted && (decrypted.email || decrypted.account)) {
          return decrypted;
        }
      } catch (_) {}
    }
  } catch (_) {
    clearTimeout(timer);
  }
  return null;
}
