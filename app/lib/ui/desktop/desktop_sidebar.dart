import 'package:flutter/material.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../../core/models.dart';
import '../components/details_sheet.dart';

class DesktopSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final CoreStatus? status;

  const DesktopSidebar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;
        final isLiquid = ThemeManager.instance.isLiquidGlass;

        final sidebarBg = isDark
            ? (isLiquid
                ? const Color(0xFF0D0C15).withValues(alpha: 0.88)
                : const Color(0xFF100E1D))
            : (isLiquid
                ? Colors.white.withValues(alpha: 0.82)
                : const Color(0xFFF0F1F9));

        final borderColor = isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFF5D5380).withValues(alpha: 0.10);

        final titleColor = isDark ? Colors.white : const Color(0xFF1D1536);
        final infoIconColor = isDark ? const Color(0xFF7E7B8E) : const Color(0xFF8C899E);

        return Container(
          width: 220,
          decoration: BoxDecoration(
            color: sidebarBg,
            border: Border(
              right: BorderSide(
                color: borderColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B42FF),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.4 : 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.shield_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'TeroVPN',
                        style: ProtonTypography.titleMedium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: titleColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.info_outline_rounded,
                        color: infoIconColor,
                        size: 18,
                      ),
                      tooltip: 'Connection Details',
                      onPressed: () => DetailsSheet.show(context, status: status),
                    ),
                  ],
                ),
              ),

              // Navigation Items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _buildNavItem(
                      index: 1,
                      icon: Icons.public_rounded,
                      label: 'Countries',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _buildNavItem(
                      index: 2,
                      icon: Icons.bookmark_border_rounded,
                      label: 'Profiles',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _buildNavItem(
                      index: 3,
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Quick Theme Switcher Pill in Sidebar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => ThemeManager.instance.setDarkMode(!isDark),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFF6B42FF).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFF6B42FF).withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            size: 15,
                            color: isDark ? const Color(0xFFFFB800) : const Color(0xFF6B42FF),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isDark ? 'Light Mode' : 'Dark Mode',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF1D1536),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Version Footer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Text(
                  'v1.1.1 Desktop',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF9E9BAE),
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = currentIndex == index;

    final selectedBg = isDark
        ? const Color(0xFF261D4C)
        : const Color(0xFFE8E5F8);

    final itemColor = isSelected
        ? (isDark ? Colors.white : const Color(0xFF6B42FF))
        : (isDark ? const Color(0xFF8A889A) : const Color(0xFF757288));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTabSelected(index),
        borderRadius: BorderRadius.circular(12),
        hoverColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFF6B42FF).withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.4 : 0.3),
                    width: 1,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.20 : 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: isSelected ? 3 : 0,
                height: isSelected ? 18 : 0,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B6BFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (isSelected) const SizedBox(width: 8),
              Icon(
                icon,
                color: itemColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: itemColor,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
