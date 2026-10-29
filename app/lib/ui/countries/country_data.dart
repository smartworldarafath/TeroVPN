class CountryItem {
  final String code;
  final String name;
  final String cities;
  final int load;
  final int pingMs;
  final bool isP2p;
  final bool isSecureCore;
  final bool isTor;

  const CountryItem({
    required this.code,
    required this.name,
    required this.cities,
    required this.load,
    required this.pingMs,
    this.isP2p = true,
    this.isSecureCore = false,
    this.isTor = false,
  });
}

const List<CountryItem> kFastlyCountries = [
  CountryItem(code: 'AR', name: 'Argentina', cities: 'Buenos Aires', load: 45, pingMs: 140),
  CountryItem(code: 'AU', name: 'Australia', cities: 'Sydney, Melbourne, Perth', load: 38, pingMs: 175),
  CountryItem(code: 'AT', name: 'Austria', cities: 'Vienna', load: 28, pingMs: 32, isSecureCore: true),
  CountryItem(code: 'BE', name: 'Belgium', cities: 'Brussels', load: 35, pingMs: 22),
  CountryItem(code: 'BR', name: 'Brazil', cities: 'São Paulo, Rio de Janeiro', load: 62, pingMs: 130),
  CountryItem(code: 'BG', name: 'Bulgaria', cities: 'Sofia', load: 24, pingMs: 48),
  CountryItem(code: 'CA', name: 'Canada', cities: 'Toronto, Montreal, Vancouver', load: 42, pingMs: 88, isSecureCore: true),
  CountryItem(code: 'CL', name: 'Chile', cities: 'Santiago', load: 55, pingMs: 155),
  CountryItem(code: 'CO', name: 'Colombia', cities: 'Bogotá', load: 58, pingMs: 125),
  CountryItem(code: 'DK', name: 'Denmark', cities: 'Copenhagen', load: 31, pingMs: 25),
  CountryItem(code: 'FI', name: 'Finland', cities: 'Helsinki', load: 22, pingMs: 29),
  CountryItem(code: 'FR', name: 'France', cities: 'Paris, Marseille', load: 48, pingMs: 19, isSecureCore: true),
  CountryItem(code: 'DE', name: 'Germany', cities: 'Frankfurt, Berlin, Munich', load: 54, pingMs: 24, isSecureCore: true, isTor: true),
  CountryItem(code: 'GH', name: 'Ghana', cities: 'Accra', load: 40, pingMs: 160),
  CountryItem(code: 'IE', name: 'Ireland', cities: 'Dublin', load: 29, pingMs: 28),
  CountryItem(code: 'IT', name: 'Italy', cities: 'Milan, Rome', load: 46, pingMs: 35),
  CountryItem(code: 'JP', name: 'Japan', cities: 'Tokyo, Osaka', load: 51, pingMs: 190, isSecureCore: true),
  CountryItem(code: 'MY', name: 'Malaysia', cities: 'Kuala Lumpur', load: 39, pingMs: 185),
  CountryItem(code: 'MX', name: 'Mexico', cities: 'Mexico City, Querétaro', load: 60, pingMs: 110),
  CountryItem(code: 'NL', name: 'Netherlands', cities: 'Amsterdam', load: 32, pingMs: 18, isSecureCore: true, isTor: true),
  CountryItem(code: 'NZ', name: 'New Zealand', cities: 'Auckland', load: 36, pingMs: 195),
  CountryItem(code: 'NO', name: 'Norway', cities: 'Oslo', load: 25, pingMs: 27),
  CountryItem(code: 'PE', name: 'Peru', cities: 'Lima', load: 53, pingMs: 145),
  CountryItem(code: 'PH', name: 'Philippines', cities: 'Manila', load: 64, pingMs: 205),
  CountryItem(code: 'PT', name: 'Portugal', cities: 'Lisbon', load: 33, pingMs: 38),
  CountryItem(code: 'SG', name: 'Singapore', cities: 'Singapore', load: 47, pingMs: 170, isSecureCore: true),
  CountryItem(code: 'ZA', name: 'South Africa', cities: 'Johannesburg, Cape Town', load: 44, pingMs: 180),
  CountryItem(code: 'KR', name: 'South Korea', cities: 'Seoul', load: 49, pingMs: 200),
  CountryItem(code: 'ES', name: 'Spain', cities: 'Madrid, Barcelona', load: 43, pingMs: 34),
  CountryItem(code: 'SE', name: 'Sweden', cities: 'Stockholm', load: 27, pingMs: 26, isSecureCore: true, isTor: true),
  CountryItem(code: 'TH', name: 'Thailand', cities: 'Bangkok', load: 52, pingMs: 190),
  CountryItem(code: 'GB', name: 'United Kingdom', cities: 'London, Manchester', load: 56, pingMs: 21, isSecureCore: true),
  CountryItem(code: 'US', name: 'United States', cities: 'New York, Los Angeles, Chicago, Miami, Dallas', load: 68, pingMs: 82, isSecureCore: true, isTor: true),
];
