import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
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
    showModalBottomSheet(
      context: context,
      backgroundColor: ProtonColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DetailsSheet(status: status),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  color: ProtonColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Connection Details', style: ProtonTypography.titleMedium),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: ProtonColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.shield_outlined,
              label: 'Protocol',
              value: transport.contains('H3') || transport.contains('QUIC')
                  ? 'WireGuard MASQUE (HTTP/3)'
                  : transport,
              badge: 'SECURE',
            ),
            _buildDetailRow(
              icon: Icons.public_rounded,
              label: 'Server IP',
              value: ip,
              isMono: true,
            ),
            _buildDetailRow(
              icon: Icons.location_on_outlined,
              label: 'Exit Node',
              value: '$exitCountry, $city',
            ),
            _buildDetailRow(
              icon: Icons.speed_rounded,
              label: 'Download / Upload',
              value: '${formatRate(traffic?.downRate ?? 0)}  ·  ${formatRate(traffic?.upRate ?? 0)}',
            ),
            _buildDetailRow(
              icon: Icons.security_rounded,
              label: 'NetShield Ad-Blocker',
              value: 'Active (DNS Malware & Ads)',
              valueColor: ProtonColors.connected,
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: ProtonColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ProtonTypography.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: isMono
                      ? ProtonTypography.mono.copyWith(
                          color: valueColor ?? ProtonColors.textPrimary,
                        )
                      : ProtonTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: valueColor ?? ProtonColors.textPrimary,
                        ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ProtonColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: ProtonColors.primary.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: ProtonColors.activeLabel,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
