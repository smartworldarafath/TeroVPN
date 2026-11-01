import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';

/// 100% Pixel-Faithful & Video-Accurate Implementation of "Dock .html"
/// 3D Glassmorphic Navigation Bar with Liquid Jelly Hold & Drag Gesture Physics
///
/// Features from user demo video (Recording 2026-11-01 165905.mp4) & Dock .html:
/// - 464px x 97px baseline obsidian violet glass pill with responsive fitted scaling
/// - Idle state: 92px x 80px tray with 78px x 42px 3D Purple Jelly Capsule with reflection dome
/// - Hold/Drag state: expands to 138px x 128px 3D Protruding Liquid Glass Lens (protruding above & below)
/// - Meniscus caustics: top and bottom parabolic curved refraction meniscus specular bands
/// - Inactive tabs in hold state: labels fade to opacity 0, icons shift down 12px
/// - Active tab in hold state: icon blooms with intense specular white/lavender glow, scales 1.16x
/// - Smooth gliding with liquid jelly stretch on quick tap
/// - Velocity tracking, boundary rubber-banding, and momentum flick snap on release
/// - Never overflows or cuts off Settings on mobile screens via fitted scaling
class Dock1JellyBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final bool isInteractivePreview;

  const Dock1JellyBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.isInteractivePreview = false,
  });

  @override
  State<Dock1JellyBar> createState() => _Dock1JellyBarState();
}

class _Dock1JellyBarState extends State<Dock1JellyBar>
    with SingleTickerProviderStateMixin {
  static const double _kSlotWidth = 98.0;
  static const int _kTotalTabs = 4;
  static const double _kMinX = 0.0;
  static const double _kMaxX = (_kTotalTabs - 1) * _kSlotWidth; // 294.0

  late int _activeTab;
  int _hoveredTab = 0;
  bool _isHolding = false;
  bool _isDragging = false;
  bool _isGliding = false;

  double _sliderX = 0.0;
  double _dragStartLocalX = 0.0;
  double _dragStartSliderX = 0.0;
  double _velocity = 0.0;
  double _lastX = 0.0;
  int _lastDragTime = 0;

  late AnimationController _springController;
  Animation<double>? _springAnimation;

  static const List<_DockTabItem> _tabs = [
    _DockTabItem(
      label: 'Home',
      iconData: Icons.home_rounded,
      inactiveIconData: Icons.home_outlined,
    ),
    _DockTabItem(
      label: 'Countries',
      iconData: Icons.public_rounded,
      inactiveIconData: Icons.public_outlined,
    ),
    _DockTabItem(
      label: 'Profiles',
      iconData: Icons.bookmark_rounded,
      inactiveIconData: Icons.bookmark_border_rounded,
    ),
    _DockTabItem(
      label: 'Settings',
      iconData: Icons.settings_rounded,
      inactiveIconData: Icons.settings_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _activeTab = widget.currentIndex.clamp(0, _kTotalTabs - 1);
    _hoveredTab = _activeTab;
    _sliderX = _activeTab * _kSlotWidth;

    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void didUpdateWidget(covariant Dock1JellyBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex && !_isDragging && !_isHolding) {
      _animateToTab(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _animateToTab(int targetIndex) {
    final target = targetIndex.clamp(0, _kTotalTabs - 1);
    final start = _sliderX;
    final end = target * _kSlotWidth;

    setState(() {
      _activeTab = target;
      _hoveredTab = target;
      _isGliding = true;
    });

    _springAnimation = Tween<double>(begin: start, end: end).animate(
      CurvedAnimation(
        parent: _springController,
        curve: const Cubic(0.22, 1.18, 0.32, 1.0),
      ),
    )..addListener(() {
        setState(() {
          _sliderX = _springAnimation!.value;
        });
      });

    _springController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() => _isGliding = false);
      }
    });
  }

  void _onPointerDown(PointerDownEvent e) {
    _springController.stop();
    _isGliding = false;
    _dragStartLocalX = e.localPosition.dx;
    _dragStartSliderX = _activeTab * _kSlotWidth;
    _sliderX = _dragStartSliderX;
    _lastX = _sliderX;
    _lastDragTime = DateTime.now().millisecondsSinceEpoch;
    _velocity = 0.0;
    _isDragging = false;

    setState(() {
      _isHolding = true;
      _hoveredTab = _activeTab;
    });
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_isHolding) return;

    final deltaX = e.localPosition.dx - _dragStartLocalX;
    if (deltaX.abs() > 3.0) {
      _isDragging = true;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final dt = math.max(1, now - _lastDragTime);

    double nextX = _dragStartSliderX + deltaX;

    // Elastic rubber-band resistance at boundaries (from Dock .html)
    if (nextX < _kMinX) {
      nextX = _kMinX - math.pow((_kMinX - nextX).abs(), 0.70) * 1.8;
    } else if (nextX > _kMaxX) {
      nextX = _kMaxX + math.pow((nextX - _kMaxX).abs(), 0.70) * 1.8;
    }

    _velocity = (nextX - _lastX) / dt;
    _lastX = nextX;
    _lastDragTime = now;

    final hovered = (nextX / _kSlotWidth).round().clamp(0, _kTotalTabs - 1);

    setState(() {
      _sliderX = nextX;
      _hoveredTab = hovered;
    });
  }

  void _onPointerUp(PointerUpEvent e) {
    if (!_isHolding) return;

    final wasDragging = _isDragging;
    setState(() {
      _isHolding = false;
      _isDragging = false;
    });

    int targetTab;
    if (wasDragging) {
      // Momentum projection on flick release (velocity * 85ms)
      final projectedX = _sliderX + _velocity * 85.0;
      targetTab = (projectedX / _kSlotWidth).round().clamp(0, _kTotalTabs - 1);
    } else {
      final localX = (e.localPosition.dx - 36.0).clamp(0.0, _kSlotWidth * _kTotalTabs);
      targetTab = (localX / _kSlotWidth).floor().clamp(0, _kTotalTabs - 1);
    }

    _animateToTab(targetTab);
    widget.onTabSelected(targetTab);
  }

  void _onPointerCancel() {
    if (!_isHolding) return;
    setState(() {
      _isHolding = false;
      _isDragging = false;
    });
    _animateToTab(_activeTab);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;

        return RepaintBoundary(
          child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          // Target baseline width is 464px. Keep at least 24px total breathing room on screen edges.
          final scale = math.min(1.0, (availableWidth - 24.0) / 464.0);
          final scaledWidth = 464.0 * scale;
          final scaledHeight = 136.0 * scale;

          return SizedBox(
            width: availableWidth,
            height: 136.0,
            child: Center(
              child: SizedBox(
                width: scaledWidth,
                height: scaledHeight,
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  child: SizedBox(
                    width: 464.0,
                    height: 136.0,
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: _onPointerDown,
                      onPointerMove: _onPointerMove,
                      onPointerUp: _onPointerUp,
                      onPointerCancel: (_) => _onPointerCancel(),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // 1. Outer Ambient Glow Halo
                          _buildAmbientHalo(isDark),

                          // 2. Main Outer Pill Container (464px x 97px)
                          _buildMainPill(isDark),

                          // 3. Sliding Active Indicator Assembly (Tray + Purple Capsule / Protruding Lens)
                          _buildActiveSlider(isDark),

                          // 4. Interactive Tabs Layer
                          _buildTabsLayer(isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
      },
    );
  }

  Widget _buildAmbientHalo(bool isDark) {
    return Positioned(
      width: 490,
      height: 120,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.85,
              colors: isDark
                  ? [
                      const Color(0xFF5A30AF).withValues(alpha: 0.45),
                      const Color(0xFF3C1878).withValues(alpha: 0.22),
                      Colors.transparent,
                    ]
                  : [
                      const Color(0xFF9060FA).withValues(alpha: 0.20),
                      const Color(0xFFB18CFA).withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainPill(bool isDark) {
    return Container(
      width: 464,
      height: 97,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xDC1E182E),
                  Color(0xEB120D1E),
                  Color(0xE0181226),
                ],
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.95),
                  const Color(0xFFF7F4FC).withValues(alpha: 0.92),
                  const Color(0xFFECE5F7).withValues(alpha: 0.95),
                  const Color(0xFFE2D6F3).withValues(alpha: 0.96),
                ],
              ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.16)
              : const Color(0xFF6B42FF).withValues(alpha: 0.20),
          width: 1.2,
        ),
        boxShadow: isDark
            ? const [
                BoxShadow(
                  color: Color(0xBF030108),
                  blurRadius: 44,
                  offset: Offset(0, 24),
                ),
                BoxShadow(
                  color: Color(0x404C20A0),
                  blurRadius: 24,
                  offset: Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF381F66).withValues(alpha: 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: const Color(0xFF6B42FF).withValues(alpha: 0.12),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Stack(
        children: [
          // Subtle top glass highlight across upper half of the bar
          Positioned(
            top: 0,
            left: 18,
            right: 18,
            height: 46,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(999)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.14),
                    Colors.white.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSlider(bool isDark) {
    // Liquid deformation stretch based on velocity or gliding
    final speed = math.min(2.2, _velocity.abs());
    final stretchX = _isGliding ? 1.08 : (1.0 + speed * 0.065);
    final compressY = _isGliding ? 0.94 : (1.0 / math.sqrt(stretchX));
    final skewAngle = math.max(-7.0, math.min(7.0, _velocity * 3.8));

    final currentTabX = _sliderX;
    // Base position starts at left: 36px inside 464px pill
    final trayLeft = 36.0 + currentTabX + (_kSlotWidth / 2.0);

    // Idle size: 92px x 80px. Hold size: 138px x 128px (protruding outside dock!)
    final trayWidth = _isHolding ? 138.0 : 92.0;
    final trayHeight = _isHolding ? 128.0 : 80.0;
    final borderRadius = _isHolding ? 44.0 : 21.0;

    return Positioned(
      left: trayLeft - (trayWidth / 2.0),
      top: 68.0 - (trayHeight / 2.0),
      child: IgnorePointer(
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(stretchX, compressY, 1.0)
            ..setEntry(0, 1, math.tan(skewAngle * math.pi / 180)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: const Cubic(0.22, 1.28, 0.32, 1.0),
            width: trayWidth,
            height: trayHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: _isHolding
                  ? const RadialGradient(
                      center: Alignment.center,
                      radius: 0.85,
                      colors: [
                        Color(0xE0100C1C),
                        Color(0xC7161028),
                        Color(0x477864AF),
                        Color(0x61F0EBFF),
                      ],
                      stops: [0.0, 0.54, 0.84, 1.0],
                    )
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x7352447E),
                        Color(0x61302650),
                        Color(0x85483A70),
                      ],
                    ),
              border: Border.all(
                color: _isHolding
                    ? Colors.white.withValues(alpha: 0.72)
                    : Colors.white.withValues(alpha: 0.18),
                width: _isHolding ? 1.4 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isHolding ? 0.80 : 0.55),
                  blurRadius: _isHolding ? 48 : 18,
                  offset: Offset(0, _isHolding ? 26 : 8),
                ),
                if (_isHolding)
                  const BoxShadow(
                    color: Color(0x595F37C3),
                    blurRadius: 24,
                    offset: Offset(0, 6),
                  ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Top & Bottom Parabolic Curved Specular Meniscus Caustics (Visible in Hold State)
                if (_isHolding)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MeniscusPainter(),
                    ),
                  ),

                // 3D Glossy Purple Jelly Capsule in Idle State (78px x 42px)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 240),
                  opacity: _isHolding ? 0.0 : 1.0,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.only(top: 5.5),
                      width: 78,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const RadialGradient(
                          center: Alignment(0, -0.30),
                          radius: 0.75,
                          colors: [
                            Color(0xFF7038E8),
                            Color(0xFF511EC4),
                            Color(0xFF350F96),
                            Color(0xFF200460),
                          ],
                          stops: [0.0, 0.42, 0.78, 1.0],
                        ),
                        border: Border.all(
                          color: const Color(0xFFDCC3FF).withValues(alpha: 0.40),
                          width: 1.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x737838F5),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Color(0xBF080218),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Top Reflection Dome
                          Positioned(
                            top: 1.5,
                            left: 6,
                            right: 6,
                            height: 19,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.60),
                                    const Color(0xFFF0E1FF).withValues(alpha: 0.25),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabsLayer(bool isDark) {
    return Positioned(
      left: 36,
      top: 28.0,
      width: _kSlotWidth * _kTotalTabs,
      height: 80,
      child: IgnorePointer(
        child: Row(
          children: List.generate(_kTotalTabs, (index) {
            final tab = _tabs[index];
            final isActive = _isHolding ? (_hoveredTab == index) : (_activeTab == index);

            return SizedBox(
              width: _kSlotWidth,
              height: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Upper area (42px) containing the icon inside the purple capsule
                  SizedBox(
                    height: 48,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 320),
                        curve: const Cubic(0.34, 1.56, 0.64, 1.0),
                        transform: Matrix4.translationValues(
                          0.0,
                          _isHolding
                              ? (isActive ? 3.0 : 12.0)
                              : (isActive ? 0.0 : 0.0),
                          0.0,
                        ),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 320),
                          scale: _isHolding
                              ? (isActive ? 1.18 : 0.90)
                              : (isActive ? 1.06 : 1.0),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Radial bloom aura behind active icon during hold (zero text-shadow risk)
                              if (isActive && _isHolding)
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        blurRadius: 14,
                                        spreadRadius: 2,
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFFC084FC).withValues(alpha: 0.65),
                                        blurRadius: 22,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              Icon(
                                isActive ? tab.iconData : tab.inactiveIconData,
                                size: 25,
                                color: (isActive && _isHolding)
                                    ? Colors.white
                                    : (isActive ? const Color(0xFFF7F4FF) : const Color(0xFF9E99AD)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Lower area containing the tab label
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: _isHolding ? (isActive ? 1.0 : 0.0) : 1.0,
                    child: Text(
                      tab.label,
                      style: TextStyle(
                        fontFamily: 'SF Pro Text',
                        fontSize: 13.5,
                        letterSpacing: -0.15,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? (_isHolding ? Colors.white : const Color(0xFFEBE6F6))
                            : const Color(0xFF8F8A9E),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Parabolic Curved Specular Meniscus Caustics Painter (matching video frames & Dock .html)
class _MeniscusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Top curved meniscus band
    final topPath = Path()
      ..moveTo(w * 0.14, 2)
      ..quadraticBezierTo(w * 0.5, 19, w * 0.86, 2)
      ..quadraticBezierTo(w * 0.5, 6, w * 0.14, 2)
      ..close();

    final topPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xD1FFFFFF),
          Color(0x94E1E8F5),
          Color(0x2EB4C3DC),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, 22));

    canvas.drawPath(topPath, topPaint);

    // Bottom curved meniscus band
    final botPath = Path()
      ..moveTo(w * 0.14, h - 2)
      ..quadraticBezierTo(w * 0.5, h - 19, w * 0.86, h - 2)
      ..quadraticBezierTo(w * 0.5, h - 6, w * 0.14, h - 2)
      ..close();

    final botPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color(0xD1FFFFFF),
          Color(0x94DCE6F5),
          Color(0x2EAFBEDC),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, h - 22, w, 22));

    canvas.drawPath(botPath, botPaint);
  }

  @override
  bool shouldRepaint(covariant _MeniscusPainter oldDelegate) => false;
}

class _DockTabItem {
  final String label;
  final IconData iconData;
  final IconData inactiveIconData;

  const _DockTabItem({
    required this.label,
    required this.iconData,
    required this.inactiveIconData,
  });
}
