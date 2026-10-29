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

    if (isFastest && isLiquid) {
      // Standalone Fastest Country card matching photo_2 & photo_3
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1728).withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6B42FF) : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6B42FF).withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
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
                      color: const Color(0xFF133226),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(Icons.bolt_rounded, color: Color(0xFF1FE5BD), size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fastest country',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Connects to closest edge server',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8F8C9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E676),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$load%',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8F8C9E),
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
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF757288),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (isLiquid) {
      // Continuous grouped glass card item matching photo_2 & photo_3
      final Color dotColor = load > 60
          ? const Color(0xFFFF9900)
          : (load > 40 ? const Color(0xFF00E676) : const Color(0xFF00E676));

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1728).withValues(alpha: 0.72),
          borderRadius: BorderRadius.vertical(
            top: isFirstInGroup ? const Radius.circular(24) : Radius.zero,
            bottom: isLastInGroup ? const Radius.circular(24) : Radius.zero,
          ),
          border: Border(
            left: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            right: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            top: isFirstInGroup ? BorderSide(color: Colors.white.withValues(alpha: 0.08)) : BorderSide.none,
            bottom: isLastInGroup ? BorderSide(color: Colors.white.withValues(alpha: 0.08)) : BorderSide.none,
          ),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8F8C9E),
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
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8F8C9E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                    color: isSelected ? const Color(0xFF6B42FF) : const Color(0xFF757288),
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
