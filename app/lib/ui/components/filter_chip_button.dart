import 'dart:ui' as ui;
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
    final isDark = ThemeManager.instance.isDarkMode;

    final unselectedBg = isDark
        ? const Color(0xFF1E1B2E).withValues(alpha: 0.65)
        : Colors.white.withValues(alpha: 0.78);

    final unselectedBorder = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.95);

    final unselectedTextColor = isDark ? ProtonColors.textLight : const Color(0xFF1D1536);
    final unselectedIconColor = isDark ? ProtonColors.textLight : const Color(0xFF1D1536);

    final chipRadius = BorderRadius.circular(20);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: chipRadius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: chipRadius,
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
          child: ClipRRect(
            borderRadius: chipRadius,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6B42FF) : unselectedBg,
                  borderRadius: chipRadius,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6B42FF) : unselectedBorder,
                    width: 1.1,
                  ),
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
          ),
        ),
      ),
    );
  }
}
