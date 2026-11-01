import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';

/// 100% Pixel-Faithful Implementation of "dock style 03.html"
/// 3D Glassmorphic Navigation Bar with Spring Glide & Liquid Jelly Stretch
///
/// Adaptive:
/// - Dark Mode: Deep obsidian cosmic glass with ambient purple glow.
/// - Light Mode: Frosted iridescent pearl glass with electric royal purple capsule and crisp dark icons.
class Dock3CapsuleBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final bool isInteractivePreview;

  const Dock3CapsuleBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.isInteractivePreview = false,
  });

  @override
  State<Dock3CapsuleBar> createState() => _Dock3CapsuleBarState();
}

class _Dock3CapsuleBarState extends State<Dock3CapsuleBar>
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

  static const List<_Dock3TabItem> _tabs = [
    _Dock3TabItem(
      label: 'Home',
      iconData: Icons.home_rounded,
      inactiveIconData: Icons.home_outlined,
    ),
    _Dock3TabItem(
      label: 'Countries',
      iconData: Icons.public_rounded,
      inactiveIconData: Icons.public_outlined,
    ),
    _Dock3TabItem(
      label: 'Profiles',
      iconData: Icons.bookmark_rounded,
      inactiveIconData: Icons.bookmark_border_rounded,
    ),
    _Dock3TabItem(
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
      duration: const Duration(milliseconds: 480),
    );
  }

  @override
  void didUpdateWidget(Dock3CapsuleBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      final target = widget.currentIndex.clamp(0, _kTotalTabs - 1);
      if (target != _activeTab) {
        _animateToTab(target);
      }
    }
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _animateToTab(int targetTab) {
    targetTab = targetTab.clamp(0, _kTotalTabs - 1);
    final startX = _sliderX;
    final endX = targetTab * _kSlotWidth;

    setState(() {
      _activeTab = targetTab;
      _hoveredTab = targetTab;
      _isGliding = true;
    });

    _springController.stop();
    _springController.reset();

    // Cubic(0.25, 1.08, 0.32, 1.0) exact spring curve
    _springAnimation = Tween<double>(begin: startX, end: endX).animate(
      CurvedAnimation(
        parent: _springController,
        curve: const Cubic(0.25, 1.08, 0.32, 1.0),
      ),
    )..addListener(() {
        setState(() {
          _sliderX = _springAnimation!.value;
        });
      });

    _springController.forward().then((_) {
      if (mounted) {
        setState(() {
          _isGliding = false;
          _velocity = 0.0;
        });
      }
    });

    widget.onTabSelected(targetTab);
  }

  int _snapTabFromSliderX(double sx, double v) {
    int nearest = (sx / _kSlotWidth).round();
    if (v.abs() > 0.45) {
      if (v > 0) {
        nearest = (sx / _kSlotWidth).floor() + 1;
      } else {
        nearest = (sx / _kSlotWidth).ceil() - 1;
      }
    }
    return nearest.clamp(0, _kTotalTabs - 1);
  }

  void _onPointerDown(PointerDownEvent e) {
    _springController.stop();
    _isHolding = true;
    _isDragging = false;
    _isGliding = false;
    _dragStartLocalX = e.localPosition.dx;
    _dragStartSliderX = _activeTab * _kSlotWidth;
    _sliderX = _dragStartSliderX;
    _hoveredTab = _activeTab;
    _lastX = e.localPosition.dx;
    _lastDragTime = DateTime.now().millisecondsSinceEpoch;
    _velocity = 0.0;
    setState(() {});
  }

  void _onPointerMove(PointerMoveEvent e) {
    final dx = e.localPosition.dx - _dragStartLocalX;
    if (dx.abs() > 4.0) {
      _isDragging = true;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final dt = math.max(1, now - _lastDragTime);
    _velocity = (e.localPosition.dx - _lastX) / dt;
    _lastX = e.localPosition.dx;
    _lastDragTime = now;

    final targetX = (_dragStartSliderX + dx).clamp(_kMinX, _kMaxX);
    _sliderX = targetX;
    _hoveredTab = (_sliderX / _kSlotWidth).round().clamp(0, _kTotalTabs - 1);
    setState(() {});
  }

  void _onPointerUp(PointerUpEvent e) {
    final dx = e.localPosition.dx - _dragStartLocalX;
    if (!_isDragging && dx.abs() < 10.0) {
      // Tap on a tab
      final tapped = ((e.localPosition.dx - 36.0) / _kSlotWidth).floor().clamp(0, _kTotalTabs - 1);
      _isHolding = false;
      _isDragging = false;
      _animateToTab(tapped);
      return;
    }

    // Drag release with momentum velocity
    final finalTab = _snapTabFromSliderX(_sliderX, _velocity);
    setState(() {
      _isHolding = false;
      _isDragging = false;
    });
    _animateToTab(finalTab);
  }

  void _onPointerCancel() {
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
              final scale = math.min(1.0, (availableWidth - 24.0) / 464.0);
              final scaledWidth = 464.0 * scale;
              final scaledHeight = 120.0 * scale;

              return SizedBox(
                width: availableWidth,
                height: 120.0,
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
                        height: 120.0,
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
                              _buildAmbientHalo(isDark),
                              _buildMainPill(isDark),
                              _buildActiveSlider(isDark),
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

  /// Outer Purple Ambient Glow (492px x 118px)
  Widget _buildAmbientHalo(bool isDark) {
    return Positioned(
      width: 492,
      height: 118,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.85,
              colors: isDark
                  ? [
                      const Color(0xFF6034B9).withValues(alpha: 0.36),
                      const Color(0xFF401C82).withValues(alpha: 0.22),
                      Colors.transparent,
                    ]
                  : [
                      const Color(0xFF9060FA).withValues(alpha: 0.20),
                      const Color(0xFFB18CFA).withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
              stops: const [0.0, 0.55, 0.78],
            ),
          ),
        ),
      ),
    );
  }

  /// Main Outer Pill Container (464px x 97px)
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
                  Color(0xFF1B172A),
                  Color(0xFF141022),
                  Color(0xFF181329),
                  Color(0xFF231C38),
                ],
                stops: [0.0, 0.46, 0.76, 1.0],
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
                stops: const [0.0, 0.46, 0.76, 1.0],
              ),
        border: Border.all(
          color: isDark
              ? const Color(0xFFC3B9E1).withValues(alpha: 0.22)
              : const Color(0xFF6B42FF).withValues(alpha: 0.20),
          width: 1.2,
        ),
        boxShadow: isDark
            ? const [
                BoxShadow(
                  color: Color(0xE004010A),
                  blurRadius: 38,
                  offset: Offset(0, 18),
                ),
                BoxShadow(
                  color: Color(0x474E269B),
                  blurRadius: 28,
                  spreadRadius: 2,
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
          // Top glass edge highlight
          Positioned(
            top: 0,
            left: 24,
            right: 24,
            height: 44,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(999)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.14 : 0.80),
                    Colors.white.withValues(alpha: isDark ? 0.02 : 0.15),
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

  /// Sliding Active Indicator Assembly (92px x 80px tray + 78px x 42px capsule)
  Widget _buildActiveSlider(bool isDark) {
    final speed = math.min(2.0, _velocity.abs());
    final stretchX = _isGliding ? 1.075 : (1.0 + speed * 0.045);
    final compressY = _isGliding ? 0.93 : (1.0 / math.sqrt(stretchX));

    final currentTabX = _sliderX;
    final trayLeft = 36.0 + currentTabX + (_kSlotWidth / 2.0);

    return Positioned(
      left: trayLeft - (92.0 / 2.0),
      top: 60.0 - (80.0 / 2.0),
      child: IgnorePointer(
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(stretchX, compressY, 1.0),
          child: Container(
            width: 92,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(21),
              gradient: isDark
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x85382E56),
                        Color(0x75261E3E),
                        Color(0x94362C52),
                      ],
                      stops: [0.0, 0.54, 1.0],
                    )
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFEFE8FC).withValues(alpha: 0.90),
                        const Color(0xFFE4D7F7).withValues(alpha: 0.85),
                        const Color(0xFFDCCDF2).withValues(alpha: 0.92),
                      ],
                      stops: const [0.0, 0.54, 1.0],
                    ),
              border: Border.all(
                color: isDark
                    ? const Color(0xFFCDC3EB).withValues(alpha: 0.16)
                    : const Color(0xFF6B42FF).withValues(alpha: 0.22),
                width: 1.0,
              ),
              boxShadow: isDark
                  ? const [
                      BoxShadow(
                        color: Color(0xA604020C),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0xFF452478).withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 3D Glossy Royal Purple Jelly Capsule (78px x 42px)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 5.5),
                    width: 78,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: isDark
                          ? const RadialGradient(
                              center: Alignment(0, 0.12),
                              radius: 0.68,
                              colors: [
                                Color(0xFF5623C4),
                                Color(0xFF3D129C),
                                Color(0xFF280872),
                                Color(0xFF1D0458),
                              ],
                              stops: [0.0, 0.48, 0.82, 1.0],
                            )
                          : const RadialGradient(
                              center: Alignment(0, 0.12),
                              radius: 0.68,
                              colors: [
                                Color(0xFF6E38E8),
                                Color(0xFF5521C6),
                                Color(0xFF3E10A4),
                                Color(0xFF2E0782),
                              ],
                              stops: [0.0, 0.48, 0.82, 1.0],
                            ),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFFAF8AFA).withValues(alpha: 0.34)
                            : const Color(0xFFD6C2FF).withValues(alpha: 0.65),
                        width: 1.0,
                      ),
                      boxShadow: isDark
                          ? const [
                              BoxShadow(
                                color: Color(0xD90A031C),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                              BoxShadow(
                                color: Color(0x7A6C30E1),
                                blurRadius: 14,
                                spreadRadius: 1,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: const Color(0xFF34106F).withValues(alpha: 0.38),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                              BoxShadow(
                                color: const Color(0xFF6B42FF).withValues(alpha: 0.35),
                                blurRadius: 14,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Stack(
                      children: [
                        // Top Reflection Dome
                        Positioned(
                          top: 2,
                          left: 7,
                          right: 7,
                          height: 19,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFFF5EEFF).withValues(alpha: isDark ? 0.44 : 0.60),
                                  const Color(0xFFC3A5FA).withValues(alpha: isDark ? 0.20 : 0.30),
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

  /// Tabs Layer with Icons and Text
  Widget _buildTabsLayer(bool isDark) {
    return Positioned(
      left: 36,
      top: 20.0,
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
                  SizedBox(
                    height: 48,
                    child: Center(
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 280),
                        curve: const Cubic(0.34, 1.56, 0.64, 1.0),
                        scale: isActive ? 1.08 : 1.0,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isActive)
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFC6B5EB).withValues(alpha: isDark ? 0.35 : 0.45),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            Icon(
                              isActive ? tab.iconData : tab.inactiveIconData,
                              size: 25,
                              color: isActive
                                  ? const Color(0xFFFFFFFF)
                                  : (isDark
                                      ? const Color(0xFF9E99AD)
                                      : const Color(0xFF635C7A)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 13.5,
                      letterSpacing: -0.15,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? (isDark
                              ? const Color(0xFFEBE6F6)
                              : const Color(0xFF280A5E))
                          : (isDark
                              ? const Color(0xFF8F8A9E)
                              : const Color(0xFF5B5470)),
                    ),
                    child: Text(tab.label),
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

class _Dock3TabItem {
  final String label;
  final IconData iconData;
  final IconData inactiveIconData;

  const _Dock3TabItem({
    required this.label,
    required this.iconData,
    required this.inactiveIconData,
  });
}
