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
              fontWeight: FontWeight.w600,
              color: isLiquid ? const Color(0xFF8F8C9E) : ProtonColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isLiquid
                ? const Color(0xFF1A1728).withValues(alpha: 0.72)
                : ProtonColors.surface,
            borderRadius: BorderRadius.circular(isLiquid ? 24 : 16),
            border: Border.all(
              color: isLiquid
                  ? Colors.white.withValues(alpha: 0.08)
                  : ProtonColors.cardBorder,
              width: 1,
            ),
            boxShadow: isLiquid
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 18,
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
                  ? Colors.white.withValues(alpha: 0.05)
                  : ProtonColors.cardBorder,
              indent: isLiquid ? 62 : 0,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              final radius = Radius.circular(isLiquid ? 24 : 16);

              final Color dotColor = item.load > 60
                  ? const Color(0xFFFF9900)
                  : (item.load > 40 ? const Color(0xFF2CFFCC) : const Color(0xFF00E676));

              return InkWell(
                onTap: () => onSelect(item),
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? radius : Radius.zero,
                  bottom: index == items.length - 1 ? radius : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                  child: Row(
                    children: [
                      CountryFlag(
                        countryCode: item.code,
                        width: 32,
                        height: 22,
                        borderRadius: 4,
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
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.city,
                              style: ProtonTypography.bodySmall.copyWith(
                                color: const Color(0xFF8F8C9E),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLiquid) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                              '${item.load}%  ${item.latencyMs} ms',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF8F8C9E),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF757288),
                              size: 20,
                            ),
                          ],
                        ),
                      ] else ...[
                        ServerLoadBar(percentage: item.load),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: ProtonColors.textMuted,
                          size: 20,
                        ),
                      ],
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
