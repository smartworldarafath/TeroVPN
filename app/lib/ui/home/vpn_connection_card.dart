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
            ? const Color(0xFF1B182B).withValues(alpha: 0.70)
            : ProtonColors.surface,
        borderRadius: BorderRadius.circular(isLiquid ? 22 : 20),
        border: Border.all(
          color: isConnected
              ? ProtonColors.connected.withValues(alpha: 0.45)
              : (isLiquid
                  ? Colors.white.withValues(alpha: 0.10)
                  : ProtonColors.cardBorder),
          width: isLiquid ? 1.2 : 1.0,
        ),
        boxShadow: [
          if (isLiquid) ...[
            BoxShadow(
              color: const Color(0xFF6D4AFF).withValues(alpha: 0.16),
              blurRadius: 24,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Server Selection Header Row
          InkWell(
            onTap: onChangeServer,
            borderRadius: BorderRadius.vertical(top: Radius.circular(isLiquid ? 22 : 20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  CountryFlag(
                    countryCode: countryCode,
                    width: 36,
                    height: 25,
                    borderRadius: 6,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          countryName.isEmpty ? 'Fastest country' : countryName,
                          style: ProtonTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cityName.isEmpty ? 'Auto Anycast Routing' : cityName,
                          style: ProtonTypography.bodySmall.copyWith(
                            color: ProtonColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isLiquid
                          ? const Color(0xFF6D4AFF).withValues(alpha: 0.15)
                          : ProtonColors.surfaceDark,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isLiquid
                            ? const Color(0xFF6D4AFF).withValues(alpha: 0.35)
                            : ProtonColors.cardBorder,
                        width: 0.8,
                      ),
                    ),
                    child: const Text(
                      'HTTP/3',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: ProtonColors.activeLabel,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: ProtonColors.textSecondary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          Divider(
            height: 1,
            color: isLiquid
                ? Colors.white.withValues(alpha: 0.08)
                : ProtonColors.cardBorder,
          ),

          // Main Action Button Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
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
                        ? ProtonColors.cancelBtn
                        : (isConnecting ? ProtonColors.cancelBtn : const Color(0xFF6D4AFF)),
                    foregroundColor: Colors.white,
                    elevation: (isConnected || isVpnOn) ? 0 : 5,
                    shadowColor: (isConnected || isVpnOn)
                        ? Colors.transparent
                        : const Color(0xFF6D4AFF).withValues(alpha: 0.55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isLiquid ? 16 : 14),
                      side: (isConnected || isVpnOn)
                          ? BorderSide(
                              color: ProtonColors.disconnected.withValues(alpha: 0.4),
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
                          ),
                        ),
                      ] else ...[
                        Icon(
                          (isConnected || isVpnOn) ? Icons.power_settings_new_rounded : Icons.bolt_rounded,
                          size: 20,
                          color: (isConnected || isVpnOn) ? ProtonColors.disconnected : Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          (isConnected || isVpnOn) ? 'Disconnect' : 'Quick Connect',
                          style: ProtonTypography.labelLarge.copyWith(
                            color: (isConnected || isVpnOn) ? ProtonColors.disconnected : Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
