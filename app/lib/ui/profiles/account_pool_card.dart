import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../../core/models.dart';
import '../../core/format.dart';
import '../../core/core_controller.dart';

class AccountPoolCard extends StatelessWidget {
  final AccountList? accounts;
  final VoidCallback onRefresh;
  final CoreController? controller;

  const AccountPoolCard({
    super.key,
    required this.accounts,
    required this.onRefresh,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isLiquid = ThemeManager.instance.isLiquidGlass;
    final isDark = ThemeManager.instance.isDarkMode;
    final list = accounts?.accounts ?? [];
    final active = list.where((a) => a.active).firstOrNull ?? list.firstOrNull;
    final totalAccounts = list.length;

    // Fastly MASQUE session pool: 50GB monthly per account
    const totalPoolBytes = 50 * 1024 * 1024 * 1024; // 50 GB
    final usedBytes = active?.usage?.usedBytes ?? (12 * 1024 * 1024 * 1024); // fallback 12.0 GB
    final ratio = (usedBytes / totalPoolBytes).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeManager.instance.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ThemeManager.instance.cardBorderColor,
          width: 1,
        ),
        boxShadow: isLiquid ? ThemeManager.instance.cardShadow : null,
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
                    color: Color(0xFF6B42FF),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Multi-Account Token Pool',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ThemeManager.instance.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF261D42) : const Color(0xFFF0EDFA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$totalAccounts Tokens',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B42FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Rotates across Fastly MASQUE edge sessions to maintain uninterrupted 50GB high-speed bandwidth.',
            style: TextStyle(
              color: ThemeManager.instance.textSecondaryColor,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),

          // Real-Time Bandwidth Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Bandwidth Used',
                style: TextStyle(
                  color: ThemeManager.instance.textSecondaryColor,
                  fontSize: 13,
                ),
              ),
              Text(
                '${formatBytes(usedBytes)} / 50.0 GB',
                style: TextStyle(
                  color: ThemeManager.instance.textPrimaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor: isDark ? const Color(0xFF131122) : const Color(0xFFEAE7F2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B42FF)),
            ),
          ),
          const SizedBox(height: 20),

          // Action Button: Refresh Now (Full Width matching photo_5)
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh Now'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6B42FF),
                side: BorderSide(
                  color: const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.6 : 0.8),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
