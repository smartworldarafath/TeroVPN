import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
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
            color: ProtonColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ProtonColors.cardBorder, width: 1),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: ProtonColors.cardBorder,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return InkWell(
                onTap: () => onSelect(item),
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(16) : Radius.zero,
                  bottom: index == items.length - 1 ? const Radius.circular(16) : Radius.zero,
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
                      ServerLoadBar(percentage: item.load),
                      const SizedBox(width: 12),
                      Text(
                        '${item.latencyMs} ms',
                        style: ProtonTypography.labelSmall.copyWith(
                          color: ProtonColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: ProtonColors.textMuted,
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
