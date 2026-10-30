import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../components/country_flag.dart';
import '../components/liquid_glass_card.dart';

class CountryItemRow extends StatelessWidget {
  final String code;
  final String name;
  final String subtitle;
  final int load;
  final int pingMs;
  final bool isFastest;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onExpand;

  const CountryItemRow({
    super.key,
    required this.code,
    required this.name,
    required this.subtitle,
    required this.load,
    required this.pingMs,
    this.isFastest = false,
    this.isSelected = false,
    required this.onTap,
    this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.instance.isDarkMode;
    final titleColor = isDark ? Colors.white : const Color(0xFF1D1536);
    final subtitleColor = isDark ? const Color(0xFF8F89A3) : const Color(0xFF757085);

    if (isFastest) {
      // Standalone Fastest Country card matching photo_2 & photo_11
      return LiquidGlassCard(
        radius: 20,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        customBorder: isSelected
            ? Border.all(color: const Color(0xFF6B42FF), width: 1.6)
            : null,
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF133226) : const Color(0xFFD8F5EB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  Icons.bolt_rounded,
                  color: isDark ? const Color(0xFF1FE5BD) : const Color(0xFF00A36C),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fastest country',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Connects to closest edge server',
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF00E676) : const Color(0xFF00A36C),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$load%',
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$pingMs ms',
                  style: TextStyle(
                    fontSize: 11,
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFF6B42FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.check, size: 14, color: Colors.white),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: subtitleColor,
                size: 20,
              ),
          ],
        ),
      );
    }

    // Individual Country Card with Real-time Latency (ms) directly below % and expansion button
    final Color dotColor = load > 60
        ? const Color(0xFFFF9900)
        : (isDark ? const Color(0xFF00E676) : const Color(0xFF00A36C));

    return LiquidGlassCard(
      radius: 18,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: EdgeInsets.zero,
      customBorder: isSelected
          ? Border.all(color: const Color(0xFF6B42FF), width: 1.6)
          : null,
      child: Row(
        children: [
          // Left Area: Flag, Name, Subtitle, Load & Ping (Tap to select/connect)
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 13, 8, 13),
                  child: Row(
                    children: [
                      CountryFlag(
                        countryCode: code,
                        width: 32,
                        height: 22,
                        borderRadius: 4,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: subtitleColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Percentage on top, Real-time Latency (ms) directly below percentage
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                                '$load%',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: subtitleColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$pingMs ms',
                            style: TextStyle(
                              fontSize: 11,
                              color: subtitleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Checkmark indicator if currently active
          if (isSelected) ...[
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFF6B42FF),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.check, size: 14, color: Colors.white),
              ),
            ),
          ],

          // Dedicated 52x52 hit-test target for > chevron button
          // Guarantees expanding even on subtle off-center taps around the icon
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onExpand ?? onTap,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(18)),
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: subtitleColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
