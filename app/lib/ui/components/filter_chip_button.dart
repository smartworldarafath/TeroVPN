import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/theme_manager.dart';

class FilterChipButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterChipButton({
    super.key,
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLiquid = ThemeManager.instance.isLiquidGlass;
    final isDark = ThemeManager.instance.isDarkMode;

    final unselectedBg = isDark
        ? (isLiquid ? const Color(0xFF1E1B2E).withValues(alpha: 0.65) : ProtonColors.chipBackground)
        : (isLiquid ? Colors.white.withValues(alpha: 0.90) : Colors.white);

    final unselectedBorder = isDark
        ? (isLiquid ? Colors.white.withValues(alpha: 0.10) : ProtonColors.cardBorder.withValues(alpha: 0.6))
        : (isLiquid ? Colors.white.withValues(alpha: 0.95) : const Color(0xFFE5E3ED));

    final unselectedTextColor = isDark ? ProtonColors.textLight : const Color(0xFF1D1536);
    final unselectedIconColor = isDark ? ProtonColors.textLight : const Color(0xFF1D1536);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isLiquid ? 20 : 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6B42FF) : unselectedBg,
            borderRadius: BorderRadius.circular(isLiquid ? 20 : 12),
            border: Border.all(
              color: isSelected ? const Color(0xFF6B42FF) : unselectedBorder,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.45 : 0.35),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : (isDark
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF5D5380).withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ]),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : unselectedIconColor,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isSelected ? Colors.white : unselectedTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
