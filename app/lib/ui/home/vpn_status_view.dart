import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';

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
    final statusColor = isConnected
        ? ProtonColors.connected
        : (isConnecting ? ProtonColors.connecting : ProtonColors.disconnected);

    final statusText = isConnected
        ? 'CONNECTED'
        : (isConnecting ? 'CONNECTING...' : 'DISCONNECTED');

    final subtitleText = isConnected
        ? (exitCountry != null && exitCountry!.isNotEmpty
            ? 'Traffic routed via $exitCountry'
            : 'Fastly MASQUE HTTP/3 Encrypted')
        : (isConnecting
            ? 'Establishing secure HTTP/3 tunnel'
            : 'Your network traffic is unencrypted');

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ProtonColors.surface,
            border: Border.all(
              color: statusColor.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: isConnected ? 0.35 : 0.15),
                blurRadius: 24,
                spreadRadius: 2,
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
                    size: 36,
                  ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          statusText,
          style: ProtonTypography.titleMedium.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitleText,
          style: ProtonTypography.bodySmall.copyWith(
            color: ProtonColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
