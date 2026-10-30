import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../components/country_flag.dart';
import '../components/liquid_glass_card.dart';

class VpnConnectionCard extends StatelessWidget {
  final String countryCode;
  final String countryName;
  final String cityName;
  final bool isConnected;
  final bool isConnecting;
  final bool isVpnOn;
  final VoidCallback onToggle;
  final VoidCallback onChangeServer;

  const VpnConnectionCard({
    super.key,
    required this.countryCode,
    required this.countryName,
    required this.cityName,
    required this.isConnected,
    this.isConnecting = false,
    this.isVpnOn = false,
    required this.onToggle,
    required this.onChangeServer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.instance.isDarkMode;

    final countryTextColor = isDark ? Colors.white : const Color(0xFF1D1536);
    final cityTextColor = isDark ? const Color(0xFF8F8C9E) : const Color(0xFF757288);

    return LiquidGlassCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Server Selection Header Row
          InkWell(
            onTap: onChangeServer,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  if (countryCode.toLowerCase() == 'fastest')
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF133226) : const Color(0xFFD8F5EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.bolt_rounded,
                          color: isDark ? const Color(0xFF1FE5BD) : const Color(0xFF00A36C),
                          size: 22,
                        ),
                      ),
                    )
                  else
                    CountryFlag(
                      countryCode: countryCode,
                      width: 36,
                      height: 26,
                      borderRadius: 4,
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          countryCode.toLowerCase() == 'fastest'
                              ? 'Fastest country'
                              : (countryName.isEmpty ? 'Netherlands' : countryName),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: countryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          countryCode.toLowerCase() == 'fastest'
                              ? 'The best server based on your location'
                              : (cityName.isEmpty ? 'Amsterdam #12' : cityName),
                          style: TextStyle(
                            color: cityTextColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF231E38) : const Color(0xFFF0EDFA),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'HTTP/3',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B42FF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: cityTextColor,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Main Action Button (Quick Connect)
          SizedBox(
            height: 52,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
                  child: child,
                ),
              ),
              child: ElevatedButton(
                key: ValueKey<String>(
                  isConnecting ? 'connecting' : ((isConnected || isVpnOn) ? 'disconnect' : 'connect'),
                ),
                onPressed: onToggle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (isConnected || isVpnOn)
                      ? (isDark ? const Color(0xFF231D28) : const Color(0xFFFFF0F2))
                      : (isConnecting
                          ? (isDark ? const Color(0xFF231D28) : const Color(0xFFFFF8EE))
                          : const Color(0xFF6B42FF)),
                  foregroundColor: Colors.white,
                  elevation: (isConnected || isVpnOn) ? 0 : 4,
                  shadowColor: (isConnected || isVpnOn)
                      ? Colors.transparent
                      : const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.45 : 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: (isConnected || isVpnOn)
                        ? BorderSide(
                            color: const Color(0xFFDC3251).withValues(alpha: isDark ? 0.4 : 0.5),
                            width: 1,
                          )
                        : BorderSide.none,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isConnecting) ...[
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(ProtonColors.connecting),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Connecting...',
                        style: ProtonTypography.labelLarge.copyWith(
                          color: ProtonColors.connecting,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ] else ...[
                      Icon(
                        (isConnected || isVpnOn) ? Icons.power_settings_new_rounded : Icons.bolt_rounded,
                        size: 22,
                        color: (isConnected || isVpnOn) ? const Color(0xFFDC3251) : Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        (isConnected || isVpnOn) ? 'Disconnect' : 'Quick Connect',
                        style: ProtonTypography.labelLarge.copyWith(
                          color: (isConnected || isVpnOn) ? const Color(0xFFDC3251) : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
