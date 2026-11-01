import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';

/// 100% Faithful Implementation of "00003.html" (Liquid Glass Lens Navigation Bar)
/// Features:
/// - Exact 464px x 97px baseline dimensions with responsive scaling.
/// - Elevated refractive optical lens with dual curved specular reflection meniscus.
/// - Interactive Hold & Drag Left/Right gesture physics with rubber-banding, velocity-based stretch/compress, and inertia flick release.
/// - Real-time hovered tab tracking and smooth spring transitions.
/// - Full Light Mode and Dark Mode support.
class Dock2LensBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final bool isInteractivePreview;

  const Dock2LensBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.isInteractivePreview = false,
  });

  @override
  State<Dock2LensBar> createState() => _Dock2LensBarState();
}

class _Dock2LensBarState extends State<Dock2LensBar>
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

  static const List<_Dock2TabItem> _tabs = [
    _Dock2TabItem(
      label: 'Home',
      iconData: Icons.shield_rounded,
      inactiveIconData: Icons.shield_outlined,
    ),
    _Dock2TabItem(
      label: 'Countries',
      iconData: Icons.language_rounded,
      inactiveIconData: Icons.language_outlined,
    ),
    _Dock2TabItem(
      label: 'Profiles',
      iconData: Icons.layers_rounded,
      inactiveIconData: Icons.layers_outlined,
    ),
    _Dock2TabItem(
      label: 'Settings',
      iconData: Icons.tune_rounded,
      inactiveIconData: Icons.tune_outlined,
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
      duration: const Duration(milliseconds: 460),
    );
  }

  @override
  void didUpdateWidget(covariant Dock2LensBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex && !_isDragging) {
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

    final effectiveScale = scale > 0 ? scale : 1.0;
    final localX = (e.position.dx - barLeft) / effectiveScale - 36.0;
    final tappedSlot = (localX / _kSlotWidth).floor().clamp(0, _kTotalTabs - 1);

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

    // Rubber-band resistance at boundaries
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
      // Momentum projection on flick release
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
              final scale = math.min(1.0, (maxWidth - 16) / 464.0);
              const barWidth = 464.0;
              final scaledWidth = barWidth * scale;
              final barLeft = (maxWidth - scaledWidth) / 2.0;

              return SizedBox(
                height: 124, // ample height for protruding lens
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
                          // 1. Ambient Halo
                          _buildAmbientHalo(isDark),

                          // 2. Main Pill Bar (464px x 97px)
                          _buildMainPill(isDark),

                          // 3. Sliding Liquid Glass Lens Assembly
                          _buildLensSlider(isDark),

                          // 4. Tabs Layer
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
                      const Color(0xFF6E46DC).withValues(alpha: 0.40),
                      const Color(0xFF4A1E9E).withValues(alpha: 0.20),
                      Colors.transparent,
                    ]
                  : [
                      const Color(0xFF7C3AED).withValues(alpha: 0.28),
                      const Color(0xFF9333EA).withValues(alpha: 0.12),
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
                  const Color(0xFF1B142E).withValues(alpha: 0.90),
                  const Color(0xFF0F0B1A).withValues(alpha: 0.95),
                  const Color(0xFF150F24).withValues(alpha: 0.92),
                ]
              : [
                  Colors.white.withValues(alpha: 0.94),
                  const Color(0xFFF1ECFA).withValues(alpha: 0.90),
                  const Color(0xFFF8F5FF).withValues(alpha: 0.96),
                ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.25)
              : const Color(0xFF7C3AED).withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.80) : const Color(0xFF281050).withValues(alpha: 0.18),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: isDark ? const Color(0xFF6E46DC).withValues(alpha: 0.32) : const Color(0xFF7C3AED).withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 24,
            right: 24,
            height: 42,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(999)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.20 : 0.45),
                    Colors.white.withValues(alpha: isDark ? 0.02 : 0.06),
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

  Widget _buildLensSlider(bool isDark) {
    final speed = math.min(2.2, _velocity.abs());
    final stretchX = 1.0 + speed * 0.065;
    final compressY = 1.0 / math.sqrt(stretchX);

    final currentTabX = _sliderX;
    final lensCenterLeft = 36.0 + currentTabX + (_kSlotWidth / 2.0);

    // Idle size: 104px x 90px. Hold size: 140px x 130px (protruding!)
    final lensWidth = _isHolding ? 140.0 : 104.0;
    final lensHeight = _isHolding ? 130.0 : 90.0;
    final borderRadius = _isHolding ? 46.0 : 26.0;

    return Positioned(
      left: lensCenterLeft - (lensWidth / 2.0),
      top: 48.5 - (lensHeight / 2.0),
      child: IgnorePointer(
        child: Transform.scale(
          scaleX: stretchX,
          scaleY: compressY,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: const Cubic(0.18, 0.9, 0.28, 1.3),
            width: lensWidth,
            height: lensHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.95,
                colors: isDark
                    ? [
                        const Color(0xFF2E1C58).withValues(alpha: _isHolding ? 0.85 : 0.65),
                        const Color(0xFF1D113B).withValues(alpha: _isHolding ? 0.92 : 0.75),
                        const Color(0xFF5B34B5).withValues(alpha: 0.35),
                        const Color(0xFFFFFFFF).withValues(alpha: 0.45),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.95),
                        const Color(0xFFEADBFF).withValues(alpha: 0.82),
                        const Color(0xFFC4A2FF).withValues(alpha: 0.40),
                        const Color(0xFF7C3AED).withValues(alpha: 0.50),
                      ],
                stops: const [0.0, 0.55, 0.82, 1.0],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: _isHolding ? 0.85 : 0.55),
                width: _isHolding ? 1.6 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.70) : const Color(0xFF381468).withValues(alpha: 0.22),
                  blurRadius: _isHolding ? 38 : 20,
                  offset: Offset(0, _isHolding ? 12 : 6),
                ),
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: _isHolding ? 0.55 : 0.35),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Top Refractive Meniscus
                Positioned(
                  top: 4,
                  left: 18,
                  right: 18,
                  height: 18,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.90),
                          Colors.white.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Bottom Refractive Meniscus
                Positioned(
                  bottom: 4,
                  left: 18,
                  right: 18,
                  height: 18,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.85),
                          Colors.white.withValues(alpha: 0.20),
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
    );
  }

  Widget _buildTabsLayer(bool isDark) {
    return Positioned(
      left: 36,
      top: 8.5,
      width: _kSlotWidth * _kTotalTabs,
      height: 80,
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
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: const Cubic(0.34, 1.56, 0.64, 1.0),
                  transform: Matrix4.translationValues(
                    0.0,
                    _isHolding
                        ? (isActive ? 2.0 : 12.0)
                        : (isActive ? 1.0 : 0.0),
                    0.0,
                  ),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 300),
                    scale: _isHolding
                        ? (isActive ? 1.18 : 0.88)
                        : (isActive ? 1.05 : 1.0),
                    child: Icon(
                      isActive ? tab.iconData : tab.inactiveIconData,
                      size: 26,
                      color: isActive
                          ? Colors.white
                          : (isDark ? const Color(0xFFA19AB5) : const Color(0xFF6B6482)),
                      shadows: isActive
                          ? [
                              Shadow(
                                color: _isHolding ? Colors.white : const Color(0xFFC084FC),
                                blurRadius: _isHolding ? 14 : 8,
                              ),
                              const Shadow(
                                color: Color(0xFF13052E),
                                blurRadius: 4,
                                offset: Offset(0, 1.5),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: _isHolding ? (isActive ? 1.0 : 0.0) : 1.0,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? (isDark ? const Color(0xFFF3EDFF) : const Color(0xFF3B1578))
                          : (isDark ? const Color(0xFF948EAA) : const Color(0xFF7A7292)),
                      shadows: isActive
                          ? [
                              Shadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.70 : 0.15),
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
    );
  }
}

class _Dock2TabItem {
  final String label;
  final IconData iconData;
  final IconData inactiveIconData;

  const _Dock2TabItem({
    required this.label,
    required this.iconData,
    required this.inactiveIconData,
  });
}
