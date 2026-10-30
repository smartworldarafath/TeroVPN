import 'package:flutter/material.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../components/country_flag.dart';
import '../components/liquid_glass_card.dart';

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

    final isDark = ThemeManager.instance.isDarkMode;
    final headerColor = isDark ? const Color(0xFF8F8C9E) : const Color(0xFF757288);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFF5D5380).withValues(alpha: 0.08);

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
        LiquidGlassCard(
          radius: 24,
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: dividerColor,
              indent: 62,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              final Color dotColor = item.load > 60
                  ? const Color(0xFFFF9900)
                  : (isDark ? const Color(0xFF00E676) : const Color(0xFF00A36C));

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelect(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
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
                        // Load & Ping indicator
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
                        const SizedBox(width: 10),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: subtitleColor,
                          size: 20,
                        ),
                      ],
                    ),
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
