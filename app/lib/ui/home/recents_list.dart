import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../components/country_flag.dart';
import '../components/server_load_bar.dart';

class RecentServerItem {
  final String code;
  final String name;
  final String city;
  final int latencyMs;
  final int load;

  const RecentServerItem({
    required this.code,
    required this.name,
    required this.city,
    required this.latencyMs,
    required this.load,
  });
}

class RecentsList extends StatelessWidget {
  final List<RecentServerItem> items;
  final ValueChanged<RecentServerItem> onSelect;

  const RecentsList({
    super.key,
    required this.items,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final isLiquid = ThemeManager.instance.isLiquidGlass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Recents',
            style: ProtonTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: ProtonColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isLiquid
                ? const Color(0xFF1B182B).withValues(alpha: 0.65)
                : ProtonColors.surface,
            borderRadius: BorderRadius.circular(isLiquid ? 20 : 16),
            border: Border.all(
              color: isLiquid
                  ? Colors.white.withValues(alpha: 0.10)
                  : ProtonColors.cardBorder,
              width: 1,
            ),
            boxShadow: isLiquid
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: isLiquid
                  ? Colors.white.withValues(alpha: 0.07)
                  : ProtonColors.cardBorder,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              final radius = Radius.circular(isLiquid ? 20 : 16);

              return InkWell(
                onTap: () => onSelect(item),
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? radius : Radius.zero,
                  bottom: index == items.length - 1 ? radius : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      CountryFlag(
                        countryCode: item.code,
                        width: 32,
                        height: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: ProtonTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.city,
                              style: ProtonTypography.bodySmall.copyWith(
                                color: ProtonColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isLiquid
                              ? const Color(0xFF6D4AFF).withValues(alpha: 0.15)
                              : ProtonColors.surfaceDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${item.latencyMs} ms',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00E676),
                          ),
                        ),
                      ),
                      ServerLoadBar(percentage: item.load),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: ProtonColors.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
