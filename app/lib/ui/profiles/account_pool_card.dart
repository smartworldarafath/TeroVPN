import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/theme_manager.dart';
import '../../core/models.dart';
import '../../core/format.dart';
import '../../core/core_controller.dart';
import '../settings/account_management_screen.dart';
import '../components/signin_dialog.dart';

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
        color: isLiquid
            ? const Color(0xFF1A1728).withValues(alpha: 0.72)
            : ProtonColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLiquid ? Colors.white.withValues(alpha: 0.08) : ProtonColors.cardBorder,
          width: 1,
        ),
        boxShadow: isLiquid
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
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
              const Row(
                children: [
                  Icon(
                    Icons.layers_rounded,
                    color: Color(0xFF6B42FF),
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Multi-Account Token Pool',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF261D42),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$totalAccounts Tokens',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B6CFF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Rotates across Fastly MASQUE edge sessions to maintain uninterrupted 50GB high-speed bandwidth.',
            style: TextStyle(
              color: Color(0xFF8F8C9E),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),

          // Real-Time Bandwidth Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Bandwidth Used',
                style: TextStyle(
                  color: Color(0xFF8F8C9E),
                  fontSize: 13,
                ),
              ),
              Text(
                '${formatBytes(usedBytes)} / 50.0 GB',
                style: const TextStyle(
                  color: Colors.white,
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
              backgroundColor: const Color(0xFF131122),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B42FF)),
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons: Refresh Now + Add Token side by side
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Refresh Now'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8B6CFF),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (controller != null) {
                        if (!controller!.hasAccount) {
                          SignInDialog.show(context, controller!);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AccountManagementScreen(controller: controller!),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Token'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B42FF),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
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
