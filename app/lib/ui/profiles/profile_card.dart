import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../components/country_flag.dart';
import '../components/liquid_glass_card.dart';

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
    final isDark = ThemeManager.instance.isDarkMode;
    final titleColor = isDark ? Colors.white : const Color(0xFF1D1536);
    final descColor = isDark ? const Color(0xFF8F8C9E) : const Color(0xFF757288);

    return LiquidGlassCard(
      radius: 22,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      customBorder: isActive
          ? Border.all(color: const Color(0xFF6B42FF), width: 1.6)
          : null,
      customShadow: isActive
          ? [
              BoxShadow(
                color: const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.35 : 0.25),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark ? const Color(0xFF281E48) : const Color(0xFFF0EDFA))
                  : (isDark
                      ? const Color(0xFF201D30)
                      : const Color(0xFFF3F2F8)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.4 : 0.3)
                    : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.transparent),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFF6B42FF) : descColor,
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
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: titleColor,
                        ),
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF00E676).withValues(alpha: 0.15)
                              : const Color(0xFFE8F8F5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF00E676).withValues(alpha: 0.4)
                                : const Color(0xFF00A36C).withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isDark ? const Color(0xFF00E676) : const Color(0xFF00A36C),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: descColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          CountryFlag(
            countryCode: countryCode,
            width: 32,
            height: 22,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }
}
