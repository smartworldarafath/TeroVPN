import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';

/// 100% Pixel-Faithful Implementation of "Dock .html"
/// 3D Glassmorphic Navigation Bar with Jelly Hold & Drag Gesture Physics
///
/// Baseline: 464px x 97px with responsive scaling.
/// Idle State: 92px x 80px tray with 78px x 42px 3D Purple Jelly Capsule.
/// Hold/Drag State: Expands to 138px x 128px 3D Protruding Liquid Glass Lens (protrudes 24px above & below).
/// Meniscus: Top and bottom curved refraction meniscus bands.
/// Gestures: 60fps/120fps Pointer tracking, velocity jelly stretch/compress, rubber-banding, momentum flick release.
/// Dual Theme: Full Dark Mode and Light Mode support with live theme listener.
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
  static const double _kMaxX = (_kTotalTabs - 1) * _kSlotWidth;

  late int _activeTab;
  int _hoveredTab = 0;
  bool _isHolding = false;
  bool _isDragging = false;

  double _sliderX = 0.0;
  double _dragStartX = 0.0;
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
      duration: const Duration(milliseconds: 440),
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

    _springController.forward(from: 0.0);
  }

  void _onPointerDown(PointerDownEvent e, double scale, double barLeft) {
    _springController.stop();
    _dragStartX = e.position.dx;
    _lastDragTime = DateTime.now().millisecondsSinceEpoch;
    _velocity = 0.0;
    _isDragging = false;

    // Detect touched slot immediately from touch coordinate
    final effectiveScale = scale > 0 ? scale : 1.0;
    final localX = (e.position.dx - barLeft) / effectiveScale - 36.0;
    final tappedSlot = (localX / _kSlotWidth).floor().clamp(0, _kTotalTabs - 1);

    // Jump lens immediately to touched tab slot
    _sliderX = tappedSlot * _kSlotWidth;
    _dragStartSliderX = _sliderX;
    _lastX = _sliderX;
    _activeTab = tappedSlot;
    _hoveredTab = tappedSlot;

    setState(() {
      _isHolding = true;
    });
  }

  void _onPointerMove(PointerMoveEvent e, double scale) {
    if (!_isHolding) return;

    final effectiveScale = scale > 0 ? scale : 1.0;
    final deltaX = (e.position.dx - _dragStartX) / effectiveScale;
    if (deltaX.abs() > 3.0) {
      _isDragging = true;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final dt = math.max(1, now - _lastDragTime);

    double nextX = _dragStartSliderX + deltaX;

    // Elastic rubber-band resistance at boundaries
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

  void _onPointerUp(PointerUpEvent e, double scale, double barLeft) {
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
      final effectiveScale = scale > 0 ? scale : 1.0;
      final localX = (e.position.dx - barLeft) / effectiveScale - 36.0;
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
              final maxWidth = constraints.maxWidth;
              // Base 464px, scale down smoothly on narrow screens
              final scale = math.min(1.0, (maxWidth - 12) / 464.0);
              const barWidth = 464.0;
              final scaledWidth = barWidth * scale;
              final barLeft = (maxWidth - scaledWidth) / 2.0;

              return SizedBox(
                height: 124, // Generous height to fit 128px protruding lens without clipping
                child: Center(
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (e) => _onPointerDown(e, scale, barLeft),
                    onPointerMove: (e) => _onPointerMove(e, scale),
                    onPointerUp: (e) => _onPointerUp(e, scale, barLeft),
                    onPointerCancel: (_) => _onPointerCancel(),
                    child: Transform.scale(
                      scale: scale,
                      child: SizedBox(
                        width: barWidth,
                        height: 124,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // 1. Outer Ambient Glow
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
              radius: 0.9,
              colors: isDark
                  ? [
                      const Color(0xFF5A30AF).withValues(alpha: 0.42),
                      const Color(0xFF3C1878).withValues(alpha: 0.22),
                      Colors.transparent,
                    ]
                  : [
                      const Color(0xFF8B5CF6).withValues(alpha: 0.28),
                      const Color(0xFFA855F7).withValues(alpha: 0.12),
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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF1E182E).withValues(alpha: 0.88),
                  const Color(0xFF120D1E).withValues(alpha: 0.94),
                  const Color(0xFF181226).withValues(alpha: 0.90),
                ]
              : [
                  Colors.white.withValues(alpha: 0.96),
                  const Color(0xFFF3EEFA).withValues(alpha: 0.92),
                  const Color(0xFFFAF7FF).withValues(alpha: 0.98),
                ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.20)
              : const Color(0xFF6B42FF).withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.75)
                : const Color(0xFF321A5A).withValues(alpha: 0.14),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: isDark
                ? const Color(0xFF4C20A0).withValues(alpha: 0.28)
                : const Color(0xFF8B5CF6).withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Top half specular glass highlight
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            height: 44,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(999)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.14 : 0.50),
                    Colors.white.withValues(alpha: isDark ? 0.02 : 0.10),
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
    // Liquid jelly deformation stretch based on velocity
    final speed = math.min(2.2, _velocity.abs());
    final stretchX = 1.0 + speed * 0.065;
    final compressY = 1.0 / math.sqrt(stretchX);

    final currentTabX = _sliderX;
    // Base position starts at left: 36px inside 464px pill
    final trayLeft = 36.0 + currentTabX + (_kSlotWidth / 2.0);

    // Idle size: 92px x 80px. Hold size: 138px x 128px (protruding!)
    final trayWidth = _isHolding ? 138.0 : 92.0;
    final trayHeight = _isHolding ? 128.0 : 80.0;
    final borderRadius = _isHolding ? 44.0 : 21.0;

    return Positioned(
      left: trayLeft - (trayWidth / 2.0),
      top: 62.0 - (trayHeight / 2.0),
      child: IgnorePointer(
        child: Transform.scale(
          scaleX: stretchX,
          scaleY: compressY,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: const Cubic(0.22, 1.28, 0.32, 1.0),
            width: trayWidth,
            height: trayHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: _isHolding
                  ? RadialGradient(
                      center: Alignment.center,
                      radius: 0.9,
                      colors: isDark
                          ? [
                              const Color(0xFF100C1C).withValues(alpha: 0.88),
                              const Color(0xFF161028).withValues(alpha: 0.78),
                              const Color(0xFF7864AF).withValues(alpha: 0.28),
                              const Color(0xFFF0EBFF).withValues(alpha: 0.38),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.94),
                              const Color(0xFFEDE7FB).withValues(alpha: 0.85),
                              const Color(0xFFC7B3F5).withValues(alpha: 0.45),
                              const Color(0xFF8B5CF6).withValues(alpha: 0.55),
                            ],
                      stops: const [0.0, 0.54, 0.84, 1.0],
                    )
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? [
                              const Color(0xFF52447E).withValues(alpha: 0.45),
                              const Color(0xFF302650).withValues(alpha: 0.38),
                              const Color(0xFF483A70).withValues(alpha: 0.52),
                            ]
                          : [
                              const Color(0xFFECE5FB).withValues(alpha: 0.85),
                              const Color(0xFFDDD2F8).withValues(alpha: 0.75),
                              const Color(0xFFE5DBFA).withValues(alpha: 0.85),
                            ],
                    ),
              border: Border.all(
                color: _isHolding
                    ? (isDark ? Colors.white.withValues(alpha: 0.78) : const Color(0xFF6B42FF))
                    : (isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0xFF6B42FF).withValues(alpha: 0.25)),
                width: _isHolding ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: _isHolding ? 0.78 : 0.55)
                      : const Color(0xFF381868).withValues(alpha: _isHolding ? 0.24 : 0.10),
                  blurRadius: _isHolding ? 40 : 18,
                  offset: Offset(0, _isHolding ? 14 : 6),
                ),
                if (_isHolding)
                  BoxShadow(
                    color: const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.38 : 0.22),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Top & Bottom Specular Meniscus Bands on Hold
                if (_isHolding) ...[
                  Positioned(
                    top: 3,
                    left: 20,
                    right: 20,
                    height: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.88),
                            Colors.white.withValues(alpha: 0.35),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 3,
                    left: 20,
                    right: 20,
                    height: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.88),
                            Colors.white.withValues(alpha: 0.35),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // 3D Glossy Purple Jelly Capsule in Idle State (78px x 42px)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 240),
                  opacity: _isHolding ? 0.0 : 1.0,
                  child: Container(
                    margin: const EdgeInsets.only(top: 5.5),
                    width: 78,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.3),
                        radius: 0.8,
                        colors: isDark
                            ? const [
                                Color(0xFF7038E8),
                                Color(0xFF511EC4),
                                Color(0xFF350F96),
                                Color(0xFF200460),
                              ]
                            : const [
                                Color(0xFF8B5CF6),
                                Color(0xFF7C3AED),
                                Color(0xFF6D28D9),
                                Color(0xFF4C1D95),
                              ],
                        stops: const [0.0, 0.42, 0.78, 1.0],
                      ),
                      border: Border.all(
                        color: const Color(0xFFDCC3FF).withValues(alpha: 0.45),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7838F5).withValues(alpha: 0.45),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.70 : 0.20),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
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
                                  Colors.white.withValues(alpha: 0.65),
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
      top: 22.0,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Wrap
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: const Cubic(0.34, 1.56, 0.64, 1.0),
                    transform: Matrix4.translationValues(
                      0.0,
                      _isHolding
                          ? (isActive ? 3.0 : 12.0)
                          : (isActive ? 1.0 : 0.0),
                      0.0,
                    ),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 320),
                      scale: _isHolding
                          ? (isActive ? 1.18 : 0.88)
                          : (isActive ? 1.05 : 1.0),
                      child: Icon(
                        isActive ? tab.iconData : tab.inactiveIconData,
                        size: 26,
                        color: isActive
                            ? Colors.white
                            : (isDark ? const Color(0xFF9E99AD) : const Color(0xFF6B6580)),
                        shadows: isActive
                            ? [
                                Shadow(
                                  color: _isHolding ? Colors.white : const Color(0xFFE1D2FF),
                                  blurRadius: _isHolding ? 14 : 6,
                                ),
                                const Shadow(
                                  color: Color(0xFF100330),
                                  blurRadius: 4,
                                  offset: Offset(0, 1.5),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Label Text
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: _isHolding ? (isActive ? 1.0 : 0.0) : 1.0,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? (isDark ? const Color(0xFFEBE6F6) : const Color(0xFF38157A))
                            : (isDark ? const Color(0xFF8F8A9E) : const Color(0xFF756F88)),
                        shadows: isActive
                            ? [
                                Shadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.75 : 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(tab.label),
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
