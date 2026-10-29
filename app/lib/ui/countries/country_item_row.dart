import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? ProtonColors.surfaceDark : Colors.transparent,
          border: isSelected
              ? Border(
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
              color: isSelected ? ProtonColors.primary : ProtonColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
