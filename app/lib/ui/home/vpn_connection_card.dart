import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
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
    return Container(
      decoration: BoxDecoration(
        color: ProtonColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected
              ? ProtonColors.connected.withOpacity(0.3)
              : ProtonColors.cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Server Selection Header Row
          InkWell(
            onTap: onChangeServer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                      color: ProtonColors.surfaceDark,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: ProtonColors.cardBorder,
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

          const Divider(height: 1, color: ProtonColors.cardBorder),

          // Main Action Button Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: onToggle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (isConnected || isVpnOn)
                      ? ProtonColors.cancelBtn
                      : (isConnecting ? ProtonColors.cancelBtn : ProtonColors.primary),
                  foregroundColor: Colors.white,
                  elevation: (isConnected || isVpnOn) ? 0 : 4,
                  shadowColor: (isConnected || isVpnOn)
                      ? Colors.transparent
                      : ProtonColors.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: (isConnected || isVpnOn)
                        ? BorderSide(
                            color: ProtonColors.disconnected.withOpacity(0.4),
                            width: 1,
                          )
                        : BorderSide.none,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isConnecting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                        ),
                      )
                    else
                      Icon(
                        (isConnected || isVpnOn) ? Icons.power_settings_new_rounded : Icons.bolt_rounded,
                        size: 20,
                        color: (isConnected || isVpnOn) ? ProtonColors.disconnected : Colors.white,
                      ),
                    const SizedBox(width: 10),
                    Text(
                      (isConnected || isVpnOn)
                          ? 'Disconnect'
                          : (isConnecting ? 'Cancel' : 'Quick Connect'),
                      style: ProtonTypography.labelLarge.copyWith(
                        color: (isConnected || isVpnOn) ? ProtonColors.disconnected : Colors.white,
                      ),
                    ),
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
