/**
 * TeroVPN Chrome Extension - Core REST API Client & Mozilla Remote Settings Fetcher
 * Matches app/lib/core/core_api.dart endpoints and contracts.
 * Version: 1.2.0
 */

const MOZILLA_SERVERLIST_URL =
  'https://firefox.settings.services.mozilla.com/v1/buckets/main/collections/vpn-serverlist/records';

export class CoreApiError extends Error {
  constructor(status, message, code = '') {
    super(message);
    this.name = 'CoreApiError';
    this.status = status;
    this.code = code;
  }
}

export class CoreClient {
  constructor(host = '127.0.0.1', port = 10820, token = '') {
    this.host = host;
    this.port = port;
    this.token = token;
  }

  get baseUrl() {
    return `http://${this.host}:${this.port}`;
  }

  async request(method, path, body = null, timeoutMs = 4000) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    const headers = {
      Accept: 'application/json'
    };
    if (this.token) {
      headers['X-Local-Token'] = this.token;
    }
    if (body !== null) {
      headers['Content-Type'] = 'application/json';
    }

    try {
      const res = await fetch(`${this.baseUrl}${path}`, {
        method,
        headers,
        body: body !== null ? JSON.stringify(body) : undefined,
        signal: controller.signal,
        cache: 'no-store'
      });
      clearTimeout(timer);

      const text = await res.text();
      let data = {};
      if (text) {
        try {
          data = JSON.parse(text);
        } catch (_) {
          data = { raw: text };
        }
      }

      if (!res.ok) {
        const msg = data.error || data.message || `HTTP ${res.status}`;
        throw new CoreApiError(res.status, msg, data.code || '');
      }
      return data;
    } catch (err) {
      clearTimeout(timer);
      if (err instanceof CoreApiError) throw err;
      throw new CoreApiError(0, err.name === 'AbortError' ? 'Core connection timed out' : err.message, 'unreachable');
    }
  }

  /**
   * Probes whether the Core is running, and whether the token is valid.
   * Returns: { state: 'online'|'unauthorized'|'offline', status?: object, error?: string }
   */
  async probe() {
    try {
      const status = await this.request('GET', '/api/status', null, 1500);
      return { state: 'online', status };
    } catch (err) {
      if (err.status === 401 || err.status === 403) {
        return { state: 'unauthorized', error: 'Invalid or missing X-Local-Token' };
      }
      return { state: 'offline', error: err.message };
    }
  }

  getStatus() {
    return this.request('GET', '/api/status');
  }

  getAccounts() {
    return this.request('GET', '/api/accounts');
  }

  getLocations() {
    return this.request('GET', '/api/locations');
  }

  pingLocations() {
    return this.request('POST', '/api/locations/ping', {}, 15000);
  }

  setPower(on) {
    return this.request('POST', '/api/power', { on: Boolean(on) }, 8000);
  }

  testConnection() {
    return this.request('POST', '/api/test', {}, 15000);
  }

  async getSettings() {
    const view = await this.request('GET', '/api/settings');
    return view.config || {};
  }

  saveSettings(config) {
    return this.request('PUT', '/api/settings', { config });
  }

  setSystemProxy(mode) {
    return this.request('POST', '/api/system-proxy', { mode });
  }

  // ---- Authentication / Sign-In Flow ----
  startSignIn(email, password) {
    return this.request('POST', '/api/signin', { email, password }, 20000);
  }

  startSignInAgain(accountId) {
    return this.request('POST', '/api/signin', { account_id: accountId }, 20000);
  }

  getSignInState(id) {
    return this.request('GET', `/api/signin/${encodeURIComponent(id)}`, null, 10000);
  }

  answerSignIn(id, value) {
    return this.request('POST', `/api/signin/${encodeURIComponent(id)}`, { value }, 20000);
  }

  cancelSignIn(id) {
    return this.request('DELETE', `/api/signin/${encodeURIComponent(id)}`);
  }

  // ---- Account Pool Management ----
  activateAccount(id) {
    return this.request('POST', `/api/accounts/${encodeURIComponent(id)}/activate`, {});
  }

  setAccountEnabled(id, enabled) {
    return this.request('POST', `/api/accounts/${encodeURIComponent(id)}/enabled`, { enabled: Boolean(enabled) });
  }

  refreshAccount(id) {
    return this.request('POST', `/api/accounts/${encodeURIComponent(id)}/refresh`, {}, 15000);
  }

  removeAccount(id) {
    return this.request('DELETE', `/api/accounts/${encodeURIComponent(id)}`);
  }
}

/**
 * Fetches the live Mozilla Remote Settings VPN server list.
 */
export async function fetchMozillaServerList() {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 5000);
  try {
    const res = await fetch(MOZILLA_SERVERLIST_URL, {
      signal: controller.signal,
      cache: 'no-store'
    });
    clearTimeout(timer);
    if (!res.ok) return null;
    const json = await res.json();
    const records = Array.isArray(json.data) ? json.data : [];
    const locations = [];
    for (const rec of records) {
      if (!rec.code || rec.code === 'REC') continue;
      const cities = Array.isArray(rec.cities) ? rec.cities : [];
      const firstCity = cities[0] || {};
      const servers = Array.isArray(firstCity.servers) ? firstCity.servers : [];
      const firstServer = servers[0] || {};
      locations.push({
        code: String(rec.code).toLowerCase(),
        name: rec.name || rec.code,
        city: firstCity.name || '',
        server: firstServer.hostname || '',
        recommended: Boolean(rec.recommended),
        ping_ms: 0
      });
    }
    return locations;
  } catch (_) {
    clearTimeout(timer);
    return null;
  }
}
