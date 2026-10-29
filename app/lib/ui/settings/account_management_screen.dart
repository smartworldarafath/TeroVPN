import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../../core/core_controller.dart';
import '../../core/models.dart';
import '../../core/format.dart';
import '../components/signin_dialog.dart';

class AccountManagementScreen extends StatefulWidget {
  final CoreController controller;

  const AccountManagementScreen({super.key, required this.controller});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final Set<String> _expandedAccountIds = {};
  bool _isRefreshing = false;

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedAccountIds.contains(id)) {
        _expandedAccountIds.remove(id);
      } else {
        _expandedAccountIds.add(id);
      }
    });
  }

  Future<void> _refreshAllQuotas() async {
    setState(() => _isRefreshing = true);
    final accounts = widget.controller.accounts?.accounts ?? [];
    for (final a in accounts) {
      try {
        await widget.controller.refreshQuota(a);
      } catch (_) {}
    }
    await widget.controller.refresh(accountsToo: true);
    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account quotas and bandwidth synchronized.'),
          backgroundColor: ProtonColors.surfaceDark,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _activateAccount(Account account) async {
    await widget.controller.activate(account);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Activated session for ${account.email}. Other accounts paused.'),
          backgroundColor: ProtonColors.surfaceDark,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _signOutAccount(Account account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProtonColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ProtonColors.cardBorder),
        ),
        title: const Text('Sign Out Account', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to remove ${account.email} from this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: ProtonColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ProtonColors.disconnected,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.controller.remove(account);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signed out ${account.email}'),
            backgroundColor: ProtonColors.surfaceDark,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final accounts = widget.controller.accounts?.accounts ?? [];
        final isLiquid = ThemeManager.instance.isLiquidGlass;

        return Scaffold(
          backgroundColor: isLiquid ? const Color(0xFF0B0A13) : ProtonColors.background,
          appBar: AppBar(
            title: Text(
              'Account Management',
              style: ProtonTypography.titleLarge.copyWith(fontSize: 20),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: ProtonColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.refresh_rounded, color: ProtonColors.textSecondary),
                tooltip: 'Refresh Quota',
                onPressed: _isRefreshing ? null : _refreshAllQuotas,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ProtonColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ProtonColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ProtonColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.vpn_key_rounded,
                          color: ProtonColors.activeLabel,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Multi-Account Session Pool',
                              style: ProtonTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Only 1 account runs active in real-time. Secondary accounts remain paused until activated.',
                              style: ProtonTypography.bodySmall.copyWith(
                                color: ProtonColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Top Actions Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => SignInDialog.show(context, widget.controller),
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                        label: const Text('Add Another Account'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ProtonColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _isRefreshing ? null : _refreshAllQuotas,
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Refresh Quota'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ProtonColors.activeLabel,
                        side: const BorderSide(color: ProtonColors.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Accounts List Header
                Text(
                  'CONNECTED ACCOUNTS (${accounts.length})',
                  style: ProtonTypography.labelSmall.copyWith(
                    color: ProtonColors.textSecondary,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),

                if (accounts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: ProtonColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ProtonColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.account_circle_outlined, size: 48, color: ProtonColors.textMuted),
                        const SizedBox(height: 12),
                        Text('No Accounts Connected', style: ProtonTypography.titleMedium),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in with a Firefox Account to unlock high-speed Fastly MASQUE proxying.',
                          textAlign: TextAlign.center,
                          style: ProtonTypography.bodySmall.copyWith(color: ProtonColors.textMuted),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: () => SignInDialog.show(context, widget.controller),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ProtonColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Sign In Now'),
                        ),
                      ],
                    ),
                  )
                else
                  ...accounts.map((account) {
                    final isExpanded = _expandedAccountIds.contains(account.id);
                    final isActive = account.active;

                    // 50GB Fastly pool per account
                    const totalLimit = 50.0 * 1024 * 1024 * 1024;
                    final used = account.usage?.usedBytes ?? 0;
                    final ratio = (used / totalLimit).clamp(0.0, 1.0);
                    final resetDate = account.usage?.resetAt != null
                        ? DateFormat.yMMMd().format(account.usage!.resetAt!)
                        : 'End of billing cycle';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: ProtonColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? ProtonColors.connected.withValues(alpha: 0.5)
                              : ProtonColors.cardBorder,
                          width: isActive ? 1.4 : 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Account Header Tile
                          InkWell(
                            onTap: () => _toggleExpand(account.id),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isActive
                                        ? ProtonColors.connected.withValues(alpha: 0.2)
                                        : ProtonColors.surfaceDark,
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: isActive ? ProtonColors.connected : ProtonColors.textSecondary,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          account.email.isNotEmpty ? account.email : 'Firefox Account',
                                          style: ProtonTypography.bodyLarge.copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isActive
                                              ? 'Active Session · Fastly Tunneling'
                                              : 'Paused · Inactive Session',
                                          style: ProtonTypography.bodySmall.copyWith(
                                            color: isActive ? ProtonColors.connected : ProtonColors.textMuted,
                                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? ProtonColors.connected.withValues(alpha: 0.15)
                                          : ProtonColors.surfaceDark,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isActive
                                            ? ProtonColors.connected.withValues(alpha: 0.4)
                                            : ProtonColors.cardBorder,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      isActive ? 'RUNNING' : 'PAUSED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: isActive ? ProtonColors.connected : ProtonColors.textMuted,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Expand Chevron
                                  Icon(
                                    isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                    color: ProtonColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Expandable Details Section
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 250),
                            crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                            firstChild: Padding(
                              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(height: 1, color: ProtonColors.cardBorder),
                                  const SizedBox(height: 14),

                                  // Usage Line
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Bandwidth Consumed',
                                        style: ProtonTypography.bodySmall.copyWith(
                                          color: ProtonColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        '${formatBytes(used)} of 50.0 GB',
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
                                  const SizedBox(height: 12),

                                  // Quota Reset Date
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Quota Reset Date',
                                        style: ProtonTypography.bodySmall.copyWith(
                                          color: ProtonColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        resetDate,
                                        style: ProtonTypography.bodySmall.copyWith(
                                          color: ProtonColors.textLight,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Account Controls
                                  Row(
                                    children: [
                                      if (!isActive)
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _activateAccount(account),
                                            icon: const Icon(Icons.play_arrow_rounded, size: 16),
                                            label: const Text('Activate'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: ProtonColors.primary,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                          ),
                                        ),
                                      if (!isActive) const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            await widget.controller.refreshQuota(account);
                                            await widget.controller.refresh(accountsToo: true);
                                          },
                                          icon: const Icon(Icons.sync_rounded, size: 16),
                                          label: const Text('Refresh'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: ProtonColors.activeLabel,
                                            side: const BorderSide(color: ProtonColors.cardBorder),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _signOutAccount(account),
                                          icon: const Icon(Icons.logout_rounded, size: 16, color: ProtonColors.disconnected),
                                          label: const Text('Sign Out', style: TextStyle(color: ProtonColors.disconnected)),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: ProtonColors.disconnected.withValues(alpha: 0.4)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            secondChild: const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}
