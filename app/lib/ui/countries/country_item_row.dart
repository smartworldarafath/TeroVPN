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
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final VoidCallback onTap;

  const CountryItemRow({
    super.key,
    required this.code,
    required this.name,
    required this.subtitle,
    required this.load,
    this.isSelected = false,
    this.isFastest = false,
    this.isFirstInGroup = false,
    this.isLastInGroup = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLiquid = ThemeManager.instance.isLiquidGlass;
    final isDark = ThemeManager.instance.isDarkMode;

    if (isFastest && (isLiquid || !isDark)) {
      // Standalone Fastest Country card matching photo_2 (dark) & photo_11 (light)
      final cardBg = isDark
          ? const Color(0xFF1A1728).withValues(alpha: 0.72)
          : Colors.white.withValues(alpha: 0.90);
      final borderColor = isSelected
          ? const Color(0xFF6B42FF)
          : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.95));

      final titleColor = isDark ? Colors.white : const Color(0xFF1D1536);
      final subtitleColor = isDark ? const Color(0xFF8F8C9E) : const Color(0xFF757288);

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.25 : 0.20),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : (isDark
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF5D5380).withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF133226) : const Color(0xFFD8F5EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.bolt_rounded,
                        color: isDark ? const Color(0xFF1FE5BD) : const Color(0xFF00A36C),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fastest country',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Connects to closest edge server',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF00E676) : const Color(0xFF00A36C),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$load%',
                    style: TextStyle(
                      fontSize: 13,
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (isSelected)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6B42FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.check, size: 14, color: Colors.white),
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: subtitleColor,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (isLiquid || !isDark) {
      // Continuous grouped glass card item matching photo_2 (dark) & photo_11 (light)
      final Color dotColor = load > 60
          ? const Color(0xFFFF9900)
          : (isDark ? const Color(0xFF00E676) : const Color(0xFF00A36C));

      final cardBg = isDark
          ? const Color(0xFF1A1728).withValues(alpha: 0.72)
          : Colors.white.withValues(alpha: 0.90);
      final borderColor = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.95);

      final titleColor = isDark ? Colors.white : const Color(0xFF1D1536);
      final subtitleColor = isDark ? const Color(0xFF8F8C9E) : const Color(0xFF757288);

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.vertical(
            top: isFirstInGroup ? const Radius.circular(24) : Radius.zero,
            bottom: isLastInGroup ? const Radius.circular(24) : Radius.zero,
          ),
          border: Border(
            left: BorderSide(color: borderColor),
            right: BorderSide(color: borderColor),
            top: isFirstInGroup ? BorderSide(color: borderColor) : BorderSide.none,
            bottom: isLastInGroup ? BorderSide(color: borderColor) : BorderSide.none,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF5D5380).withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.vertical(
              top: isFirstInGroup ? const Radius.circular(24) : Radius.zero,
              bottom: isLastInGroup ? const Radius.circular(24) : Radius.zero,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              child: Row(
                children: [
                  CountryFlag(
                    countryCode: code,
                    width: 32,
                    height: 22,
                    borderRadius: 4,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$load%',
                    style: TextStyle(
                      fontSize: 13,
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                    color: isSelected ? const Color(0xFF6B42FF) : subtitleColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Classic Proton UI fallback
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? ProtonColors.surfaceDark : Colors.transparent,
          border: isSelected
              ? const Border(
                  left: BorderSide(
                    color: ProtonColors.primary,
                    width: 3,
                  ),
                )
              : null,
        ),
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
                      color: isSelected ? ProtonColors.activeLabel : ProtonColors.textPrimary,
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
    );
  }
}
