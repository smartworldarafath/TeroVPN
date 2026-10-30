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
    final isDark = ThemeManager.instance.isDarkMode;

    final headerColor = isDark ? const Color(0xFF8F8C9E) : const Color(0xFF757288);
    final cardBg = isDark
        ? (isLiquid ? const Color(0xFF1A1728).withValues(alpha: 0.72) : ProtonColors.surface)
        : (isLiquid ? Colors.white.withValues(alpha: 0.90) : Colors.white);
    final cardBorder = isDark
        ? (isLiquid ? Colors.white.withValues(alpha: 0.08) : ProtonColors.cardBorder)
        : (isLiquid ? Colors.white.withValues(alpha: 0.95) : const Color(0xFFE5E3ED));
    final dividerColor = isDark
        ? (isLiquid ? Colors.white.withValues(alpha: 0.05) : ProtonColors.cardBorder)
        : const Color(0xFFEFEFF6);

    final titleColor = isDark ? Colors.white : const Color(0xFF1D1536);
    final subtitleColor = isDark ? const Color(0xFF8F8C9E) : const Color(0xFF757288);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Recents',
            style: ProtonTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: headerColor,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(isLiquid ? 24 : 16),
            border: Border.all(
              color: cardBorder,
              width: 1,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFF5D5380).withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: dividerColor,
              indent: isLiquid ? 62 : 0,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              final radius = Radius.circular(isLiquid ? 24 : 16);

              final Color dotColor = item.load > 60
                  ? const Color(0xFFFF9900)
                  : (item.load > 40 ? const Color(0xFF2CFFCC) : (isDark ? const Color(0xFF00E676) : const Color(0xFF00A36C)));

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
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.city,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLiquid || !isDark) ...[
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
                            const SizedBox(width: 5),
                            Text(
                              '${item.load}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: subtitleColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${item.latencyMs} ms',
                              style: TextStyle(
                                fontSize: 12,
                                color: subtitleColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item.latencyMs} ms',
                              style: ProtonTypography.labelSmall.copyWith(
                                color: ProtonColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 3),
                            ServerLoadBar(percentage: item.load),
                          ],
                        ),
                      ],
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: subtitleColor,
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
