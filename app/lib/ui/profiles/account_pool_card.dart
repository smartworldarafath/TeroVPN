import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../../core/models.dart';
import '../../core/format.dart';

class AccountPoolCard extends StatelessWidget {
  final AccountList? accounts;
  final VoidCallback onRefresh;

  const AccountPoolCard({
    super.key,
    required this.accounts,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isLiquid = ThemeManager.instance.isLiquidGlass;
    final list = accounts?.accounts ?? [];
    final active = list.where((a) => a.active).firstOrNull ?? list.firstOrNull;
    final totalAccounts = list.length;

    // Fastly MASQUE session pool: 50GB monthly per account
    const totalPoolBytes = 50 * 1024 * 1024 * 1024; // 50 GB
    final usedBytes = active?.usage?.usedBytes ?? 0;
    final ratio = (usedBytes / totalPoolBytes).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isLiquid
            ? const Color(0xFF1E1B2E).withValues(alpha: 0.65)
            : ProtonColors.surface,
        borderRadius: BorderRadius.circular(isLiquid ? 20 : 18),
        border: Border.all(
          color: isLiquid ? Colors.white.withValues(alpha: 0.10) : ProtonColors.cardBorder,
          width: 1,
        ),
        boxShadow: isLiquid
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
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
                    color: Color(0xFF6D4AFF),
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
                  color: const Color(0xFF6D4AFF).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$totalAccounts ${totalAccounts == 1 ? 'Token' : 'Tokens'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB19BFF),
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

          // Real-Time Bandwidth Progress Bar
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
              backgroundColor: isLiquid ? const Color(0xFF141222) : ProtonColors.surfaceDark,
              valueColor: AlwaysStoppedAnimation<Color>(
                ratio > 0.85 ? ProtonColors.disconnected : const Color(0xFF6D4AFF),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Single Full-Width Action Button: Refresh Now
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh Now'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isLiquid ? const Color(0xFFB19BFF) : ProtonColors.activeLabel,
                side: BorderSide(
                  color: isLiquid ? const Color(0xFF6D4AFF).withValues(alpha: 0.5) : ProtonColors.cardBorder,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
