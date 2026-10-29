import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../components/country_flag.dart';
import '../components/server_load_bar.dart';

class CountryItemRow extends StatelessWidget {
  final String code;
  final String name;
  final String subtitle;
  final int load;
  final bool isSelected;
  final bool isFastest;
  final VoidCallback onTap;

  const CountryItemRow({
    super.key,
    required this.code,
    required this.name,
    required this.subtitle,
    required this.load,
    this.isSelected = false,
    this.isFastest = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLiquid = ThemeManager.instance.isLiquidGlass;

    return Container(
      margin: isLiquid ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isLiquid
            ? (isSelected
                ? const Color(0xFF6D4AFF).withValues(alpha: 0.22)
                : const Color(0xFF1E1B2E).withValues(alpha: 0.55))
            : (isSelected ? ProtonColors.surfaceDark : Colors.transparent),
        borderRadius: isLiquid ? BorderRadius.circular(16) : null,
        border: isLiquid
            ? Border.all(
                color: isSelected
                    ? const Color(0xFF6D4AFF)
                    : Colors.white.withValues(alpha: 0.08),
                width: isSelected ? 1.4 : 1.0,
              )
            : (isSelected
                ? const Border(
                    left: BorderSide(
                      color: ProtonColors.primary,
                      width: 3,
                    ),
                  )
                : null),
        boxShadow: (isLiquid && isSelected)
            ? [
                BoxShadow(
                  color: const Color(0xFF6D4AFF).withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: isLiquid ? BorderRadius.circular(16) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                CountryFlag(
                  countryCode: isFastest ? 'fastest' : code,
                  width: 32,
                  height: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: ProtonTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? (isLiquid ? const Color(0xFFB19BFF) : ProtonColors.activeLabel)
                              : ProtonColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: ProtonTypography.bodySmall.copyWith(
                          color: ProtonColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ServerLoadBar(percentage: load),
                const SizedBox(width: 12),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                  color: isSelected ? const Color(0xFF6D4AFF) : ProtonColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
