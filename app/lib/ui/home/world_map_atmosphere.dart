import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/theme_manager.dart';

class WorldMapAtmosphere extends StatelessWidget {
  final bool isConnected;
  final bool isConnecting;

  const WorldMapAtmosphere({
    super.key,
    required this.isConnected,
    this.isConnecting = false,
  });

  Color get _glowColor {
    if (isConnected) return ProtonColors.connected;
    if (isConnecting) return ProtonColors.connecting;
    return ProtonColors.disconnected;
  }

  @override
  Widget build(BuildContext context) {
    final isLiquid = ThemeManager.instance.isLiquidGlass;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 400,
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: isLiquid
                ? RadialGradient(
                    center: const Alignment(0, -0.65),
                    radius: 1.15,
                    colors: [
                      const Color(0xFF8B1538).withValues(alpha: isConnected ? 0.38 : (isConnecting ? 0.32 : 0.28)),
                      const Color(0xFF4B237C).withValues(alpha: isConnected ? 0.32 : (isConnecting ? 0.25 : 0.18)),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  )
                : RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 1.1,
                    colors: [
                      _glowColor.withValues(alpha: isConnected ? 0.16 : (isConnecting ? 0.14 : 0.08)),
                      _glowColor.withValues(alpha: isConnected ? 0.06 : 0.03),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
          ),
          child: isLiquid
              ? const SizedBox.shrink()
              : CustomPaint(
                  painter: _DottedMapPainter(
                    dotColor: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
        ),
      ),
    );
  }
}

class _DottedMapPainter extends CustomPainter {
  final Color dotColor;

  _DottedMapPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const spacing = 18.0;
    final cols = (size.width / spacing).ceil();
    final rows = (size.height / spacing).ceil();

    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        final x = i * spacing + (j % 2 == 0 ? 0 : spacing / 2);
        final y = j * spacing;
        final distanceFromCenter = (x - size.width / 2).abs() / (size.width / 2);
        final verticalFade = 1.0 - (y / size.height);
        final horizontalFade = (1.0 - (distanceFromCenter * 0.4)).clamp(0.0, 1.0);

        if (verticalFade > 0.1 && (i * 7 + j * 13) % 5 != 0) {
          canvas.drawCircle(Offset(x, y), 1.2 * verticalFade * horizontalFade, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
