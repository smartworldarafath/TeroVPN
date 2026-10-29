import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../components/country_flag.dart';

class ProfileCard extends StatelessWidget {
  final String title;
  final String description;
  final String countryCode;
  final String countryName;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const ProfileCard({
    super.key,
    required this.title,
    required this.description,
    required this.countryCode,
    required this.countryName,
    required this.icon,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLiquid = ThemeManager.instance.isLiquidGlass;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isLiquid
            ? const Color(0xFF1E1B2E).withValues(alpha: 0.65)
            : ProtonColors.surface,
        borderRadius: BorderRadius.circular(isLiquid ? 20 : 16),
        border: Border.all(
          color: isActive
              ? const Color(0xFF6D4AFF)
              : (isLiquid
                  ? Colors.white.withValues(alpha: 0.09)
                  : ProtonColors.cardBorder),
          width: isActive ? 1.6 : 1.0,
        ),
        boxShadow: [
          if (isLiquid && isActive) ...[
            BoxShadow(
              color: const Color(0xFF6D4AFF).withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ] else if (isLiquid) ...[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isLiquid ? 20 : 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF6D4AFF).withValues(alpha: 0.22)
                        : (isLiquid
                            ? const Color(0xFF141222).withValues(alpha: 0.6)
                            : ProtonColors.surfaceDark),
                    borderRadius: BorderRadius.circular(isLiquid ? 14 : 12),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF6D4AFF).withValues(alpha: 0.6)
                          : (isLiquid
                              ? Colors.white.withValues(alpha: 0.08)
                              : ProtonColors.cardBorder),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isActive
                        ? (isLiquid ? const Color(0xFFB19BFF) : ProtonColors.activeLabel)
                        : ProtonColors.textLight,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: ProtonTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C853).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF00E676),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: ProtonTypography.bodySmall.copyWith(
                          color: ProtonColors.textMuted,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CountryFlag(
                            countryCode: countryCode,
                            width: 20,
                            height: 14,
                            borderRadius: 3,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            countryName,
                            style: ProtonTypography.bodySmall.copyWith(
                              color: ProtonColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  isActive ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                  color: isActive ? const Color(0xFF6D4AFF) : ProtonColors.textMuted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
