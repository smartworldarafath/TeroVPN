import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final itemWidth = totalWidth / items.length;
        const pillWidth = 64.0;
        const pillHeight = 32.0;

        // Exact horizontal centering of the active pill over the icon of the current tab
        final pillLeft = (currentIndex * itemWidth) + (itemWidth / 2) - (pillWidth / 2);

        return Container(
          height: 68,
          decoration: BoxDecoration(
            color: ProtonColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: ProtonColors.cardBorder.withOpacity(0.8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Sliding Active Bubble
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: pillLeft,
                top: 8,
                width: pillWidth,
                height: pillHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: ProtonColors.activePill,
                    borderRadius: BorderRadius.circular(16),
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
                                color: isSelected ? Colors.white : ProtonColors.textSecondary,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: ProtonTypography.labelSmall.copyWith(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? ProtonColors.activeLabel
                                  : ProtonColors.textSecondary,
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
        );
      },
    );
  }
}
