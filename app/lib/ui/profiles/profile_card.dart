import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
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
    final isDark = ThemeManager.instance.isDarkMode;

    final cardBg = isDark
        ? (isLiquid ? const Color(0xFF1A1728).withValues(alpha: 0.72) : ProtonColors.surface)
        : (isLiquid ? Colors.white.withValues(alpha: 0.90) : Colors.white);

    final borderColor = isActive
        ? const Color(0xFF6B42FF)
        : (isDark
            ? (isLiquid ? Colors.white.withValues(alpha: 0.08) : ProtonColors.cardBorder)
            : (isLiquid ? Colors.white.withValues(alpha: 0.95) : const Color(0xFFE5E3ED)));

    final titleColor = isDark ? Colors.white : const Color(0xFF1D1536);
    final descColor = isDark ? const Color(0xFF8F8C9E) : const Color(0xFF757288);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.30 : 0.20),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            )
          else if (isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: const Color(0xFF5D5380).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isDark ? const Color(0xFF281E48) : const Color(0xFFF0EDFA))
                        : (isDark
                            ? (isLiquid ? const Color(0xFF201D30) : ProtonColors.surfaceDark)
                            : const Color(0xFFF3F2F8)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.4 : 0.3)
                          : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.transparent),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: isActive
                          ? const Color(0xFF6B42FF)
                          : (isDark ? const Color(0xFF8F8C9E) : const Color(0xFF757288)),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F2B26) : const Color(0xFFE0F7EF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? const Color(0xFF1FE5BD) : const Color(0xFF00A36C),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: TextStyle(
                          color: descColor,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Country flag on the right, matching photo_4 & photo_5
                CountryFlag(
                  countryCode: countryCode,
                  width: 28,
                  height: 18,
                  borderRadius: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
