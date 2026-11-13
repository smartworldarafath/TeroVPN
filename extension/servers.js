/**
 * TeroVPN Chrome Extension - Locations, Profiles & DNS Presets
 * Matches TeroVPN Desktop & Mobile app configurations.
 * Version: 1.2.0
 */

export const DEFAULT_LOCATIONS = [
  { code: 'nl', name: 'Netherlands', city: 'Amsterdam', region: 'Europe', recommended: true, ping_ms: 0 },
  { code: 'de', name: 'Germany', city: 'Frankfurt', region: 'Europe', recommended: false, ping_ms: 0 },
  { code: 'us', name: 'United States', city: 'New York', region: 'North America', recommended: false, ping_ms: 0 },
  { code: 'gb', name: 'United Kingdom', city: 'London', region: 'Europe', recommended: false, ping_ms: 0 },
  { code: 'jp', name: 'Japan', city: 'Tokyo', region: 'Asia Pacific', recommended: false, ping_ms: 0 },
  { code: 'sg', name: 'Singapore', city: 'Singapore', region: 'Asia Pacific', recommended: false, ping_ms: 0 },
  { code: 'ca', name: 'Canada', city: 'Toronto', region: 'North America', recommended: false, ping_ms: 0 },
  { code: 'ch', name: 'Switzerland', city: 'Zurich', region: 'Europe', recommended: false, ping_ms: 0 },
  { code: 'fr', name: 'France', city: 'Paris', region: 'Europe', recommended: false, ping_ms: 0 },
  { code: 'se', name: 'Sweden', city: 'Stockholm', region: 'Europe', recommended: false, ping_ms: 0 },
  { code: 'no', name: 'Norway', city: 'Oslo', region: 'Europe', recommended: false, ping_ms: 0 },
  { code: 'fi', name: 'Finland', city: 'Helsinki', region: 'Europe', recommended: false, ping_ms: 0 },
  { code: 'au', name: 'Australia', city: 'Sydney', region: 'Oceania', recommended: false, ping_ms: 0 },
  { code: 'kr', name: 'South Korea', city: 'Seoul', region: 'Asia Pacific', recommended: false, ping_ms: 0 },
  { code: 'br', name: 'Brazil', city: 'Sao Paulo', region: 'South America', recommended: false, ping_ms: 0 },
  { code: 'es', name: 'Spain', city: 'Madrid', region: 'Europe', recommended: false, ping_ms: 0 },
  { code: 'it', name: 'Italy', city: 'Milan', region: 'Europe', recommended: false, ping_ms: 0 },
  { code: 'bd', name: 'Bangladesh', city: 'Dhaka', region: 'South Asia', recommended: false, ping_ms: 0 }
];

export const PROFILES = [
  {
    id: 'fastest',
    name: 'Fastest',
    subtitle: 'Lowest latency exit node',
    countryCode: 'auto',
    transport: 'auto',
    icon: 'bolt',
    color: '#10B981'
  },
  {
    id: 'random',
    name: 'Random',
    subtitle: 'Randomized global exit route',
    countryCode: 'random',
    transport: 'auto',
    icon: 'shuffle',
    color: '#8B5CF6'
  },
  {
    id: 'streaming',
    name: 'Streaming',
    subtitle: 'US High-Throughput 4K route',
    countryCode: 'us',
    transport: 'h2',
    icon: 'play',
    color: '#3B82F6'
  },
  {
    id: 'gaming',
    name: 'Gaming',
    subtitle: 'Low-jitter Singapore QUIC route',
    countryCode: 'sg',
    transport: 'h3',
    icon: 'gamepad',
    color: '#F59E0B'
  },
  {
    id: 'privacy',
    name: 'Secure Core',
    subtitle: 'Swiss privacy jurisdiction',
    countryCode: 'ch',
    transport: 'h3',
    icon: 'shield',
    color: '#00F0FF'
  }
];

export const DNS_PRESETS = [
  { id: 'system', name: 'System / Default', address: '' },
  { id: 'cloudflare', name: 'Cloudflare (1.1.1.1)', address: 'https://cloudflare-dns.com/dns-query' },
  { id: 'google', name: 'Google (8.8.8.8)', address: 'https://dns.google/dns-query' },
  { id: 'quad9', name: 'Quad9 Security (9.9.9.9)', address: 'https://dns.quad9.net/dns-query' },
  { id: 'adguard', name: 'AdGuard AdBlock', address: 'https://dns.adguard-dns.com/dns-query' }
];

const SUPPORTED_FLAGS = new Set([
  'ar', 'at', 'au', 'bd', 'be', 'bg', 'br', 'ca', 'ch', 'cl', 'co', 'de',
  'dk', 'es', 'fi', 'fr', 'gb', 'gh', 'ie', 'is', 'it', 'jp', 'kr', 'mx',
  'my', 'nl', 'no', 'nz', 'pe', 'ph', 'pt', 'se', 'sg', 'th', 'us', 'za'
]);

export function getFlagUrl(countryCode) {
  const code = (countryCode || 'nl').toLowerCase();
  if (SUPPORTED_FLAGS.has(code)) {
    return `flags/${code}.svg`;
  }
  return 'flags/nl.svg';
}

export function getLocationByCode(code, list = DEFAULT_LOCATIONS) {
  const c = (code || '').toLowerCase();
  return list.find((l) => l.code.toLowerCase() === c) || list[0] || DEFAULT_LOCATIONS[0];
}
