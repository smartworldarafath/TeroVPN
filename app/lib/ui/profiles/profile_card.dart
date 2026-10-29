import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ProtonColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? ProtonColors.primary : ProtonColors.cardBorder,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isActive
                        ? ProtonColors.primary.withOpacity(0.2)
                        : ProtonColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? ProtonColors.primary.withOpacity(0.5)
                          : ProtonColors.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isActive ? ProtonColors.activeLabel : ProtonColors.textLight,
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
                                color: ProtonColors.connected.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: ProtonColors.connected,
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
                        ),
                      ),
                    ],
                  ),
                ),
                CountryFlag(
                  countryCode: countryCode,
                  width: 28,
                  height: 19,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
