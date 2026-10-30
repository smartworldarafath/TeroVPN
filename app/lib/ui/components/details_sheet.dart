import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../../core/models.dart';
import '../../core/format.dart';

class DetailsSheet extends StatelessWidget {
  final CoreStatus? status;
  final VoidCallback? onClose;

  const DetailsSheet({
    super.key,
    this.status,
    this.onClose,
  });

  static void show(BuildContext context, {CoreStatus? status}) {
    final isDark = ThemeManager.instance.isDarkMode;
    final isLiquid = ThemeManager.instance.isLiquidGlass;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? (isLiquid ? const Color(0xFF161426).withValues(alpha: 0.95) : const Color(0xFF181628))
                : Colors.white.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.95),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.5) : const Color(0xFF5D5380).withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: DetailsSheet(status: status),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.instance.isDarkMode;
    final proxy = status?.proxy;
    final traffic = status?.traffic;
    final transport = proxy?.transport.toUpperCase() ?? 'HTTP/3 (QUIC)';
    final ip = (status?.exit?.ipv4.isNotEmpty == true)
        ? status!.exit!.ipv4
        : ((status?.exit?.ipv6.isNotEmpty == true) ? status!.exit!.ipv6 : '185.156.73.42');
    final exitCountry = proxy?.countryName.isNotEmpty == true
        ? proxy!.countryName
        : 'Netherlands';
    final city = proxy?.cityName.isNotEmpty == true ? proxy!.cityName : 'Amsterdam';

    final textPrimary = isDark ? Colors.white : const Color(0xFF1D1536);
    final textSecondary = isDark ? const Color(0xFF8F8C9E) : const Color(0xFF757288);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFD8D5E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Connection Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF262338) : const Color(0xFFF1F0F7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: textPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow(
              icon: Icons.shield_outlined,
              label: 'Protocol',
              value: transport.contains('H3') || transport.contains('QUIC')
                  ? 'WireGuard MASQUE (HTTP/3)'
                  : transport,
              badge: 'SECURE',
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            _buildDetailRow(
              icon: Icons.public_rounded,
              label: 'Server IP',
              value: ip,
              isMono: true,
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            _buildDetailRow(
              icon: Icons.location_on_outlined,
              label: 'Exit Node',
              value: '$exitCountry, $city',
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            _buildDetailRow(
              icon: Icons.speed_rounded,
              label: 'Download / Upload',
              value: '${formatRate(traffic?.downRate ?? 0)}  ·  ${formatRate(traffic?.upRate ?? 0)}',
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            _buildDetailRow(
              icon: Icons.security_rounded,
              label: 'NetShield Ad-Blocker',
              value: 'Active (DNS Malware & Ads)',
              valueColor: isDark ? const Color(0xFF1FE5BD) : const Color(0xFF00A36C),
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    String? badge,
    bool isMono = false,
    Color? valueColor,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 20, color: textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? textPrimary,
                    fontFamily: isMono ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF261D42) : const Color(0xFFF0EDFA),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? const Color(0xFF6B42FF).withValues(alpha: 0.5) : const Color(0xFFDCD4F8),
                ),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6B42FF),
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
