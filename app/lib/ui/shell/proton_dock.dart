import 'dart:ui';
import 'package:flutter/material.dart';
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
    final isDark = ThemeManager.instance.isDarkMode;
    final isLiquid = ThemeManager.instance.isLiquidGlass;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final itemWidth = totalWidth / items.length;
        const pillWidth = 58.0;
        const pillHeight = 32.0;

        // Exact horizontal centering of the active pill over the icon of current tab
        final pillLeft = (currentIndex * itemWidth) + (itemWidth / 2) - (pillWidth / 2);

        final dockRadius = BorderRadius.circular(isLiquid ? 36 : 20);

        final dockBg = isDark
            ? (isLiquid ? const Color(0xFF131122).withValues(alpha: 0.68) : const Color(0xFF181526))
            : (isLiquid ? Colors.white.withValues(alpha: 0.76) : Colors.white);

        final dockBorderColor = isDark
            ? (isLiquid ? Colors.white.withValues(alpha: 0.12) : const Color(0xFF2E2A42))
            : (isLiquid ? Colors.white.withValues(alpha: 0.95) : const Color(0xFFE5E3ED));

        return Container(
          height: isLiquid ? 72 : 66,
          decoration: BoxDecoration(
            borderRadius: dockRadius,
            boxShadow: isLiquid
                ? [
                    if (isDark) ...[
                      BoxShadow(
                        color: const Color(0xFF6B42FF).withValues(alpha: 0.50),
                        blurRadius: 40,
                        spreadRadius: 3,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.65),
                        blurRadius: 24,
                        offset: const Offset(0, 4),
                      ),
                    ] else ...[
                      BoxShadow(
                        color: const Color(0xFF6B42FF).withValues(alpha: 0.28),
                        blurRadius: 36,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: const Color(0xFF5D5380).withValues(alpha: 0.10),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: dockRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: isLiquid ? 28 : 0,
                sigmaY: isLiquid ? 28 : 0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: dockBg,
                  borderRadius: dockRadius,
                  border: Border.all(
                    color: dockBorderColor,
                    width: 1.2,
                  ),
                  gradient: isLiquid
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  Colors.white.withValues(alpha: 0.08),
                                  Colors.white.withValues(alpha: 0.02),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.12),
                                ]
                              : [
                                  Colors.white.withValues(alpha: 0.45),
                                  Colors.white.withValues(alpha: 0.10),
                                  Colors.transparent,
                                  const Color(0xFF5D5380).withValues(alpha: 0.04),
                                ],
                          stops: const [0.0, 0.35, 0.70, 1.0],
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    // Sliding Active Bubble
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      left: pillLeft,
                      top: 10,
                      width: pillWidth,
                      height: pillHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B42FF),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B42FF).withValues(alpha: 0.45),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tab Buttons
                    Row(
                      children: List.generate(items.length, (index) {
                        final item = items[index];
                        final isSelected = index == currentIndex;

                        const inactiveColor = Color(0xFF757288);
                        const activeLabelColor = Color(0xFF6B42FF);

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
                                      color: isSelected ? Colors.white : inactiveColor,
                                      size: 21,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? activeLabelColor : inactiveColor,
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
