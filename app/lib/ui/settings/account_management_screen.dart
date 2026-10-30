import '../components/liquid_glass_atmosphere.dart';
import '../components/liquid_glass_card.dart';
import '../components/top_dock_toast.dart';
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
      TopDockToast.show(
        context,
        title: 'Accounts Synchronized',
        message: 'Account quotas and bandwidth updated in real-time',
        icon: Icons.sync_rounded,
      );
    }
  }

  Future<void> _activateAccount(Account account) async {
    await widget.controller.activate(account);
    if (mounted) {
      TopDockToast.show(
        context,
        title: 'Account Activated',
        message: '${account.email} session active',
        icon: Icons.check_circle_rounded,
      );
    }
  }

  Future<void> _signOutAccount(Account account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeManager.instance.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: ThemeManager.instance.cardBorderColor),
        ),
        title: Text(
          'Sign Out Account',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: ThemeManager.instance.textPrimaryColor,
          ),
        ),
        content: Text(
          'Are you sure you want to remove ${account.email} from this device?',
          style: TextStyle(color: ThemeManager.instance.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: ThemeManager.instance.textSecondaryColor)),
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
        TopDockToast.show(
          context,
          title: 'Account Removed',
          message: 'Signed out ${account.email}',
          icon: Icons.logout_rounded,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, ThemeManager.instance]),
      builder: (context, _) {
        final accounts = widget.controller.accounts?.accounts ?? [];
        final isDark = ThemeManager.instance.isDarkMode;

        return LiquidGlassAtmosphere(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Account Management',
              style: ProtonTypography.titleLarge.copyWith(
                fontSize: 20,
                color: ThemeManager.instance.textPrimaryColor,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: ThemeManager.instance.textPrimaryColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: _isRefreshing
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ThemeManager.instance.textPrimaryColor,
                        ),
                      )
                    : Icon(Icons.refresh_rounded, color: ThemeManager.instance.textPrimaryColor),
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
                LiquidGlassCard(
                  radius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF6B42FF).withValues(alpha: 0.15)
                              : const Color(0xFFF0EDFA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.vpn_key_rounded,
                          color: Color(0xFF6B42FF),
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
                                color: ThemeManager.instance.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Only 1 account runs active in real-time. Secondary accounts remain paused until activated.',
                              style: ProtonTypography.bodySmall.copyWith(
                                color: ThemeManager.instance.textSecondaryColor,
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
                          backgroundColor: const Color(0xFF6B42FF),
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
                        foregroundColor: const Color(0xFF6B42FF),
                        side: BorderSide(color: ThemeManager.instance.cardBorderColor),
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
                    color: ThemeManager.instance.textSecondaryColor,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),

                if (accounts.isEmpty)
                  LiquidGlassCard(
                    radius: 20,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.account_circle_outlined, size: 48, color: ThemeManager.instance.textMutedColor),
                        const SizedBox(height: 12),
                        Text(
                          'No Accounts Connected',
                          style: ProtonTypography.titleMedium.copyWith(
                            color: ThemeManager.instance.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in with a Firefox Account to unlock high-speed Fastly MASQUE proxying.',
                          textAlign: TextAlign.center,
                          style: ProtonTypography.bodySmall.copyWith(color: ThemeManager.instance.textMutedColor),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: () => SignInDialog.show(context, widget.controller),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B42FF),
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

                    return LiquidGlassCard(
                      radius: 20,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: EdgeInsets.zero,
                      customBorder: isActive
                          ? Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.6), width: 1.4)
                          : null,
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
                                        ? (isDark
                                            ? ProtonColors.connected.withValues(alpha: 0.2)
                                            : const Color(0xFFE0F7EF))
                                        : (isDark
                                            ? const Color(0xFF131122)
                                            : const Color(0xFFF0EDFA)),
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: isActive
                                          ? ProtonColors.connected
                                          : (isDark ? ProtonColors.textSecondary : const Color(0xFF6B42FF)),
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
                                            color: ThemeManager.instance.textPrimaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isActive
                                              ? 'Active Session · Fastly Tunneling'
                                              : 'Paused · Inactive Session',
                                          style: ProtonTypography.bodySmall.copyWith(
                                            color: isActive ? ProtonColors.connected : ThemeManager.instance.textSecondaryColor,
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
                                          ? (isDark
                                              ? ProtonColors.connected.withValues(alpha: 0.15)
                                              : const Color(0xFFE0F7EF))
                                          : (isDark
                                              ? const Color(0xFF261D42)
                                              : const Color(0xFFF0EDFA)),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isActive
                                            ? ProtonColors.connected.withValues(alpha: 0.4)
                                            : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.transparent),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      isActive ? 'RUNNING' : 'PAUSED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: isActive
                                            ? (isDark ? ProtonColors.connected : const Color(0xFF00A36C))
                                            : (isDark ? const Color(0xFF8B6CFF) : const Color(0xFF6B42FF)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Expand Chevron
                                  Icon(
                                    isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                    color: ThemeManager.instance.textSecondaryColor,
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
                                  Divider(height: 1, color: ThemeManager.instance.dividerColor),
                                  const SizedBox(height: 14),

                                  // Usage Line
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Bandwidth Consumed',
                                        style: ProtonTypography.bodySmall.copyWith(
                                          color: ThemeManager.instance.textSecondaryColor,
                                        ),
                                      ),
                                      Text(
                                        '${formatBytes(used)} of 50.0 GB',
                                        style: ProtonTypography.bodySmall.copyWith(
                                          color: ThemeManager.instance.textPrimaryColor,
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
                                      backgroundColor: isDark ? const Color(0xFF131122) : const Color(0xFFEAE7F2),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        ratio > 0.85 ? ProtonColors.disconnected : const Color(0xFF6B42FF),
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
                                          color: ThemeManager.instance.textSecondaryColor,
                                        ),
                                      ),
                                      Text(
                                        resetDate,
                                        style: ProtonTypography.bodySmall.copyWith(
                                          color: ThemeManager.instance.textPrimaryColor,
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
                                              backgroundColor: const Color(0xFF6B42FF),
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
                                            foregroundColor: const Color(0xFF6B42FF),
                                            side: BorderSide(color: ThemeManager.instance.cardBorderColor),
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
          ),
        );
      },
    );
  }
}
