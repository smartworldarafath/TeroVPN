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

function buildPacBypassCondition(bypassLocal, extraBypassDomains = []) {
  const checks = [];
  if (bypassLocal) {
    checks.push(
      'isPlainHostName(host)',
      'shExpMatch(host, "*.local")',
      'shExpMatch(host, "localhost")',
      'shExpMatch(host, "127.*")',
      'isInNet(dnsResolve(host), "10.0.0.0", "255.0.0.0")',
      'isInNet(dnsResolve(host), "172.16.0.0", "255.240.0.0")',
      'isInNet(dnsResolve(host), "192.168.0.0", "255.255.0.0")'
    );
  }
  for (const raw of extraBypassDomains) {
    const domain = String(raw || '').trim();
    if (!domain) continue;
    const escaped = domain.replace(/["\\]/g, '');
    checks.push(`shExpMatch(host, "${escaped}")`);
  }
  return checks.length > 0 ? checks.join(' || ') : 'false';
}

/**
 * Generates Chrome ProxySettings for local TeroVPN desktop core.
 * Default desktop core listen port is 10810 (SOCKS5/HTTP).
 */
export function buildDesktopCoreProxyConfig(
  host = '127.0.0.1',
  port = 10810,
  bypassLocal = true,
  extraBypassDomains = []
) {
  const condition = buildPacBypassCondition(bypassLocal, extraBypassDomains);
  const pacData = `
    function FindProxyForURL(url, host) {
      if (${condition}) {
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
 * Generates Chrome ProxySettings for a user-configured custom proxy server.
 */
export function buildRelayProxyConfig(server, bypassLocal = true, extraBypassDomains = []) {
  const scheme = (server.scheme || 'https').toLowerCase();
  const host = server.host;
  const port = Number(server.port) || 443;
  const bypass = [
    ...(bypassLocal ? DEFAULT_BYPASS_LIST : ['<local>']),
    ...extraBypassDomains.map((d) => String(d || '').trim()).filter(Boolean)
  ];

  if (scheme === 'socks5') {
    return {
      mode: 'fixed_servers',
      rules: {
        singleProxy: {
          scheme: 'socks5',
          host,
          port
        },
        bypassList: bypass
      }
    };
  }

  const proxyDirective = scheme === 'https'
    ? `HTTPS ${host}:${port}; PROXY ${host}:${port}; DIRECT`
    : `PROXY ${host}:${port}; DIRECT`;

  const condition = buildPacBypassCondition(bypassLocal, extraBypassDomains);
  const pacData = `
    function FindProxyForURL(url, host) {
      if (${condition}) {
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
