/**
 * TeroVPN Chrome Extension - Proxy Configuration Generator
 * Version: 1.2.0
 */

export const DEFAULT_BYPASS_LIST = [
  '<local>',
  'localhost',
  '127.0.0.1',
  '::1',
  '10.0.0.0/8',
  '172.16.0.0/12',
  '192.168.0.0/16',
  '*.local'
];

/**
 * Generates Chrome ProxySettings for local TeroVPN desktop core.
 * Default desktop core listen port is 10810 (SOCKS5/HTTP).
 */
export function buildDesktopCoreProxyConfig(host = '127.0.0.1', port = 10810, bypassLocal = true) {
  const bypass = bypassLocal ? DEFAULT_BYPASS_LIST : ['<local>'];
  
  // PAC script ensures both HTTP and HTTPS route via local core without certificate warnings
  const pacData = `
    function FindProxyForURL(url, host) {
      if (${bypassLocal ? 'isPlainHostName(host) || shExpMatch(host, "*.local") || shExpMatch(host, "localhost") || shExpMatch(host, "127.*") || isInNet(dnsResolve(host), "10.0.0.0", "255.0.0.0") || isInNet(dnsResolve(host), "172.16.0.0", "255.240.0.0") || isInNet(dnsResolve(host), "192.168.0.0", "255.255.0.0")' : 'false'}) {
        return "DIRECT";
      }
      return "SOCKS5 ${host}:${port}; PROXY ${host}:${port}; DIRECT";
    }
  `.trim();

  return {
    mode: 'pac_script',
    pacScript: {
      data: pacData,
      mandatory: false
    }
  };
}

/**
 * Generates Chrome ProxySettings for standalone / cloud relay proxy server.
 */
export function buildRelayProxyConfig(server, bypassLocal = true) {
  const scheme = (server.scheme || 'https').toLowerCase();
  const host = server.host;
  const port = server.port || 443;
  const bypass = bypassLocal ? DEFAULT_BYPASS_LIST : ['<local>'];

  if (scheme === 'socks5') {
    return {
      mode: 'fixed_servers',
      rules: {
        singleProxy: {
          scheme: 'socks5',
          host: host,
          port: Number(port)
        },
        bypassList: bypass
      }
    };
  }

  // HTTPS / HTTP PAC script with graceful fallback
  const proxyDirective = scheme === 'https'
    ? `HTTPS ${host}:${port}; PROXY ${host}:${port}; DIRECT`
    : `PROXY ${host}:${port}; DIRECT`;

  const pacData = `
    function FindProxyForURL(url, host) {
      if (${bypassLocal ? 'isPlainHostName(host) || shExpMatch(host, "*.local") || shExpMatch(host, "localhost") || shExpMatch(host, "127.*") || isInNet(dnsResolve(host), "10.0.0.0", "255.0.0.0") || isInNet(dnsResolve(host), "172.16.0.0", "255.240.0.0") || isInNet(dnsResolve(host), "192.168.0.0", "255.255.0.0")' : 'false'}) {
        return "DIRECT";
      }
      return "${proxyDirective}";
    }
  `.trim();

  return {
    mode: 'pac_script',
    pacScript: {
      data: pacData,
      mandatory: false
    }
  };
}

/**
 * Generates direct connection config (VPN/Proxy turned off).
 */
export function buildDirectConfig() {
  return {
    mode: 'direct'
  };
}
