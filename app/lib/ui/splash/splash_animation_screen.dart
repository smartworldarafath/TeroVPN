import 'dart:math';
import 'package:flutter/material.dart';

/// Full 60fps Kinetic Opening Splash Screen Animation
/// Faithfully reproduces the 3-second motion story from screensplash.html:
/// Phase 1 (0.0s - 1.7s): Line clouds, cyber server silhouettes, cathedral data hub,
/// moving highway, and encrypted VPN cruiser/pod driving across with glowing neon trail.
/// Phase 2 (1.7s - 3.2s): Parallax drop exit, 3D frosted shield app icon elastic pop-in,
/// kinetic 'tero' + emerald cyber shield badge + 'vpn' wordmark reveal, and 3 pulsing dots.
class SplashAnimationScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const SplashAnimationScreen({super.key, required this.onFinished});

  @override
  State<SplashAnimationScreen> createState() => _SplashAnimationScreenState();
}

class _SplashAnimationScreenState extends State<SplashAnimationScreen> with TickerProviderStateMixin {
  late AnimationController _storyController;
  late AnimationController _roadDashController;
  late AnimationController _dotsController;
  bool _isTransitioningOut = false;

  @override
  void initState() {
    super.initState();
    _storyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _roadDashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _storyController.forward();
    _storyController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && !_isTransitioningOut) {
        _handleFinish();
      }
    });
  }

  void _handleFinish() {
    if (_isTransitioningOut) return;
    setState(() => _isTransitioningOut = true);
    widget.onFinished();
  }

  @override
  void dispose() {
    _storyController.dispose();
    _roadDashController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleFinish,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF4B1D95), // Rich purple-violet sky
                Color(0xFF371375),
                Color(0xFF1D0942),
              ],
              stops: [0.0, 0.52, 1.0],
            ),
          ),
          child: AnimatedBuilder(
            animation: Listenable.merge([_storyController, _roadDashController, _dotsController]),
            builder: (context, _) {
              final t = _storyController.value; // 0.0 to 1.0
              final size = MediaQuery.of(context).size;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // LAYER 1: Minimalist Line Clouds Drifting
                  _buildClouds(t, size),

                  // LAYER 2: Phase 1 City & Cyber Highway (Drops out at t >= 0.52)
                  _buildPhase1CityAndRoad(t, size),

                  // LAYER 3: Hero Encrypted Cruiser / Pod Driving Across (t: 0.0 to 0.58)
                  _buildCruiserPod(t, size),

                  // LAYER 4: Phase 2 Brand Reveal (t >= 0.52 to 1.0)
                  _buildPhase2BrandReveal(t, size),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildClouds(double t, Size size) {
    final driftSlow = sin(t * pi) * 25.0;
    final driftFast = cos(t * pi) * 35.0;

    return Stack(
      children: [
        Positioned(
          top: 60,
          left: 30 + driftSlow,
          child: CustomPaint(
            size: const Size(140, 35),
            painter: _CloudPainter(),
          ),
        ),
        Positioned(
          top: 120,
          right: 25 - driftFast,
          child: CustomPaint(
            size: const Size(120, 32),
            painter: _CloudPainter(),
          ),
        ),
        Positioned(
          top: 240,
          left: 45 + driftFast,
          child: CustomPaint(
            size: const Size(150, 38),
            painter: _CloudPainter(),
          ),
        ),
        Positioned(
          bottom: 120,
          left: 50 + driftSlow,
          child: CustomPaint(
            size: const Size(160, 40),
            painter: _CloudPainter(),
          ),
        ),
      ],
    );
  }

  Widget _buildPhase1CityAndRoad(double t, Size size) {
    // City drops down and fades out between t=0.52 and 0.72
    double dropOffset = 0.0;
    double opacity = 1.0;

    if (t > 0.52) {
      final dropP = ((t - 0.52) / 0.20).clamp(0.0, 1.0);
      final curvedDrop = Curves.easeInCubic.transform(dropP);
      dropOffset = curvedDrop * 340.0;
      opacity = (1.0 - curvedDrop).clamp(0.0, 1.0);
    }

    if (opacity <= 0.0) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Transform.translate(
        offset: Offset(0, dropOffset),
        child: Opacity(
          opacity: opacity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // City Skyline (cathedral + data towers)
              SizedBox(
                height: 240,
                child: Center(
                  child: CustomPaint(
                    size: const Size(340, 240),
                    painter: _CyberCityPainter(),
                  ),
                ),
              ),

              // Cyber Highway Road
              Container(
                height: 110,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF14082E),
                  border: Border(
                    top: BorderSide(color: Color(0xFF2D165E), width: 4),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Moving dashed center road line
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DashedRoadLinePainter(
                          scrollProgress: _roadDashController.value,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCruiserPod(double t, Size size) {
    if (t > 0.65) return const SizedBox.shrink();

    // Drives from left (-140) across screen to right (size.width + 100)
    final driveProgress = (t / 0.60).clamp(0.0, 1.0);
    final curvedDrive = Curves.easeInOutCubic.transform(driveProgress);
    final cruiserX = -130.0 + curvedDrive * (size.width + 240.0);
    final bobY = sin(t * pi * 8) * 2.5;

    return Positioned(
      bottom: 108 + bobY,
      left: cruiserX,
      child: CustomPaint(
        size: const Size(130, 90),
        painter: _CyberCruiserPainter(t: t),
      ),
    );
  }

  Widget _buildPhase2BrandReveal(double t, Size size) {
    if (t < 0.50) return const SizedBox.shrink();

    final phase2P = ((t - 0.50) / 0.50).clamp(0.0, 1.0);

    // 1. Logo box scale pop (from 0.3 to 1.0 with elastic bounce)
    final logoP = (phase2P / 0.50).clamp(0.0, 1.0);
    final logoScale = Curves.easeOutBack.transform(logoP);
    final logoOpacity = logoP.clamp(0.0, 1.0);

    // 2. Kinetic wordmark: "tero" from left, "vpn" from right
    final wordP = ((phase2P - 0.15) / 0.55).clamp(0.0, 1.0);
    final wordCurved = Curves.easeOutBack.transform(wordP);
    final wordLeftX = (1.0 - wordCurved) * -35.0;
    final wordRightX = (1.0 - wordCurved) * 35.0;

    // 3. Cyber emerald badge pop in middle
    final badgeP = ((phase2P - 0.28) / 0.50).clamp(0.0, 1.0);
    final badgeScale = Curves.easeOutBack.transform(badgeP);
    final badgeRotate = (1.0 - badgeP) * -0.3;

    // 4. Loading dots
    final dotsP = ((phase2P - 0.40) / 0.40).clamp(0.0, 1.0);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3D Frosted Shield Squircle App Icon
          Opacity(
            opacity: logoOpacity,
            child: Transform.scale(
              scale: logoScale,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFAB82FF),
                      Color(0xFF7C4DFF),
                      Color(0xFF5623D4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF140438).withValues(alpha: 0.65),
                      blurRadius: 40,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: const Color(0xFFA78BFA).withValues(alpha: 0.45),
                      blurRadius: 50,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.65),
                    width: 2.0,
                  ),
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(65, 75),
                    painter: _ShieldKeyholePainter(),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Kinetic Brand Wordmark: "tero" + [Badge] + "vpn"
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // "tero"
              Transform.translate(
                offset: Offset(wordLeftX, 0),
                child: Opacity(
                  opacity: wordP.clamp(0.0, 1.0),
                  child: const Text(
                    'tero',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.2,
                      height: 1.0,
                    ),
                  ),
                ),
              ),

              // Center Emerald Cyber Shield Badge
              Transform.scale(
                scale: badgeScale,
                child: Transform.rotate(
                  angle: badgeRotate,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34D399),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF34D399),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.shield_rounded,
                        color: Color(0xFF064E3B),
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ),

              // "vpn" with emerald dot
              Transform.translate(
                offset: Offset(wordRightX, 0),
                child: Opacity(
                  opacity: wordP.clamp(0.0, 1.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'vpn',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFDDD6FE),
                          letterSpacing: -1.2,
                          height: 1.0,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 4, top: 22),
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34D399),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF34D399),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // 3 Minimal Bouncing Loading Dots
          Opacity(
            opacity: dotsP.clamp(0.0, 1.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final dotPhase = (_dotsController.value + i * 0.25) % 1.0;
                final scale = 1.0 + sin(dotPhase * pi) * 0.5;
                final isGreen = dotPhase > 0.4 && dotPhase < 0.8;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 8 * scale,
                  height: 8 * scale,
                  decoration: BoxDecoration(
                    color: isGreen ? const Color(0xFF34D399) : Colors.white.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    boxShadow: isGreen
                        ? const [
                            BoxShadow(
                              color: Color(0xFF34D399),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Minimalist line cloud painter matching screensplash.html
class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDDD6FE).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.8);
    path.lineTo(size.width * 0.9, size.height * 0.8);
    path.addArc(Rect.fromLTWH(size.width * 0.25, size.height * 0.4, size.width * 0.25, size.height * 0.4), pi, pi);
    path.addArc(Rect.fromLTWH(size.width * 0.45, size.height * 0.2, size.width * 0.3, size.height * 0.6), pi, pi);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Cyber City Skyline & Cathedral Hub
class _CyberCityPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()..color = const Color(0xFFF5F0FF);
    final accentPaint = Paint()..color = const Color(0xFFCAB3FF);
    final darkTowerPaint = Paint()..color = const Color(0xFF230B54);
    final greenNode = Paint()..color = const Color(0xFF34D399);

    // Background dark violet silhouettes
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(20, 60, 65, 180), const Radius.circular(3)), darkTowerPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(250, 40, 70, 200), const Radius.circular(3)), darkTowerPaint);

    // Left Server Bell Tower
    canvas.drawRect(const Rect.fromLTWH(38, 62, 56, 178), whitePaint);
    final leftRoof = Path()
      ..moveTo(35, 62)
      ..lineTo(66, 34)
      ..lineTo(97, 62)
      ..close();
    canvas.drawPath(leftRoof, Paint()..color = Colors.white);
    canvas.drawLine(const Offset(66, 14), const Offset(66, 35), Paint()..color = Colors.white..strokeWidth = 3);
    canvas.drawCircle(const Offset(66, 14), 4, greenNode);

    // Center Grand Cyber Data Hub
    canvas.drawRect(const Rect.fromLTWH(94, 105, 152, 135), whitePaint);
    final centerRoof = Path()
      ..moveTo(86, 105)
      ..lineTo(170, 56)
      ..lineTo(254, 105)
      ..close();
    canvas.drawPath(centerRoof, Paint()..color = const Color(0xFFF3ECFF));

    // Shield Emblem on Building
    final shieldPath = Path()
      ..moveTo(170, 72)
      ..lineTo(182, 78)
      ..lineTo(182, 90)
      ..quadraticBezierTo(170, 104, 170, 104)
      ..quadraticBezierTo(158, 90, 158, 78)
      ..close();
    canvas.drawPath(shieldPath, Paint()..color = const Color(0xFF6D28D9));

    // Arched cyber portals
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(112, 165, 28, 75), const Radius.circular(14)), accentPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(150, 155, 40, 85), const Radius.circular(20)), Paint()..color = const Color(0xFF9F75FF));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(200, 165, 28, 75), const Radius.circular(14)), accentPaint);

    // Right Tower
    canvas.drawRect(const Rect.fromLTWH(246, 62, 56, 178), whitePaint);
    final rightRoof = Path()
      ..moveTo(243, 62)
      ..lineTo(274, 34)
      ..lineTo(305, 62)
      ..close();
    canvas.drawPath(rightRoof, Paint()..color = Colors.white);
    canvas.drawLine(const Offset(274, 14), const Offset(274, 35), Paint()..color = Colors.white..strokeWidth = 3);
    canvas.drawCircle(const Offset(274, 14), 4, Paint()..color = const Color(0xFFA78BFA));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dashed Highway Center Line Painter
class _DashedRoadLinePainter extends CustomPainter {
  final double scrollProgress;

  _DashedRoadLinePainter({required this.scrollProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDDD6FE).withValues(alpha: 0.5)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const dashWidth = 36.0;
    const dashSpace = 24.0;
    final totalSegment = dashWidth + dashSpace;
    final offset = scrollProgress * totalSegment;

    for (double x = -offset; x < size.width + totalSegment; x += totalSegment) {
      canvas.drawLine(Offset(x, size.height * 0.45), Offset(x + dashWidth, size.height * 0.45), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoadLinePainter oldDelegate) =>
      oldDelegate.scrollProgress != scrollProgress;
}

/// Cyber Cruiser Scooter with Rider & Emerald Cargo Box
class _CyberCruiserPainter extends CustomPainter {
  final double t;

  _CyberCruiserPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // High-speed neon engine trails behind vehicle
    final trailPaint1 = Paint()..color = const Color(0xFF34D399).withValues(alpha: 0.85)..strokeWidth = 3..strokeCap = StrokeCap.round;
    final trailPaint2 = Paint()..color = const Color(0xFFA78BFA).withValues(alpha: 0.70)..strokeWidth = 2..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-32, 48), const Offset(10, 48), trailPaint1);
    canvas.drawLine(const Offset(-20, 56), const Offset(8, 56), trailPaint2);

    // Ground Shadow
    canvas.drawOval(const Rect.fromLTWH(24, 76, 84, 8), Paint()..color = Colors.black.withValues(alpha: 0.65));

    // Glowing Emerald VPN Cargo Box on back
    final boxRect = RRect.fromRectAndRadius(const Rect.fromLTWH(18, 30, 28, 24), const Radius.circular(5));
    canvas.drawRRect(boxRect, Paint()..color = const Color(0xFF10B981));
    canvas.drawRRect(boxRect, Paint()..color = const Color(0xFFA7F3D0)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    // Mini lock on cargo box
    canvas.drawCircle(const Offset(32, 42), 3.5, Paint()..color = const Color(0xFF064E3B));

    // Cyber Rider Silhouette & Helmet
    canvas.drawCircle(const Offset(60, 21), 9.5, Paint()..color = const Color(0xFFF5F3FF));
    // Glowing cyan visor
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(62, 18, 7, 5), const Radius.circular(2)), Paint()..color = const Color(0xFF34D399));
    // Rider body & arm
    canvas.drawLine(const Offset(60, 34), const Offset(82, 40), Paint()..color = const Color(0xFFA78BFA)..strokeWidth = 4.5..strokeCap = StrokeCap.round);

    // Cyber Scooter Chassis
    final bodyPath = Path()
      ..moveTo(22, 54)
      ..lineTo(72, 54)
      ..lineTo(84, 34)
      ..lineTo(92, 34)
      ..lineTo(82, 64)
      ..lineTo(30, 64)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = const Color(0xFF8B5CF6));
    canvas.drawPath(bodyPath, Paint()..color = const Color(0xFFDDD6FE)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Wheels
    _drawWheel(canvas, const Offset(34, 68));
    _drawWheel(canvas, const Offset(92, 68));
  }

  void _drawWheel(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 11, Paint()..color = const Color(0xFF1E1B4B));
    canvas.drawCircle(center, 11, Paint()..color = const Color(0xFFE0E7FF)..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawCircle(center, 4, Paint()..color = const Color(0xFF34D399));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 3D Shield with Keyhole Icon Painter
class _ShieldKeyholePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shield Body
    final shieldPath = Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.6, 0, w * 0.85, h * 0.1, w * 0.95, h * 0.18)
      ..cubicTo(w, h * 0.22, w, h * 0.28, w, h * 0.35)
      ..cubicTo(w, h * 0.68, w * 0.75, h * 0.9, w * 0.53, h * 0.99)
      ..lineTo(w * 0.5, h)
      ..lineTo(w * 0.47, h * 0.99)
      ..cubicTo(w * 0.25, h * 0.9, 0, h * 0.68, 0, h * 0.35)
      ..cubicTo(0, h * 0.28, 0, h * 0.22, w * 0.05, h * 0.18)
      ..cubicTo(w * 0.15, h * 0.1, w * 0.4, 0, w * 0.5, 0)
      ..close();

    final shieldGrad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.white, Color(0xFFEFE8FF), Color(0xFFA67EFF)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(shieldPath, Paint()..shader = shieldGrad);
    canvas.drawPath(shieldPath, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.5);

    // Keyhole cutout
    final keyholePaint = Paint()..color = const Color(0xFF5623D4);
    canvas.drawCircle(Offset(w * 0.5, h * 0.45), w * 0.15, keyholePaint);

    final stemPath = Path()
      ..moveTo(w * 0.42, h * 0.52)
      ..lineTo(w * 0.38, h * 0.72)
      ..lineTo(w * 0.62, h * 0.72)
      ..lineTo(w * 0.58, h * 0.52)
      ..close();
    canvas.drawPath(stemPath, keyholePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
