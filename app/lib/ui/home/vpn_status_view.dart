import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/theme_manager.dart';
import '../components/liquid_glass_card.dart';

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
    final isDark = ThemeManager.instance.isDarkMode;

    final statusColor = isConnected
        ? (isDark ? const Color(0xFF00E676) : const Color(0xFF00A36C))
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

    final ringAndStatus = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          width: isLiquid ? 88 : 80,
          height: isLiquid ? 88 : 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? (isLiquid
                    ? (isConnected
                        ? const Color(0xFF13231B)
                        : (isConnecting ? const Color(0xFF281F15) : const Color(0xFF20131B)))
                    : ProtonColors.surface)
                : (isConnected
                    ? const Color(0xFFE8F8F5)
                    : (isConnecting ? const Color(0xFFFFF7EB) : const Color(0xFFFFF0F2))),
            border: Border.all(
              color: statusColor.withValues(alpha: isDark ? 0.8 : 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: isDark ? 0.35 : 0.22),
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
        const SizedBox(height: 16),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 16,
          ),
        ),
      ],
    );

    // In Light mode, wrap the ring & status in the frosted glass card matching photo_12
    if (!isDark) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LiquidGlassCard(
            radius: 28,
            blur: 24,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 36),
            child: ringAndStatus,
          ),
          const SizedBox(height: 14),
          Text(
            subtitleText,
            style: const TextStyle(
              color: Color(0xFF2A2738),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ringAndStatus,
        const SizedBox(height: 8),
        Text(
          subtitleText,
          style: const TextStyle(
            color: Color(0xFF8F8C9E),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
