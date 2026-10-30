import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../../core/app_preferences.dart';

enum ToastAnimationMode {
  auto,
  dynamicIsland,
  cornerPunchHole,
  waterDroplet,
}

/// Universal Device-Adaptive Top Dock Glass Toast Notification
/// Supports:
/// 1. Dynamic Island (Center punch-hole) - expands directly from center camera cutout
/// 2. Corner Punch-Hole - expands directly from corner camera cutout
/// 3. Water Droplet (No punch-hole) - emerges from very top, hangs for 2.5s, falls down to bottom with gravity
class TopDockToast {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    IconData icon = Icons.check_circle_rounded,
    Color? iconColor,
    Duration duration = const Duration(milliseconds: 2500),
    ToastAnimationMode? mode,
  }) {
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context, rootOverlay: true);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _TopDockToastWidget(
        message: message,
        title: title,
        icon: icon,
        iconColor: iconColor,
        duration: duration,
        mode: mode ?? _resolveMode(context),
        onDismissed: () {
          if (_currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static ToastAnimationMode _resolveMode(BuildContext context) {
    // Check manual override in preferences if set
    final pref = AppPreferences.toastAnimationMode;
    if (pref == 'island') return ToastAnimationMode.dynamicIsland;
    if (pref == 'corner') return ToastAnimationMode.cornerPunchHole;
    if (pref == 'droplet') return ToastAnimationMode.waterDroplet;

    final mediaQuery = MediaQuery.of(context);
    final topInset = mediaQuery.padding.top;
    final screenWidth = mediaQuery.size.width;

    // Check display features for cutouts
    for (final feature in mediaQuery.displayFeatures) {
      if (feature.type == ui.DisplayFeatureType.cutout) {
        final centerDx = feature.bounds.center.dx;
        if ((centerDx - screenWidth / 2).abs() < 45) {
          return ToastAnimationMode.dynamicIsland;
        } else {
          return ToastAnimationMode.cornerPunchHole;
        }
      }
    }

    // Default to dynamic island if tall status bar (standard on punch-hole devices),
    // otherwise water droplet if no notch/cutout or classic aspect
    if (topInset >= 36) {
      return ToastAnimationMode.dynamicIsland;
    }
    return ToastAnimationMode.waterDroplet;
  }
}

class _TopDockToastWidget extends StatefulWidget {
  final String message;
  final String? title;
  final IconData icon;
  final Color? iconColor;
  final Duration duration;
  final ToastAnimationMode mode;
  final VoidCallback onDismissed;

  const _TopDockToastWidget({
    required this.message,
    this.title,
    required this.icon,
    this.iconColor,
    required this.duration,
    required this.mode,
    required this.onDismissed,
  });

  @override
  State<_TopDockToastWidget> createState() => _TopDockToastWidgetState();
}

class _TopDockToastWidgetState extends State<_TopDockToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _expandProgress;
  late Animation<double> _exitProgress;
  Timer? _holdTimer;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _expandProgress = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _exitProgress = CurvedAnimation(
      parent: _animController,
      curve: widget.mode == ToastAnimationMode.waterDroplet
          ? Curves.easeInQuad // Acceleration downward like water falling
          : Curves.easeInOutCubic,
    );

    _animController.forward().then((_) {
      _holdTimer = Timer(widget.duration, () {
        if (mounted) {
          setState(() {
            _isExiting = true;
          });
          // Animate out
          _animController.reverse().then((_) {
            widget.onDismissed();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topInset = mediaQuery.padding.top;
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    final isDark = ThemeManager.instance.isDarkMode;
    final isLiquid = ThemeManager.instance.isLiquidGlass;

    final textPrimary = isDark ? Colors.white : const Color(0xFF161224);
    final textSecondary = isDark
        ? Colors.white.withValues(alpha: 0.70)
        : const Color(0xFF5E5873);
    final defaultIconColor =
        widget.iconColor ?? (isDark ? const Color(0xFF00E676) : const Color(0xFF00A36C));

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final progress = _isExiting ? (1.0 - _exitProgress.value) : _expandProgress.value;

        // Target geometry for the dock pill
        const double targetWidth = 320.0;
        const double targetHeight = 52.0;
        final double finalWidth = targetWidth.clamp(260.0, screenWidth - 32);

        double currentWidth;
        double currentHeight;
        Offset currentOffset;
        double opacity = _isExiting ? (1.0 - _animController.value) : _animController.value.clamp(0.0, 1.0);
        double borderRadius = 26.0;

        switch (widget.mode) {
          case ToastAnimationMode.dynamicIsland:
            // Expands directly out of center camera cutout
            final centerCutoutX = screenWidth / 2;
            final centerCutoutY = topInset > 0 ? (topInset * 0.45) : 12.0;

            if (!_isExiting) {
              // Morph from camera notch pill
              currentWidth = ui.lerpDouble(24.0, finalWidth, progress)!;
              currentHeight = ui.lerpDouble(14.0, targetHeight, progress)!;
              final currentY = ui.lerpDouble(centerCutoutY, topInset + 10.0, progress)!;
              currentOffset = Offset(centerCutoutX - (currentWidth / 2), currentY);
            } else {
              // Contract back into center camera notch
              final exitT = _animController.value;
              currentWidth = ui.lerpDouble(24.0, finalWidth, exitT)!;
              currentHeight = ui.lerpDouble(14.0, targetHeight, exitT)!;
              final currentY = ui.lerpDouble(centerCutoutY, topInset + 10.0, exitT)!;
              currentOffset = Offset(centerCutoutX - (currentWidth / 2), currentY);
              opacity = exitT.clamp(0.0, 1.0);
            }
            break;

          case ToastAnimationMode.cornerPunchHole:
            // Expands from corner camera position (typically top-left ~36px from left)
            const cornerCutoutX = 36.0;
            final cornerCutoutY = topInset > 0 ? (topInset * 0.45) : 12.0;
            final targetX = (screenWidth - finalWidth) / 2;

            if (!_isExiting) {
              currentWidth = ui.lerpDouble(18.0, finalWidth, progress)!;
              currentHeight = ui.lerpDouble(18.0, targetHeight, progress)!;
              final currentX = ui.lerpDouble(cornerCutoutX, targetX, progress)!;
              final currentY = ui.lerpDouble(cornerCutoutY, topInset + 10.0, progress)!;
              currentOffset = Offset(currentX, currentY);
            } else {
              final exitT = _animController.value;
              currentWidth = ui.lerpDouble(18.0, finalWidth, exitT)!;
              currentHeight = ui.lerpDouble(18.0, targetHeight, exitT)!;
              final currentX = ui.lerpDouble(cornerCutoutX, targetX, exitT)!;
              final currentY = ui.lerpDouble(cornerCutoutY, topInset + 10.0, exitT)!;
              currentOffset = Offset(currentX, currentY);
              opacity = exitT.clamp(0.0, 1.0);
            }
            break;

          case ToastAnimationMode.waterDroplet:
          case ToastAnimationMode.auto:
            // Devices without punch-hole:
            // Emerges from top like a liquid water droplet, hangs for 2.5s, then falls towards bottom
            currentWidth = finalWidth;
            currentHeight = targetHeight;
            final targetX = (screenWidth - finalWidth) / 2;

            if (!_isExiting) {
              // Dropping down from very top
              final startY = -60.0;
              final endY = topInset + 12.0;
              final currentY = ui.lerpDouble(startY, endY, progress)!;
              currentOffset = Offset(targetX, currentY);
            } else {
              // User requirement: "falls towards the bottom of the screen like a water droplet and disappear"
              final startY = topInset + 12.0;
              final dropDistance = screenHeight * 0.55;
              final exitFallProgress = (1.0 - _animController.value); // 0 to 1
              final currentY = startY + (dropDistance * exitFallProgress * exitFallProgress);
              currentOffset = Offset(targetX, currentY);
              opacity = (1.0 - exitFallProgress).clamp(0.0, 1.0);
              borderRadius = ui.lerpDouble(26.0, 36.0, exitFallProgress)!;
            }
            break;
        }

        final showContent = progress > 0.45;

        return Positioned(
          left: currentOffset.dx,
          top: currentOffset.dy,
          width: currentWidth,
          height: currentHeight,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF181427).withValues(alpha: isLiquid ? 0.88 : 0.96)
                          : Colors.white.withValues(alpha: isLiquid ? 0.92 : 0.98),
                      borderRadius: BorderRadius.circular(borderRadius),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.16)
                            : Colors.white.withValues(alpha: 0.95),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? const Color(0xFF6B42FF).withValues(alpha: 0.35)
                              : Colors.black.withValues(alpha: 0.10),
                          blurRadius: 18,
                          spreadRadius: 1,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: showContent
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: defaultIconColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    widget.icon,
                                    color: defaultIconColor,
                                    size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (widget.title != null) ...[
                                      Text(
                                        widget.title!,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 1),
                                    ],
                                    Text(
                                      widget.message,
                                      style: TextStyle(
                                        fontSize: widget.title != null ? 11.5 : 13.0,
                                        fontWeight: widget.title != null
                                            ? FontWeight.w500
                                            : FontWeight.w600,
                                        color: widget.title != null
                                            ? textSecondary
                                            : textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
