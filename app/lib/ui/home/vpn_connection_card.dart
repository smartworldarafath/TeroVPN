import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../components/country_flag.dart';

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
    final isLiquid = ThemeManager.instance.isLiquidGlass;

    return Container(
      decoration: BoxDecoration(
        color: isLiquid
            ? const Color(0xFF1A1728).withValues(alpha: 0.72)
            : ProtonColors.surface,
        borderRadius: BorderRadius.circular(isLiquid ? 24 : 20),
        border: Border.all(
          color: isConnected
              ? (isLiquid ? const Color(0xFF00E676).withValues(alpha: 0.4) : ProtonColors.connected.withValues(alpha: 0.45))
              : (isLiquid
                  ? Colors.white.withValues(alpha: 0.08)
                  : ProtonColors.cardBorder),
          width: 1.0,
        ),
        boxShadow: [
          if (isLiquid) ...[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ] else ...[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ],
      ),
      child: Padding(
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
                            countryName.isEmpty ? 'Netherlands' : countryName,
                            style: ProtonTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cityName.isEmpty ? 'Amsterdam #12' : cityName,
                            style: ProtonTypography.bodySmall.copyWith(
                              color: const Color(0xFF8F8C9E),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF231E38),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'HTTP/3',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8B6CFF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF8F8C9E),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),

            if (!isLiquid) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: ProtonColors.cardBorder),
              const SizedBox(height: 12),
            ] else ...[
              const SizedBox(height: 18),
            ],

            // Main Action Button Row
            SizedBox(
              height: 54,
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
                        ? const Color(0xFF231D28)
                        : (isConnecting ? const Color(0xFF231D28) : const Color(0xFF6B42FF)),
                    foregroundColor: Colors.white,
                    elevation: (isConnected || isVpnOn) ? 0 : 6,
                    shadowColor: (isConnected || isVpnOn)
                        ? Colors.transparent
                        : const Color(0xFF6B42FF).withValues(alpha: 0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: (isConnected || isVpnOn)
                          ? BorderSide(
                              color: const Color(0xFFDC3251).withValues(alpha: 0.4),
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
      ),
    );
  }
}
