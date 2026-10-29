import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';

class VpnStatusView extends StatelessWidget {
  final bool isConnected;
  final bool isConnecting;
  final String? exitCountry;

  const VpnStatusView({
    super.key,
    required this.isConnected,
    this.isConnecting = false,
    this.exitCountry,
  });

  @override
  Widget build(BuildContext context) {
    final isLiquid = ThemeManager.instance.isLiquidGlass;

    final statusColor = isConnected
        ? (isLiquid ? const Color(0xFF00E676) : ProtonColors.connected)
        : (isConnecting ? ProtonColors.connecting : const Color(0xFFDC3251));

    final statusText = isConnected
        ? 'CONNECTED'
        : (isConnecting ? 'CONNECTING...' : 'DISCONNECTED');

    final subtitleText = isConnected
        ? (exitCountry != null && exitCountry!.isNotEmpty
            ? 'Traffic routed via $exitCountry'
            : 'Your network traffic is encrypted')
        : (isConnecting
            ? 'Establishing secure HTTP/3 tunnel'
            : 'Your network traffic is unencrypted');

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          width: isLiquid ? 88 : 80,
          height: isLiquid ? 88 : 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isLiquid
                ? (isConnected
                    ? const Color(0xFF13231B)
                    : (isConnecting ? const Color(0xFF281F15) : const Color(0xFF20131B)))
                : ProtonColors.surface,
            border: Border.all(
              color: isLiquid ? statusColor.withValues(alpha: 0.8) : statusColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: isLiquid ? 0.35 : 0.2),
                blurRadius: isLiquid ? 36 : 24,
                spreadRadius: isLiquid ? 4 : 2,
              ),
            ],
          ),
          child: Center(
            child: isConnecting
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(ProtonColors.connecting),
                    ),
                  )
                : Icon(
                    isConnected ? Icons.lock_rounded : Icons.lock_open_rounded,
                    color: statusColor,
                    size: isLiquid ? 38 : 36,
                  ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          statusText,
          style: ProtonTypography.titleMedium.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitleText,
          style: ProtonTypography.bodySmall.copyWith(
            color: isLiquid ? const Color(0xFF8F8C9E) : ProtonColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
