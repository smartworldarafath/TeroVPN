import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';

class DockItemData {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const DockItemData({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}

class ProtonDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const ProtonDock({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  static const List<DockItemData> items = [
    DockItemData(
      label: 'Home',
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
    ),
    DockItemData(
      label: 'Countries',
      activeIcon: Icons.public_rounded,
      inactiveIcon: Icons.public_outlined,
    ),
    DockItemData(
      label: 'Profiles',
      activeIcon: Icons.bookmark_rounded,
      inactiveIcon: Icons.bookmark_border_rounded,
    ),
    DockItemData(
      label: 'Settings',
      activeIcon: Icons.settings_rounded,
      inactiveIcon: Icons.settings_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isLiquid = ThemeManager.instance.isLiquidGlass;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final itemWidth = totalWidth / items.length;
        const pillWidth = 58.0;
        const pillHeight = 32.0;

        // Exact horizontal centering of the active pill over the icon of the current tab
        final pillLeft = (currentIndex * itemWidth) + (itemWidth / 2) - (pillWidth / 2);

        final dockRadius = BorderRadius.circular(isLiquid ? 36 : 22);

        return Container(
          height: isLiquid ? 72 : 68,
          decoration: BoxDecoration(
            borderRadius: dockRadius,
            boxShadow: [
              if (isLiquid) ...[
                BoxShadow(
                  color: const Color(0xFF6B42FF).withValues(alpha: 0.42),
                  blurRadius: 36,
                  spreadRadius: 3,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 22,
                  offset: const Offset(0, 4),
                ),
              ] else ...[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ],
          ),
          child: ClipRRect(
            borderRadius: dockRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: isLiquid ? 20 : 0,
                sigmaY: isLiquid ? 20 : 0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isLiquid
                      ? const Color(0xFF131122).withValues(alpha: 0.85)
                      : ProtonColors.surface,
                  borderRadius: dockRadius,
                  border: Border.all(
                    color: isLiquid
                        ? Colors.white.withValues(alpha: 0.10)
                        : ProtonColors.cardBorder.withValues(alpha: 0.8),
                    width: 1.0,
                  ),
                ),
                child: Stack(
                  children: [
                    // Sliding Active Bubble
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      left: pillLeft,
                      top: isLiquid ? 10 : 8,
                      width: pillWidth,
                      height: pillHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isLiquid ? const Color(0xFF6B42FF) : ProtonColors.activePill,
                          borderRadius: BorderRadius.circular(isLiquid ? 16 : 16),
                        ),
                      ),
                    ),

                    // Tab Buttons
                    Row(
                      children: List.generate(items.length, (index) {
                        final item = items[index];
                        final isSelected = index == currentIndex;

                        return Expanded(
                          child: InkWell(
                            onTap: () => onTabSelected(index),
                            borderRadius: BorderRadius.circular(20),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 32,
                                  child: Center(
                                    child: Icon(
                                      isSelected ? item.activeIcon : item.inactiveIcon,
                                      color: isSelected
                                          ? Colors.white
                                          : (isLiquid
                                              ? const Color(0xFF757288)
                                              : ProtonColors.textSecondary),
                                      size: 21,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.label,
                                  style: ProtonTypography.labelSmall.copyWith(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? (isLiquid ? const Color(0xFF8B6CFF) : ProtonColors.activeLabel)
                                        : (isLiquid
                                            ? const Color(0xFF757288)
                                            : ProtonColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
