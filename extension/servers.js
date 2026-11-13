/**
 * TeroVPN Chrome Extension - Global Server Network Definition
 * Version: 1.2.0
 */

export const SERVERS = [
  {
    id: 'nl-ams-01',
    countryCode: 'nl',
    countryName: 'Netherlands',
    cityName: 'Amsterdam',
    region: 'Europe',
    defaultPing: 18,
    pingUrl: 'https://speed.cloudflare.com/__down?bytes=0',
    host: 'nl.relay.terovpn.net',
    port: 443,
    scheme: 'https',
    features: ['P2P', 'WireGuard/MASQUE', 'No-Logs']
  },
  {
    id: 'de-fra-01',
    countryCode: 'de',
    countryName: 'Germany',
    cityName: 'Frankfurt',
    region: 'Europe',
    defaultPing: 22,
    pingUrl: 'https://de.speedtest.net',
    host: 'de.relay.terovpn.net',
    port: 443,
    scheme: 'https',
    features: ['P2P', 'Streaming', 'Anti-DPI']
  },
  {
    id: 'us-nyc-01',
    countryCode: 'us',
    countryName: 'United States',
    cityName: 'New York',
    region: 'North America',
    defaultPing: 32,
    pingUrl: 'https://us.speedtest.net',
    host: 'us-east.relay.terovpn.net',
    port: 443,
    scheme: 'https',
    features: ['Streaming', 'High-Speed', 'No-Logs']
  },
  {
    id: 'us-lax-01',
    countryCode: 'us',
    countryName: 'United States',
    cityName: 'Los Angeles',
    region: 'North America',
    defaultPing: 45,
    pingUrl: 'https://us-west.speedtest.net',
    host: 'us-west.relay.terovpn.net',
    port: 443,
    scheme: 'https',
    features: ['Streaming', 'Gaming', 'No-Logs']
  },
  {
    id: 'gb-lon-01',
    countryCode: 'gb',
    countryName: 'United Kingdom',
    cityName: 'London',
    region: 'Europe',
    defaultPing: 24,
    pingUrl: 'https://uk.speedtest.net',
    host: 'gb.relay.terovpn.net',
    port: 443,
    scheme: 'https',
    features: ['Streaming', 'BBC iPlayer', 'No-Logs']
  },
  {
    id: 'jp-tyo-01',
    countryCode: 'jp',
    countryName: 'Japan',
    cityName: 'Tokyo',
    region: 'Asia Pacific',
    defaultPing: 48,
    pingUrl: 'https://jp.speedtest.net',
    host: 'jp.relay.terovpn.net',
    port: 443,
    scheme: 'https',
    features: ['Anime', 'Low-Latency', 'No-Logs']
  },
  {
    id: 'sg-sin-01',
    countryCode: 'sg',
    countryName: 'Singapore',
    cityName: 'Singapore',
    region: 'Asia Pacific',
    defaultPing: 29,
    pingUrl: 'https://sg.speedtest.net',
    host: 'sg.relay.terovpn.net',
    port: 443,
    scheme: 'https',
    features: ['Gaming', 'Fiber-Speed', 'No-Logs']
  },
  {
    id: 'ca-tor-01',
    countryCode: 'ca',
    countryName: 'Canada',
    cityName: 'Toronto',
    region: 'North America',
    defaultPing: 35,
    pingUrl: 'https://ca.speedtest.net',
    host: 'ca.relay.terovpn.net',
    port: 443,
    scheme: 'https',
    features: ['P2P', 'Streaming', 'No-Logs']
  },
  {
    id: 'ch-zrh-01',
    countryCode: 'ch',
    countryName: 'Switzerland',
    cityName: 'Zurich',
    region: 'Europe',
    defaultPing: 26,
    pingUrl: 'https://ch.speedtest.net',
    host: 'ch.relay.terovpn.net',
    port: 443,
    scheme: 'https',
    features: ['Maximum Privacy', 'Swiss Law', 'No-Logs']
  },
  {
    id: 'fr-par-01',
    countryCode: 'fr',
    countryName: 'France',
    cityName: 'Paris',
    region: 'Europe',
    defaultPing: 25,
    pingUrl: 'https://fr.speedtest.net',
    host: 'fr.relay.terovpn.net',
    port: 443,
    scheme: 'https',
    features: ['Streaming', 'No-Logs']
  },
  {
    id: 'se-sto-01',
    countryCode: 'se',
    countryName: 'Sweden',
    cityName: 'Stockholm',
    region: 'Europe',
    defaultPing: 28,
    pingUrl: 'https://se.speedtest.net',
    host: 'se.relay.terovpn.net',
    port: 443,
    scheme: 'https',
    features: ['High Privacy', 'No-Logs']
  },
  {
    id: 'bd-dac-01',
    countryCode: 'bd',
    countryName: 'Bangladesh',
    cityName: 'Dhaka',
    region: 'South Asia',
    defaultPing: 12,
    pingUrl: 'https://bd.speedtest.net',
    host: 'bd.relay.terovpn.net',
    port: 443,
    scheme: 'https',
    features: ['Local Access', 'BDIX Direct', 'No-Logs']
  },
  {
    id: 'au-syd-01',
    countryCode: 'au',
    countryName: 'Australia',
    cityName: 'Sydney',
    region: 'Oceania',
    defaultPing: 65,
    pingUrl: 'https://au.speedtest.net',
    host: 'au.relay.terovpn.net',
    port: 443,
    scheme: 'https',
    features: ['Streaming', 'No-Logs']
  },
  {
    id: 'kr-seo-01',
    countryCode: 'kr',
    countryName: 'South Korea',
    cityName: 'Seoul',
    region: 'Asia Pacific',
    defaultPing: 42,
    pingUrl: 'https://kr.speedtest.net',
    host: 'kr.relay.terovpn.net',
    port: 443,
    scheme: 'https',
    features: ['Ultra-Speed', 'Gaming', 'No-Logs']
  }
];

export function getDefaultServer() {
  return SERVERS[0]; // Netherlands
}

export function getServerById(id) {
  return SERVERS.find(s => s.id === id) || getDefaultServer();
}

export function getFlagUrl(countryCode) {
  const code = (countryCode || 'nl').toLowerCase();
  return `flags/${code}.svg`;
}
