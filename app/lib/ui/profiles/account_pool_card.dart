import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../core/models.dart';
import '../../core/format.dart';

class AccountPoolCard extends StatelessWidget {
  final AccountList? accounts;
  final VoidCallback onRotate;
  final VoidCallback onAddAccount;

  const AccountPoolCard({
    super.key,
    required this.accounts,
    required this.onRotate,
    required this.onAddAccount,
  });

  @override
  Widget build(BuildContext context) {
    final list = accounts?.accounts ?? [];
    final active = list.where((a) => a.active).firstOrNull ?? list.firstOrNull;
    final totalAccounts = list.length;

    // Fastly MASQUE session pool: 50GB monthly per account
    const totalPoolBytes = 50 * 1024 * 1024 * 1024; // 50 GB
    final usedBytes = active?.usage?.usedBytes ?? (12 * 1024 * 1024 * 1024);
    final ratio = (usedBytes / totalPoolBytes).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ProtonColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ProtonColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.layers_rounded,
                    color: ProtonColors.activeLabel,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Multi-Account Token Pool',
                    style: ProtonTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ProtonColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$totalAccounts ${totalAccounts == 1 ? 'Token' : 'Tokens'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ProtonColors.activeLabel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Rotates across Fastly MASQUE edge sessions to maintain uninterrupted 50GB high-speed bandwidth.',
            style: ProtonTypography.bodySmall.copyWith(
              color: ProtonColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),

          // Bandwidth Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Bandwidth Used',
                style: ProtonTypography.bodySmall.copyWith(
                  color: ProtonColors.textSecondary,
                ),
              ),
              Text(
                '${formatBytes(usedBytes)} / 50.0 GB',
                style: ProtonTypography.bodySmall.copyWith(
                  color: ProtonColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: ProtonColors.surfaceDark,
              valueColor: AlwaysStoppedAnimation<Color>(
                ratio > 0.85 ? ProtonColors.disconnected : ProtonColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Action Buttons Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRotate,
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: const Text('Rotate Now'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ProtonColors.activeLabel,
                    side: const BorderSide(color: ProtonColors.cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAddAccount,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Token'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProtonColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
