import 'dart:math';
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
  'US': CountryCoordinates(lat: 40.7128, lng: -74.0060, code: 'US', name: 'United States', city: 'New York'),
  'GB': CountryCoordinates(lat: 51.5074, lng: -0.1278, code: 'GB', name: 'United Kingdom', city: 'London'),
  'CH': CountryCoordinates(lat: 46.2044, lng: 6.1432, code: 'CH', name: 'Switzerland', city: 'Geneva'),
  'JP': CountryCoordinates(lat: 35.6762, lng: 139.6503, code: 'JP', name: 'Japan', city: 'Tokyo'),
  'SG': CountryCoordinates(lat: 1.3521, lng: 103.8198, code: 'SG', name: 'Singapore', city: 'Singapore'),
  'CA': CountryCoordinates(lat: 45.4215, lng: -75.6972, code: 'CA', name: 'Canada', city: 'Montreal'),
  'FR': CountryCoordinates(lat: 48.8566, lng: 2.3522, code: 'FR', name: 'France', city: 'Paris'),
  'SE': CountryCoordinates(lat: 59.3293, lng: 18.0686, code: 'SE', name: 'Sweden', city: 'Stockholm'),
  'NO': CountryCoordinates(lat: 59.9139, lng: 10.7522, code: 'NO', name: 'Norway', city: 'Oslo'),
  'FI': CountryCoordinates(lat: 60.1699, lng: 24.9384, code: 'FI', name: 'Finland', city: 'Helsinki'),
  'AU': CountryCoordinates(lat: -33.8688, lng: 151.2093, code: 'AU', name: 'Australia', city: 'Sydney'),
  'IS': CountryCoordinates(lat: 64.1466, lng: -21.9426, code: 'IS', name: 'Iceland', city: 'Reykjavik'),
  'ES': CountryCoordinates(lat: 40.4168, lng: -3.7038, code: 'ES', name: 'Spain', city: 'Madrid'),
};

class ProtonWorldMap extends StatefulWidget {
  final bool isConnected;
  final bool isConnecting;
  final String originCountryCode;
  final String destinationCountryCode;
  final String destinationCityName;
  final VoidCallback? onMapTap;

  const ProtonWorldMap({
    super.key,
    required this.isConnected,
    this.isConnecting = false,
    this.originCountryCode = 'BD',
    required this.destinationCountryCode,
    this.destinationCityName = '',
    this.onMapTap,
  });

  @override
  State<ProtonWorldMap> createState() => _ProtonWorldMapState();
}

class _ProtonWorldMapState extends State<ProtonWorldMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  CountryCoordinates _getDestLocation() {
    final code = widget.destinationCountryCode.toUpperCase();
    return kCountryLocations[code] ??
        kCountryLocations['NL']!;
  }

  CountryCoordinates _getOriginLocation() {
    final code = widget.originCountryCode.toUpperCase();
    return kCountryLocations[code] ??
        kCountryLocations['BD']!;
  }

  double _calculateDistanceKm(CountryCoordinates a, CountryCoordinates b) {
    const p = 0.017453292519943295;
    final c = 0.5 -
        cos((b.lat - a.lat) * p) / 2 +
        cos(a.lat * p) * cos(b.lat * p) * (1 - cos((b.lng - a.lng) * p)) / 2;
    return 12742 * asin(sqrt(c));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;
        final isLiquid = ThemeManager.instance.isLiquidGlass;

        final origin = _getOriginLocation();
        final dest = _getDestLocation();
        final distanceKm = _calculateDistanceKm(origin, dest).round();

        final mapBg = isDark
            ? (isLiquid ? const Color(0xFF100E1C).withValues(alpha: 0.90) : const Color(0xFF141122))
            : (isLiquid ? Colors.white.withValues(alpha: 0.92) : const Color(0xFFFAF9FD));

        final cardBorder = isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFF5D5380).withValues(alpha: 0.12);

        final textPrimary = isDark ? Colors.white : const Color(0xFF1D1536);
        final textSecondary = isDark ? const Color(0xFF8E8B9D) : const Color(0xFF6E6B80);

        return LayoutBuilder(
          builder: (context, constraints) {
            final showHud = constraints.maxWidth >= 240;

            return Container(
              height: 250,
              decoration: BoxDecoration(
                color: mapBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isConnected
                      ? const Color(0xFF00E676).withValues(alpha: isDark ? 0.4 : 0.3)
                      : (widget.isConnecting
                          ? const Color(0xFFFFB800).withValues(alpha: 0.4)
                          : cardBorder),
                  width: 1.2,
                ),
                boxShadow: isLiquid ? ThemeManager.instance.cardShadow : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // World Map Custom Painter
                  AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ProtonMapCanvasPainter(
                      progress: _animController.value,
                      origin: origin,
                      destination: dest,
                      isConnected: widget.isConnected,
                      isConnecting: widget.isConnecting,
                      isDark: isDark,
                    ),
                  );
                },
              ),

                  if (showHud) ...[
                    // Top HUD Telemetry Banner
                    Positioned(
                      top: 10,
                      left: 12,
                      right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Origin Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF181528) : Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFF5D5380).withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CountryFlag(countryCode: origin.code, width: 16, height: 11),
                                const SizedBox(width: 5),
                                Text(
                                  origin.code,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Connection State Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.isConnected
                                  ? (isDark ? const Color(0xFF133226) : const Color(0xFFD8F5EB))
                                  : (widget.isConnecting
                                      ? (isDark ? const Color(0xFF332612) : const Color(0xFFFFF4D9))
                                      : (isDark ? const Color(0xFF28161A) : const Color(0xFFFFECEF))),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: widget.isConnected
                                    ? const Color(0xFF00C896).withValues(alpha: 0.5)
                                    : (widget.isConnecting
                                        ? const Color(0xFFFFB800).withValues(alpha: 0.5)
                                        : const Color(0xFFE53950).withValues(alpha: 0.4)),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.isConnected
                                      ? Icons.shield_rounded
                                      : (widget.isConnecting ? Icons.sync_rounded : Icons.gpp_maybe_rounded),
                                  size: 12,
                                  color: widget.isConnected
                                      ? const Color(0xFF00C896)
                                      : (widget.isConnecting ? const Color(0xFFFFB800) : const Color(0xFFE53950)),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.isConnected
                                      ? 'ON'
                                      : (widget.isConnecting ? 'CONNECTING' : 'OFF'),
                                  style: TextStyle(
                                    color: widget.isConnected
                                        ? (isDark ? const Color(0xFF00E676) : const Color(0xFF00A36C))
                                        : (widget.isConnecting
                                            ? const Color(0xFFFFB800)
                                            : const Color(0xFFE53950)),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Destination Information Card
                    Positioned(
                      bottom: 10,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF181528).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFF5D5380).withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          children: [
                            CountryFlag(countryCode: dest.code, width: 20, height: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.isConnected
                                    ? '${dest.name} (${widget.destinationCityName.isNotEmpty ? widget.destinationCityName : dest.city}) • $distanceKm km'
                                    : 'Target: ${dest.name}',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B42FF).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                widget.isConnected ? 'AES-256' : 'STANDBY',
                                style: const TextStyle(
                                  color: Color(0xFF8B6BFF),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProtonMapCanvasPainter extends CustomPainter {
  final double progress;
  final CountryCoordinates origin;
  final CountryCoordinates destination;
  final bool isConnected;
  final bool isConnecting;
  final bool isDark;

  _ProtonMapCanvasPainter({
    required this.progress,
    required this.origin,
    required this.destination,
    required this.isConnected,
    required this.isConnecting,
    required this.isDark,
  });

  // Convert lat/lng (-90..90, -180..180) to Canvas coordinates (0..w, 0..h)
  Offset _toCanvasPoint(double lat, double lng, Size size) {
    final x = (lng + 180.0) * (size.width / 360.0);
    final y = (90.0 - lat) * (size.height / 180.0);
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Geographic Continents Dotted Outline
    _drawWorldContinents(canvas, size);

    final originPoint = _toCanvasPoint(origin.lat, origin.lng, size);
    final destPoint = _toCanvasPoint(destination.lat, destination.lng, size);

    // 2. Draw Connection Arc when Connecting or Connected
    if (isConnected || isConnecting) {
      _drawGeodesicConnectionArc(canvas, originPoint, destPoint);
    }

    // 3. Draw Origin Point (User Location)
    _drawOriginPin(canvas, originPoint);

    // 4. Draw Destination Point (VPN Server Location)
    _drawDestinationBeacon(canvas, destPoint);
  }

  void _drawWorldContinents(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFF5D5380).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // Stylized high-accuracy world continent seed nodes
    final continentCenters = [
      // North America
      const Offset(0.18, 0.35), const Offset(0.24, 0.32), const Offset(0.28, 0.40), const Offset(0.20, 0.22),
      // South America
      const Offset(0.32, 0.68), const Offset(0.35, 0.78),
      // Europe
      const Offset(0.51, 0.28), const Offset(0.54, 0.30), const Offset(0.53, 0.22),
      // Africa
      const Offset(0.53, 0.52), const Offset(0.56, 0.65), const Offset(0.58, 0.45),
      // Asia
      const Offset(0.70, 0.32), const Offset(0.75, 0.36), const Offset(0.82, 0.34), const Offset(0.68, 0.45),
      // Australia
      const Offset(0.85, 0.74), const Offset(0.88, 0.78),
    ];

    for (final c in continentCenters) {
      final cx = c.dx * size.width;
      final cy = c.dy * size.height;
      for (int dx = -24; dx <= 24; dx += 8) {
        for (int dy = -16; dy <= 16; dy += 8) {
          if ((dx * dx + dy * dy) < 450) {
            canvas.drawCircle(Offset(cx + dx, cy + dy), 1.3, dotPaint);
          }
        }
      }
    }
  }

  void _drawGeodesicConnectionArc(Canvas canvas, Offset p1, Offset p2) {
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Curved control point arched upward
    final midX = (p1.dx + p2.dx) / 2;
    final midY = min(p1.dy, p2.dy) - 45.0;
    final controlPoint = Offset(midX, midY);

    final path = Path();
    path.moveTo(p1.dx, p1.dy);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, p2.dx, p2.dy);

    // Glowing underlying line
    arcPaint.shader = LinearGradient(
      colors: isConnected
          ? [const Color(0xFF6B42FF), const Color(0xFF00E676)]
          : [const Color(0xFF6B42FF), const Color(0xFFFFB800)],
    ).createShader(Rect.fromPoints(p1, p2));

    canvas.drawPath(path, arcPaint);

    // Animated Traveling Photon along the curve
    final t = progress;
    final invT = 1.0 - t;
    final photonX = invT * invT * p1.dx + 2 * invT * t * controlPoint.dx + t * t * p2.dx;
    final photonY = invT * invT * p1.dy + 2 * invT * t * controlPoint.dy + t * t * p2.dy;
    final photonPos = Offset(photonX, photonY);

    final photonPaint = Paint()
      ..color = isConnected ? const Color(0xFF00E676) : const Color(0xFFFFB800)
      ..style = PaintingStyle.fill;

    // Glowing halo around photon
    canvas.drawCircle(
      photonPos,
      6.0,
      Paint()
        ..color = (isConnected ? const Color(0xFF00E676) : const Color(0xFFFFB800)).withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );
    canvas.drawCircle(photonPos, 3.2, photonPaint);
  }

  void _drawOriginPin(Canvas canvas, Offset pos) {
    // Pulsing Radar ring around origin
    final radarRadius = 10.0 + 8.0 * (1.0 - progress);
    canvas.drawCircle(
      pos,
      radarRadius,
      Paint()
        ..color = const Color(0xFF6B42FF).withValues(alpha: 0.3 * progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Solid core pin
    canvas.drawCircle(
      pos,
      5.0,
      Paint()..color = const Color(0xFF6B42FF)..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      pos,
      2.5,
      Paint()..color = Colors.white..style = PaintingStyle.fill,
    );
  }

  void _drawDestinationBeacon(Canvas canvas, Offset pos) {
    final activeColor = isConnected
        ? const Color(0xFF00E676)
        : (isConnecting ? const Color(0xFFFFB800) : const Color(0xFF6B42FF));

    // Concentric expanding ripple waves
    for (int i = 0; i < 3; i++) {
      final wavePhase = (progress + (i * 0.33)) % 1.0;
      final waveRadius = 6.0 + 16.0 * wavePhase;
      final waveAlpha = (1.0 - wavePhase).clamp(0.0, 1.0) * 0.45;

      canvas.drawCircle(
        pos,
        waveRadius,
        Paint()
          ..color = activeColor.withValues(alpha: waveAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }

    // Glowing node center
    canvas.drawCircle(
      pos,
      6.0,
      Paint()..color = activeColor..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      pos,
      2.8,
      Paint()..color = Colors.white..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _ProtonMapCanvasPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isConnected != isConnected ||
        oldDelegate.destination.code != destination.code ||
        oldDelegate.isDark != isDark;
  }
}
