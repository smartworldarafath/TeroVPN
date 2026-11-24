import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../components/country_flag.dart';

class CountryCoordinates {
  final double lat;
  final double lng;
  final String code;
  final String name;
  final String city;

  const CountryCoordinates({
    required this.lat,
    required this.lng,
    required this.code,
    required this.name,
    required this.city,
  });
}

const Map<String, CountryCoordinates> kCountryLocations = {
  'BD': CountryCoordinates(lat: 23.8103, lng: 90.4125, code: 'BD', name: 'Bangladesh', city: 'Dhaka'),
  'NL': CountryCoordinates(lat: 52.3676, lng: 4.9041, code: 'NL', name: 'Netherlands', city: 'Amsterdam'),
  'DE': CountryCoordinates(lat: 50.1109, lng: 8.6821, code: 'DE', name: 'Germany', city: 'Frankfurt'),
  'US': CountryCoordinates(lat: 39.8283, lng: -98.5795, code: 'US', name: 'United States', city: 'New York'),
  'GB': CountryCoordinates(lat: 52.3555, lng: -1.1743, code: 'GB', name: 'United Kingdom', city: 'London'),
  'CH': CountryCoordinates(lat: 46.8182, lng: 8.2275, code: 'CH', name: 'Switzerland', city: 'Zurich'),
  'JP': CountryCoordinates(lat: 36.2048, lng: 138.2529, code: 'JP', name: 'Japan', city: 'Tokyo'),
  'SG': CountryCoordinates(lat: 1.3521, lng: 103.8198, code: 'SG', name: 'Singapore', city: 'Singapore'),
  'CA': CountryCoordinates(lat: 56.1304, lng: -106.3468, code: 'CA', name: 'Canada', city: 'Toronto'),
  'FR': CountryCoordinates(lat: 46.2276, lng: 2.2137, code: 'FR', name: 'France', city: 'Paris'),
  'SE': CountryCoordinates(lat: 60.1282, lng: 18.6435, code: 'SE', name: 'Sweden', city: 'Stockholm'),
  'NO': CountryCoordinates(lat: 60.4720, lng: 8.4689, code: 'NO', name: 'Norway', city: 'Oslo'),
  'FI': CountryCoordinates(lat: 61.9241, lng: 25.7482, code: 'FI', name: 'Finland', city: 'Helsinki'),
  'AU': CountryCoordinates(lat: -25.2744, lng: 133.7751, code: 'AU', name: 'Australia', city: 'Sydney'),
  'IS': CountryCoordinates(lat: 64.9631, lng: -19.0208, code: 'IS', name: 'Iceland', city: 'Reykjavik'),
  'ES': CountryCoordinates(lat: 40.4637, lng: -3.7492, code: 'ES', name: 'Spain', city: 'Madrid'),
  'IT': CountryCoordinates(lat: 41.8719, lng: 12.5674, code: 'IT', name: 'Italy', city: 'Milan'),
  'BR': CountryCoordinates(lat: -14.2350, lng: -51.9253, code: 'BR', name: 'Brazil', city: 'São Paulo'),
  'IN': CountryCoordinates(lat: 20.5937, lng: 78.9629, code: 'IN', name: 'India', city: 'Mumbai'),
  'KR': CountryCoordinates(lat: 35.9078, lng: 127.7669, code: 'KR', name: 'South Korea', city: 'Seoul'),
  'HK': CountryCoordinates(lat: 22.3193, lng: 114.1694, code: 'HK', name: 'Hong Kong', city: 'Hong Kong'),
  'TW': CountryCoordinates(lat: 23.6978, lng: 120.9605, code: 'TW', name: 'Taiwan', city: 'Taipei'),
  'AT': CountryCoordinates(lat: 47.5162, lng: 14.5501, code: 'AT', name: 'Austria', city: 'Vienna'),
  'BE': CountryCoordinates(lat: 50.5039, lng: 4.4699, code: 'BE', name: 'Belgium', city: 'Brussels'),
  'DK': CountryCoordinates(lat: 56.2639, lng: 9.5018, code: 'DK', name: 'Denmark', city: 'Copenhagen'),
  'IE': CountryCoordinates(lat: 53.1424, lng: -7.6921, code: 'IE', name: 'Ireland', city: 'Dublin'),
  'PL': CountryCoordinates(lat: 51.9194, lng: 19.1451, code: 'PL', name: 'Poland', city: 'Warsaw'),
  'PT': CountryCoordinates(lat: 39.3999, lng: -8.2245, code: 'PT', name: 'Portugal', city: 'Lisbon'),
  'CZ': CountryCoordinates(lat: 49.8175, lng: 15.4730, code: 'CZ', name: 'Czechia', city: 'Prague'),
  'RO': CountryCoordinates(lat: 45.9432, lng: 24.9668, code: 'RO', name: 'Romania', city: 'Bucharest'),
  'BG': CountryCoordinates(lat: 42.7339, lng: 25.4858, code: 'BG', name: 'Bulgaria', city: 'Sofia'),
  'HU': CountryCoordinates(lat: 47.1625, lng: 19.5033, code: 'HU', name: 'Hungary', city: 'Budapest'),
  'UA': CountryCoordinates(lat: 48.3794, lng: 31.1656, code: 'UA', name: 'Ukraine', city: 'Kyiv'),
  'MX': CountryCoordinates(lat: 23.6345, lng: -102.5528, code: 'MX', name: 'Mexico', city: 'Mexico City'),
  'AR': CountryCoordinates(lat: -38.4161, lng: -63.6167, code: 'AR', name: 'Argentina', city: 'Buenos Aires'),
  'CL': CountryCoordinates(lat: -35.6751, lng: -71.5430, code: 'CL', name: 'Chile', city: 'Santiago'),
  'CO': CountryCoordinates(lat: 4.5709, lng: -74.2973, code: 'CO', name: 'Colombia', city: 'Bogotá'),
  'ZA': CountryCoordinates(lat: -30.5595, lng: 22.9375, code: 'ZA', name: 'South Africa', city: 'Johannesburg'),
  'AE': CountryCoordinates(lat: 23.4241, lng: 53.8478, code: 'AE', name: 'United Arab Emirates', city: 'Dubai'),
  'IL': CountryCoordinates(lat: 31.0461, lng: 34.8516, code: 'IL', name: 'Israel', city: 'Tel Aviv'),
  'NZ': CountryCoordinates(lat: -40.9006, lng: 174.8860, code: 'NZ', name: 'New Zealand', city: 'Auckland'),
  'MY': CountryCoordinates(lat: 4.2105, lng: 101.9758, code: 'MY', name: 'Malaysia', city: 'Kuala Lumpur'),
  'ID': CountryCoordinates(lat: -0.7893, lng: 113.9213, code: 'ID', name: 'Indonesia', city: 'Jakarta'),
  'TH': CountryCoordinates(lat: 15.8700, lng: 100.9925, code: 'TH', name: 'Thailand', city: 'Bangkok'),
};

class _MapPolygon {
  final String code;
  final String label;
  final double labelLat;
  final double labelLng;
  final List<Offset> points; // (lng, lat)

  const _MapPolygon({
    required this.code,
    required this.label,
    required this.labelLat,
    required this.labelLng,
    required this.points,
  });
}

const List<_MapPolygon> _kWorldPolygons = [
  // South & Southeast Asia (detailed around Bangladesh for disconnected view & Singapore for connected view)
  _MapPolygon(
    code: 'BD',
    label: 'BANGLADESH',
    labelLat: 23.8,
    labelLng: 90.3,
    points: [
      Offset(88.0, 26.6),
      Offset(89.8, 26.2),
      Offset(92.4, 25.1),
      Offset(92.6, 21.0),
      Offset(91.8, 20.8),
      Offset(91.2, 22.2),
      Offset(89.1, 21.6),
      Offset(88.1, 24.4),
    ],
  ),
  _MapPolygon(
    code: 'IN',
    label: 'INDIA',
    labelLat: 22.8,
    labelLng: 79.5,
    points: [
      Offset(68.2, 23.5),
      Offset(74.5, 34.2),
      Offset(80.1, 30.2),
      Offset(88.0, 27.5),
      Offset(96.5, 28.2),
      Offset(94.2, 23.5),
      Offset(88.2, 21.5),
      Offset(80.2, 13.0),
      Offset(77.5, 8.1),
      Offset(72.8, 19.0),
    ],
  ),
  _MapPolygon(
    code: 'MM',
    label: 'MYANMAR (BURMA)',
    labelLat: 21.2,
    labelLng: 96.2,
    points: [
      Offset(92.2, 21.0),
      Offset(94.2, 26.8),
      Offset(98.5, 28.0),
      Offset(101.1, 21.5),
      Offset(98.5, 10.2),
      Offset(94.2, 16.0),
    ],
  ),
  _MapPolygon(
    code: 'NP',
    label: 'NEPAL',
    labelLat: 28.3,
    labelLng: 84.1,
    points: [
      Offset(80.1, 30.2),
      Offset(88.1, 27.9),
      Offset(88.0, 26.4),
      Offset(80.2, 28.8),
    ],
  ),
  _MapPolygon(
    code: 'BT',
    label: 'BHUTAN',
    labelLat: 27.5,
    labelLng: 90.4,
    points: [
      Offset(88.8, 28.2),
      Offset(92.1, 27.9),
      Offset(92.0, 26.7),
      Offset(88.8, 26.7),
    ],
  ),
  _MapPolygon(
    code: 'TH',
    label: 'THAILAND',
    labelLat: 15.8,
    labelLng: 101.0,
    points: [
      Offset(97.5, 20.2),
      Offset(105.5, 15.2),
      Offset(102.5, 12.0),
      Offset(100.2, 6.5),
      Offset(98.4, 8.2),
    ],
  ),
  _MapPolygon(
    code: 'MY',
    label: 'MALAYSIA',
    labelLat: 4.2,
    labelLng: 102.2,
    points: [
      Offset(100.1, 6.6),
      Offset(103.5, 6.1),
      Offset(104.2, 1.4),
      Offset(101.2, 2.8),
    ],
  ),
  _MapPolygon(
    code: 'SG',
    label: 'SINGAPORE',
    labelLat: 1.35,
    labelLng: 103.82,
    points: [
      Offset(103.6, 1.48),
      Offset(104.05, 1.48),
      Offset(104.05, 1.22),
      Offset(103.6, 1.22),
    ],
  ),
  _MapPolygon(
    code: 'ID',
    label: 'INDONESIA',
    labelLat: -2.2,
    labelLng: 106.5,
    points: [
      Offset(95.3, 5.5),
      Offset(106.0, -5.9),
      Offset(114.5, -8.2),
      Offset(120.0, -2.0),
      Offset(109.2, 1.5),
    ],
  ),
  // East Asia
  _MapPolygon(
    code: 'CN',
    label: 'CHINA',
    labelLat: 34.5,
    labelLng: 104.5,
    points: [
      Offset(75.0, 39.0),
      Offset(96.0, 49.0),
      Offset(134.0, 48.0),
      Offset(122.0, 31.0),
      Offset(114.0, 22.5),
      Offset(98.0, 28.0),
      Offset(80.0, 30.5),
    ],
  ),
  _MapPolygon(
    code: 'JP',
    label: 'JAPAN',
    labelLat: 36.5,
    labelLng: 138.5,
    points: [
      Offset(130.0, 31.5),
      Offset(136.5, 35.0),
      Offset(141.0, 41.0),
      Offset(145.5, 44.0),
      Offset(140.8, 35.5),
      Offset(133.0, 33.0),
    ],
  ),
  _MapPolygon(
    code: 'KR',
    label: 'SOUTH KOREA',
    labelLat: 36.2,
    labelLng: 127.8,
    points: [
      Offset(126.1, 38.2),
      Offset(129.5, 38.0),
      Offset(129.2, 35.0),
      Offset(126.3, 34.5),
    ],
  ),
  // North & South America
  _MapPolygon(
    code: 'CA',
    label: 'CANADA',
    labelLat: 56.0,
    labelLng: -102.0,
    points: [
      Offset(-140.0, 60.0),
      Offset(-130.0, 70.0),
      Offset(-75.0, 62.0),
      Offset(-55.0, 47.0),
      Offset(-76.0, 44.0),
      Offset(-95.0, 49.0),
      Offset(-123.0, 49.0),
    ],
  ),
  _MapPolygon(
    code: 'US',
    label: 'UNITED STATES',
    labelLat: 39.5,
    labelLng: -98.5,
    points: [
      Offset(-124.5, 48.8),
      Offset(-95.0, 49.0),
      Offset(-76.0, 44.0),
      Offset(-67.0, 45.0),
      Offset(-75.5, 35.5),
      Offset(-80.2, 25.2),
      Offset(-83.0, 29.5),
      Offset(-97.0, 26.0),
      Offset(-106.5, 31.8),
      Offset(-117.1, 32.5),
      Offset(-124.2, 40.5),
    ],
  ),
  _MapPolygon(
    code: 'MX',
    label: 'MEXICO',
    labelLat: 23.8,
    labelLng: -102.5,
    points: [
      Offset(-117.0, 32.4),
      Offset(-97.2, 25.8),
      Offset(-87.0, 21.2),
      Offset(-92.2, 14.8),
      Offset(-105.5, 20.0),
    ],
  ),
  _MapPolygon(
    code: 'BR',
    label: 'BRAZIL',
    labelLat: -12.5,
    labelLng: -52.5,
    points: [
      Offset(-70.0, -4.0),
      Offset(-50.0, 2.0),
      Offset(-35.0, -6.0),
      Offset(-40.0, -22.0),
      Offset(-53.0, -33.0),
      Offset(-60.0, -18.0),
    ],
  ),
  _MapPolygon(
    code: 'AR',
    label: 'ARGENTINA',
    labelLat: -36.5,
    labelLng: -64.0,
    points: [
      Offset(-66.0, -22.0),
      Offset(-54.0, -26.0),
      Offset(-58.0, -38.0),
      Offset(-68.0, -54.0),
      Offset(-71.0, -42.0),
    ],
  ),
  // Europe
  _MapPolygon(
    code: 'GB',
    label: 'UNITED KINGDOM',
    labelLat: 54.0,
    labelLng: -2.0,
    points: [
      Offset(-5.5, 58.6),
      Offset(1.8, 52.5),
      Offset(-5.2, 50.0),
      Offset(-4.5, 55.0),
    ],
  ),
  _MapPolygon(
    code: 'IE',
    label: 'IRELAND',
    labelLat: 53.3,
    labelLng: -8.0,
    points: [
      Offset(-10.2, 54.5),
      Offset(-6.0, 54.5),
      Offset(-6.2, 52.0),
      Offset(-10.0, 51.8),
    ],
  ),
  _MapPolygon(
    code: 'FR',
    label: 'FRANCE',
    labelLat: 46.5,
    labelLng: 2.3,
    points: [
      Offset(-4.5, 48.5),
      Offset(2.5, 51.0),
      Offset(7.8, 48.5),
      Offset(7.2, 43.7),
      Offset(3.0, 42.5),
      Offset(-1.8, 43.4),
    ],
  ),
  _MapPolygon(
    code: 'ES',
    label: 'SPAIN',
    labelLat: 40.2,
    labelLng: -3.7,
    points: [
      Offset(-9.2, 43.0),
      Offset(3.2, 42.4),
      Offset(-0.5, 38.0),
      Offset(-5.6, 36.0),
      Offset(-8.8, 37.0),
    ],
  ),
  _MapPolygon(
    code: 'NL',
    label: 'NETHERLANDS',
    labelLat: 52.3,
    labelLng: 5.3,
    points: [
      Offset(3.4, 51.4),
      Offset(4.8, 53.3),
      Offset(7.1, 53.4),
      Offset(6.8, 51.8),
      Offset(5.8, 50.8),
    ],
  ),
  _MapPolygon(
    code: 'BE',
    label: 'BELGIUM',
    labelLat: 50.6,
    labelLng: 4.6,
    points: [
      Offset(2.6, 51.3),
      Offset(5.8, 51.2),
      Offset(6.0, 49.5),
      Offset(3.2, 50.2),
    ],
  ),
  _MapPolygon(
    code: 'DE',
    label: 'GERMANY',
    labelLat: 51.1,
    labelLng: 10.4,
    points: [
      Offset(6.0, 51.8),
      Offset(8.5, 54.8),
      Offset(14.2, 54.0),
      Offset(14.8, 51.0),
      Offset(13.0, 47.6),
      Offset(7.6, 47.6),
    ],
  ),
  _MapPolygon(
    code: 'CH',
    label: 'SWITZERLAND',
    labelLat: 46.8,
    labelLng: 8.2,
    points: [
      Offset(6.0, 46.2),
      Offset(7.6, 47.6),
      Offset(10.4, 47.5),
      Offset(10.2, 46.0),
    ],
  ),
  _MapPolygon(
    code: 'IT',
    label: 'ITALY',
    labelLat: 42.8,
    labelLng: 12.6,
    points: [
      Offset(7.0, 45.8),
      Offset(13.6, 46.5),
      Offset(18.5, 40.2),
      Offset(15.6, 38.0),
      Offset(11.5, 42.0),
    ],
  ),
  _MapPolygon(
    code: 'PL',
    label: 'POLAND',
    labelLat: 52.1,
    labelLng: 19.4,
    points: [
      Offset(14.2, 54.0),
      Offset(23.5, 54.2),
      Offset(24.0, 49.5),
      Offset(15.0, 50.5),
    ],
  ),
  _MapPolygon(
    code: 'SE',
    label: 'SWEDEN',
    labelLat: 61.5,
    labelLng: 16.5,
    points: [
      Offset(11.5, 58.0),
      Offset(15.0, 68.5),
      Offset(23.5, 66.0),
      Offset(18.5, 59.5),
      Offset(13.0, 55.4),
    ],
  ),
  _MapPolygon(
    code: 'NO',
    label: 'NORWAY',
    labelLat: 61.8,
    labelLng: 8.8,
    points: [
      Offset(5.0, 60.0),
      Offset(15.0, 69.0),
      Offset(11.5, 59.0),
      Offset(6.5, 58.0),
    ],
  ),
  _MapPolygon(
    code: 'FI',
    label: 'FINLAND',
    labelLat: 63.5,
    labelLng: 26.5,
    points: [
      Offset(21.0, 60.5),
      Offset(24.0, 68.5),
      Offset(31.0, 65.0),
      Offset(28.0, 60.5),
    ],
  ),
  _MapPolygon(
    code: 'IS',
    label: 'ICELAND',
    labelLat: 64.9,
    labelLng: -19.0,
    points: [
      Offset(-24.0, 65.5),
      Offset(-13.5, 66.2),
      Offset(-14.5, 63.5),
      Offset(-22.8, 63.8),
    ],
  ),
  _MapPolygon(
    code: 'UA',
    label: 'UKRAINE',
    labelLat: 48.8,
    labelLng: 31.5,
    points: [
      Offset(23.5, 51.5),
      Offset(38.0, 50.0),
      Offset(36.0, 46.0),
      Offset(29.5, 46.0),
      Offset(22.5, 48.5),
    ],
  ),
  _MapPolygon(
    code: 'AU',
    label: 'AUSTRALIA',
    labelLat: -25.2,
    labelLng: 134.0,
    points: [
      Offset(114.0, -22.0),
      Offset(131.0, -12.0),
      Offset(146.0, -17.0),
      Offset(153.0, -28.0),
      Offset(147.0, -38.0),
      Offset(130.0, -32.0),
      Offset(115.0, -34.0),
    ],
  ),
];

class ProtonWorldMap extends StatefulWidget {
  final bool isConnected;
  final bool isConnecting;
  final String originCountryCode;
  final String destinationCountryCode;
  final String destinationCountryName;
  final String destinationCityName;
  final String? clientIp;
  final VoidCallback? onMapTap;

  const ProtonWorldMap({
    super.key,
    required this.isConnected,
    this.isConnecting = false,
    this.originCountryCode = 'BD',
    required this.destinationCountryCode,
    this.destinationCountryName = '',
    this.destinationCityName = '',
    this.clientIp,
    this.onMapTap,
  });

  @override
  State<ProtonWorldMap> createState() => _ProtonWorldMapState();
}

class _ProtonWorldMapState extends State<ProtonWorldMap>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulseController;
  bool _maskIp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (_pulseController.isAnimating) {
        _pulseController.stop(canceled: false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    super.dispose();
  }

  CountryCoordinates _resolveCoordinates(String code, {String fallbackName = ''}) {
    final upper = code.trim().toUpperCase();
    if (kCountryLocations.containsKey(upper)) {
      return kCountryLocations[upper]!;
    }
    return CountryCoordinates(
      lat: 52.3676,
      lng: 4.9041,
      code: upper.isEmpty ? 'NL' : upper,
      name: fallbackName.isNotEmpty ? fallbackName : 'Netherlands',
      city: 'Amsterdam',
    );
  }

  double _zoomForCountry(String code, bool isConnected) {
    final upper = code.toUpperCase();
    if (!isConnected) return 5.8; // Detailed regional focus around user's country (Bangladesh)
    switch (upper) {
      case 'US':
      case 'CA':
      case 'BR':
      case 'AU':
      case 'IN':
        return 3.4;
      case 'SG':
      case 'NL':
      case 'CH':
      case 'BE':
      case 'HK':
        return 6.2;
      default:
        return 4.8;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;
        final origin = _resolveCoordinates(widget.originCountryCode);
        final dest = _resolveCoordinates(
          widget.destinationCountryCode,
          fallbackName: widget.destinationCountryName,
        );

        final activeFocus = (widget.isConnected || widget.isConnecting)
            ? dest
            : origin;
        final targetZoom = _zoomForCountry(
          activeFocus.code,
          widget.isConnected || widget.isConnecting,
        );

        final rawIp = (widget.clientIp != null && widget.clientIp!.isNotEmpty)
            ? widget.clientIp!
            : (widget.isConnected ? '146.70.184.22' : '103.112.54.18');
        final displayedIp = _maskIp ? '•••.•••.•••.•••' : rawIp;

        final mapBg = isDark
            ? const Color(0xFF151324)
            : const Color(0xFF1B1830);

        return Container(
          height: 256,
          decoration: BoxDecoration(
            color: mapBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isConnected
                  ? const Color(0xFF1FE5BD).withValues(alpha: 0.38)
                  : (widget.isConnecting
                        ? const Color(0xFFFFB800).withValues(alpha: 0.38)
                        : Colors.white.withValues(alpha: 0.08)),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Smoothly animated camera pan (lat/lng) + zoom transition
              TweenAnimationBuilder<Offset>(
                tween: Tween<Offset>(
                  end: Offset(activeFocus.lng, activeFocus.lat),
                ),
                duration: const Duration(milliseconds: 950),
                curve: Curves.easeInOutCubic,
                builder: (context, cameraLngLat, _) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: targetZoom),
                    duration: const Duration(milliseconds: 950),
                    curve: Curves.easeInOutCubic,
                    builder: (context, zoom, _) {
                      return RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _ProtonFocusedMapPainter(
                                cameraLng: cameraLngLat.dx,
                                cameraLat: cameraLngLat.dy,
                                zoom: zoom,
                                pulseProgress: _pulseController.value,
                                activeCountry: activeFocus,
                                originCountry: origin,
                                isConnected: widget.isConnected,
                                isConnecting: widget.isConnecting,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),

              // Top radial vignette so ProtonVPN status text is ultra-legible
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 118,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF121020).withValues(alpha: 0.92),
                          const Color(0xFF121020).withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ProtonVPN Header Overlay: "Protected" vs "You are unprotected"
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: widget.isConnected
                          ? Row(
                              key: const ValueKey('protected_header'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF1FE5BD,
                                    ).withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.shield_rounded,
                                    color: Color(0xFF1FE5BD),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Protected',
                                  style: TextStyle(
                                    color: Color(0xFF1FE5BD),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            )
                          : widget.isConnecting
                          ? Row(
                              key: const ValueKey('connecting_header'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFFFB800),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Connecting to ${dest.name}...',
                                  style: const TextStyle(
                                    color: Color(0xFFFFB800),
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'You are unprotected',
                              key: ValueKey('unprotected_header'),
                              style: TextStyle(
                                color: Color(0xFFFF6B7A),
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    // Location & IP Pill (ProtonVPN style)
                    GestureDetector(
                      onTap: () => setState(() => _maskIp = !_maskIp),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF211E34).withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CountryFlag(
                              countryCode: activeFocus.code,
                              width: 18,
                              height: 13,
                              borderRadius: 2,
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                '${activeFocus.name} · $displayedIp',
                                style: const TextStyle(
                                  color: Color(0xFFD6D3E6),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              _maskIp
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 14,
                              color: const Color(0xFF9E9AB5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProtonFocusedMapPainter extends CustomPainter {
  final double cameraLng;
  final double cameraLat;
  final double zoom;
  final double pulseProgress;
  final CountryCoordinates activeCountry;
  final CountryCoordinates originCountry;
  final bool isConnected;
  final bool isConnecting;

  static final Map<String, TextPainter> _labelCache = {};

  static TextPainter _cachedLabel(String label, bool isActivePoly) {
    final key = '${isActivePoly ? '1' : '0'}_$label';
    return _labelCache.putIfAbsent(key, () {
      return TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: isActivePoly
                ? Colors.white.withValues(alpha: 0.90)
                : const Color(0xFF7B7599).withValues(alpha: 0.68),
            fontSize: isActivePoly ? 11.5 : 9.5,
            fontWeight: isActivePoly ? FontWeight.w800 : FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  _ProtonFocusedMapPainter({
    required this.cameraLng,
    required this.cameraLat,
    required this.zoom,
    required this.pulseProgress,
    required this.activeCountry,
    required this.originCountry,
    required this.isConnected,
    required this.isConnecting,
  });

  // Converts geographic (lng, lat) to viewport (x, y) centered on (cameraLng, cameraLat)
  // shifted slightly downward so the beacon sits nicely below the top header.
  Offset _project(double lng, double lat, Size size) {
    final centerX = size.width * 0.5;
    final centerY = size.height * 0.62;
    final scale = (size.width / 110.0) * zoom;
    final x = centerX + (lng - cameraLng) * scale;
    final y = centerY - (lat - cameraLat) * scale * 1.12;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Subtle Latitude/Longitude graticule lines (ProtonVPN map style)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;

    for (double lng = -160; lng <= 160; lng += 10) {
      final p1 = _project(lng, -80, size);
      final p2 = _project(lng, 80, size);
      if (p1.dx >= -20 && p1.dx <= size.width + 20) {
        canvas.drawLine(Offset(p1.dx, 0), Offset(p2.dx, size.height), gridPaint);
      }
    }
    for (double lat = -60; lat <= 70; lat += 10) {
      final p1 = _project(-180, lat, size);
      final p2 = _project(180, lat, size);
      if (p1.dy >= -20 && p1.dy <= size.height + 20) {
        canvas.drawLine(Offset(0, p1.dy), Offset(size.width, p2.dy), gridPaint);
      }
    }

    // 2. Country Polygons & Borders
    final inactiveFill = Paint()
      ..color = const Color(0xFF232038)
      ..style = PaintingStyle.fill;

    final activeFill = Paint()
      ..color = isConnected
          ? const Color(0xFF1F383D)
          : (isConnecting
                ? const Color(0xFF332A24)
                : const Color(0xFF322030))
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF3F3A5C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round;

    final activeBorderPaint = Paint()
      ..color = isConnected
          ? const Color(0xFF1FE5BD).withValues(alpha: 0.65)
          : (isConnecting
                ? const Color(0xFFFFB800).withValues(alpha: 0.65)
                : const Color(0xFFFF5C70).withValues(alpha: 0.60))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;

    for (final poly in _kWorldPolygons) {
      if (poly.points.isEmpty) continue;
      final path = Path();
      final first = _project(poly.points.first.dx, poly.points.first.dy, size);
      path.moveTo(first.dx, first.dy);
      for (int i = 1; i < poly.points.length; i++) {
        final pt = _project(poly.points[i].dx, poly.points[i].dy, size);
        path.lineTo(pt.dx, pt.dy);
      }
      path.close();

      final isActivePoly =
          poly.code.toUpperCase() == activeCountry.code.toUpperCase();
      canvas.drawPath(path, isActivePoly ? activeFill : inactiveFill);
      canvas.drawPath(path, isActivePoly ? activeBorderPaint : borderPaint);
    }

    // 3. Country Labels (ProtonVPN uppercase style: BANGLADESH, UNITED STATES, SINGAPORE, etc.)
    for (final poly in _kWorldPolygons) {
      final pos = _project(poly.labelLng, poly.labelLat, size);
      if (pos.dx < -40 ||
          pos.dx > size.width + 40 ||
          pos.dy < 65 ||
          pos.dy > size.height + 10) {
        continue;
      }
      final isActivePoly =
          poly.code.toUpperCase() == activeCountry.code.toUpperCase();

      final tp = _cachedLabel(poly.label, isActivePoly);
      tp.paint(
        canvas,
        Offset(pos.dx - tp.width / 2, pos.dy + (isActivePoly ? 14 : -tp.height / 2)),
      );
    }

    // If activeCountry is not in _kWorldPolygons, still render its uppercase name
    final hasPoly = _kWorldPolygons.any(
      (p) => p.code.toUpperCase() == activeCountry.code.toUpperCase(),
    );
    final beaconPos = _project(activeCountry.lng, activeCountry.lat, size);
    if (!hasPoly) {
      final tp = _cachedLabel(activeCountry.name.toUpperCase(), true);
      tp.paint(canvas, Offset(beaconPos.dx - tp.width / 2, beaconPos.dy + 16));
    }

    // 4. Pulsing ProtonVPN Radar Beacon on Active Country
    final beaconColor = isConnected
        ? const Color(0xFF1FE5BD)
        : (isConnecting ? const Color(0xFFFFB800) : const Color(0xFFFF4D63));

    // Soft outer glow via GPU radial shader (avoids expensive MaskFilter.blur on 120Hz repaints)
    canvas.drawCircle(
      beaconPos,
      38.0,
      Paint()
        ..shader = ui.Gradient.radial(
          beaconPos,
          38.0,
          [
            beaconColor.withValues(alpha: 0.28),
            beaconColor.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          const [0.0, 0.55, 1.0],
        ),
    );

    // Expanding concentric radar rings
    for (int i = 0; i < 3; i++) {
      final wavePhase = (pulseProgress + (i * 0.33)) % 1.0;
      final radius = 8.0 + 28.0 * wavePhase;
      final alpha = (1.0 - wavePhase).clamp(0.0, 1.0) * 0.55;
      canvas.drawCircle(
        beaconPos,
        radius,
        Paint()
          ..color = beaconColor.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // Center glowing pin
    canvas.drawCircle(
      beaconPos,
      7.5,
      Paint()
        ..color = beaconColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      beaconPos,
      3.2,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _ProtonFocusedMapPainter oldDelegate) {
    return oldDelegate.cameraLng != cameraLng ||
        oldDelegate.cameraLat != cameraLat ||
        oldDelegate.zoom != zoom ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.isConnected != isConnected ||
        oldDelegate.isConnecting != isConnecting ||
        oldDelegate.activeCountry.code != activeCountry.code;
  }
}
