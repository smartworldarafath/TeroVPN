import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
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
            color: isSelected
                ? const Color(0xFF6D4AFF)
                : (isLiquid
                    ? const Color(0xFF1E1B2E).withValues(alpha: 0.65)
                    : ProtonColors.chipBackground),
            borderRadius: BorderRadius.circular(isLiquid ? 20 : 12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6D4AFF)
                  : (isLiquid
                      ? Colors.white.withValues(alpha: 0.10)
                      : ProtonColors.cardBorder.withValues(alpha: 0.6)),
              width: 1,
            ),
            boxShadow: (isSelected && isLiquid)
                ? [
                    BoxShadow(
                      color: const Color(0xFF6D4AFF).withValues(alpha: 0.45),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : ProtonColors.textLight,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: ProtonTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : ProtonColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
