import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';

class LiquidGlassAtmosphere extends StatelessWidget {
  final Widget child;
  final bool isConnected;
  final bool isConnecting;

  const LiquidGlassAtmosphere({
    super.key,
    required this.child,
    this.isConnected = false,
    this.isConnecting = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;
        final isLiquid = ThemeManager.instance.isLiquidGlass;
        final bgColor = ThemeManager.instance.backgroundColor;

        if (!isLiquid) {
          return Scaffold(
            backgroundColor: bgColor,
            body: child,
          );
        }

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // --- LIQUID GLASS ATMOSPHERIC LIGHTING LAYERS ---
              if (!isDark) ...[
                // LIGHT MODE LIQUID GLASS (matching photo_12, photo_11, photo_5, photo_7, etc.)
                // 1. Top-Right Soft Coral / Peach Fluid Orb
                Positioned(
                  top: -80,
                  right: -60,
                  width: 380,
                  height: 380,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFAC8E).withValues(alpha: 0.55),
                            const Color(0xFFFFD1C0).withValues(alpha: 0.32),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Top-Left Refreshing Mint / Aqua Fluid Orb
                Positioned(
                  top: -60,
                  left: -70,
                  width: 340,
                  height: 340,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFA7F3D0).withValues(alpha: 0.45),
                            const Color(0xFFBAE6FD).withValues(alpha: 0.25),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Center Atmospheric Lavender / Periwinkle Glow
                Positioned(
                  top: 140,
                  left: 0,
                  right: 0,
                  height: 360,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          radius: 1.15,
                          colors: [
                            const Color(0xFFE2D9FC).withValues(alpha: 0.50),
                            const Color(0xFFFFE0D4).withValues(alpha: 0.25),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Lower-Mid Sunset Peach Fluid Orb (for scrolling lists)
                Positioned(
                  top: 480,
                  right: -50,
                  width: 340,
                  height: 340,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFC0AE).withValues(alpha: 0.38),
                            const Color(0xFFDDD3F8).withValues(alpha: 0.22),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // 5. Lower-Left Cyan Fluid Orb
                Positioned(
                  top: 720,
                  left: -60,
                  width: 320,
                  height: 320,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFA7F3D0).withValues(alpha: 0.32),
                            const Color(0xFFBAE6FD).withValues(alpha: 0.20),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // 6. Bottom Dock Ambient Purple Lighting
                Positioned(
                  bottom: -10,
                  left: 0,
                  right: 0,
                  height: 170,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, 0.85),
                          radius: 0.95,
                          colors: [
                            const Color(0xFF6B42FF).withValues(alpha: 0.40),
                            const Color(0xFF9065FF).withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // DARK MODE LIQUID GLASS (matching photo_1, photo_7, photo_2, photo_5, etc.)
                // 1. Center / Top Status Radial Aura (Ruby Red when off, Emerald when on)
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  height: 360,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.25),
                          radius: 0.90,
                          colors: [
                            (isConnected
                                    ? const Color(0xFF00E676)
                                    : (isConnecting ? const Color(0xFFFFB300) : const Color(0xFFFF2A55)))
                                .withValues(alpha: isConnected ? 0.40 : 0.35),
                            const Color(0xFF5A189A).withValues(alpha: 0.22),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.50, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Top-Right Deep Crimson Nebula Glow
                Positioned(
                  top: -50,
                  right: -50,
                  width: 320,
                  height: 320,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF7A0C2E).withValues(alpha: 0.32),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Mid-screen deep violet nebula
                Positioned(
                  top: 420,
                  right: -40,
                  width: 320,
                  height: 320,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF4B237C).withValues(alpha: 0.26),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Bottom Electric Purple Neon Aura behind Dock
                Positioned(
                  bottom: -10,
                  left: 0,
                  right: 0,
                  height: 190,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, 0.85),
                          radius: 1.0,
                          colors: [
                            const Color(0xFF6B42FF).withValues(alpha: 0.50),
                            const Color(0xFF381B7E).withValues(alpha: 0.25),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              // Content
              child,
            ],
          ),
        );
      },
    );
  }
}
