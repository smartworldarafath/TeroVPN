import 'package:flutter/material.dart';
import '../../core/core_controller.dart';
import '../../core/app_preferences.dart';
import '../../theme/theme_manager.dart';
import '../components/signin_dialog.dart';
import '../settings/account_management_screen.dart';
import '../settings/split_tunneling_screen.dart';
import '../settings/theme_settings_screen.dart';
import '../settings/app_update_screen.dart';
import '../settings/about_screen.dart';
import '../settings/extra_functions_screen.dart';

class DesktopSettingsView extends StatefulWidget {
  final CoreController controller;

  const DesktopSettingsView({
    super.key,
    required this.controller,
  });

  @override
  State<DesktopSettingsView> createState() => _DesktopSettingsViewState();
}

class _DesktopSettingsViewState extends State<DesktopSettingsView> {
  late bool _netShieldEnabled;
  late bool _killSwitchEnabled;
  late bool _vpnAccelerator;
  late bool _showSpeedInNotification;
  late String _selectedProtocol;

  @override
  void initState() {
    super.initState();
    _netShieldEnabled = AppPreferences.netShieldEnabled;
    _killSwitchEnabled = AppPreferences.killSwitchEnabled;
    _vpnAccelerator = AppPreferences.vpnAcceleratorEnabled;
    _showSpeedInNotification = AppPreferences.showSpeedNotification;
    _selectedProtocol = AppPreferences.selectedProtocol;
  }

  void _promptSignIn(String feature) {
    final isDark = ThemeManager.instance.isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161426) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Color(0xFF6B42FF), size: 22),
            const SizedBox(width: 10),
            Text(
              'Sign In Required',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1D1536),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          '$feature requires an active Firefox Account session on Fastly MASQUE.\n\nPlease log in to activate advanced routing features.',
          style: TextStyle(
            color: isDark ? const Color(0xFF8E8B9D) : const Color(0xFF6E6B80),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? const Color(0xFF8E8B9D) : const Color(0xFF6E6B80)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B42FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              SignInDialog.show(context, widget.controller);
            },
            child: const Text('Sign In', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String maskEmail(String email) {
    if (!email.contains('@')) return email;
    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '$name••@$domain';
    return '${name.substring(0, 2)}•••••@$domain';
  }

  void _showProtocolPicker(BuildContext context) {
    final isDark = ThemeManager.instance.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161426) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: const Color(0xFF6B42FF).withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B42FF).withValues(alpha: 0.25),
                blurRadius: 28,
                spreadRadius: 2,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
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
                  Text(
                    'Select VPN Protocol',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1D1536),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _protocolTile('Smart (Automatic)', 'Automatically picks fastest tunnel', isDark),
                  const SizedBox(height: 12),
                  _protocolTile('WireGuard MASQUE (HTTP/3)', 'Fastest speed via QUIC UDP encapsulation', isDark),
                  const SizedBox(height: 12),
                  _protocolTile('Fastly HTTP/2 MASQUE', 'Fallback for restricted TCP networks', isDark),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _protocolTile(String title, String desc, bool isDark) {
    final isSelected = _selectedProtocol == title;
    final itemBg = isSelected
        ? const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.18 : 0.10)
        : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _selectedProtocol = title);
          AppPreferences.setSelectedProtocol(title);
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: itemBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6B42FF).withValues(alpha: 0.6)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? const Color(0xFF6B42FF)
                            : (isDark ? Colors.white : const Color(0xFF1D1536)),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF8F8C9E) : const Color(0xFF757288),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF6B42FF),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, ThemeManager.instance]),
      builder: (context, _) {
        final hasAccount = widget.controller.hasAccount;
        final activeAccount = widget.controller.activeAccount;
        final isDark = ThemeManager.instance.isDarkMode;
        final isLiquid = ThemeManager.instance.isLiquidGlass;

        final textPrimary = isDark ? Colors.white : const Color(0xFF1D1536);
        final textSecondary = isDark ? const Color(0xFF8E8B9D) : const Color(0xFF6E6B80);
        final cardBg = isDark
            ? (isLiquid ? const Color(0xFF161426).withValues(alpha: 0.88) : const Color(0xFF161426))
            : (isLiquid ? Colors.white.withValues(alpha: 0.90) : Colors.white);

        final cardBorder = isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFF5D5380).withValues(alpha: 0.10);

        final dividerColor = isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFF5D5380).withValues(alpha: 0.06);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Settings',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure VPN protocols, security features, routing, and app preferences.',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 22),

              // ACCOUNT Section
              _buildSectionHeader('ACCOUNT', textSecondary),
              const SizedBox(height: 8),
              _buildCardContainer(
                cardBg: cardBg,
                cardBorder: cardBorder,
                children: [
                  _buildActionRow(
                    icon: hasAccount ? Icons.manage_accounts_rounded : Icons.person_add_alt_1_rounded,
                    title: hasAccount ? 'Account (${maskEmail(activeAccount?.email ?? 'user')})' : 'Add Account',
                    subtitle: hasAccount
                        ? 'Firefox Account Active · Tap to manage or switch'
                        : 'Sign in with Firefox Account for Fastly MASQUE',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: hasAccount
                            ? (isDark ? const Color(0xFF133226) : const Color(0xFFD8F5EB))
                            : (isDark ? const Color(0xFF261D4C) : const Color(0xFFEDE9F8)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hasAccount
                              ? (isDark ? const Color(0xFF1FE5BD).withValues(alpha: 0.5) : const Color(0xFF00C896).withValues(alpha: 0.5))
                              : const Color(0xFF6B42FF).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        hasAccount ? 'ACTIVE' : '+ SIGN IN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: hasAccount
                              ? (isDark ? const Color(0xFF1FE5BD) : const Color(0xFF00A36C))
                              : const Color(0xFF6B42FF),
                        ),
                      ),
                    ),
                    onTap: () {
                      if (hasAccount) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AccountManagementScreen(controller: widget.controller)),
                        );
                      } else {
                        SignInDialog.show(context, widget.controller);
                      }
                    },
                  ),
                  if (hasAccount) ...[
                    _buildDivider(dividerColor),
                    _buildActionRow(
                      icon: Icons.workspace_premium_rounded,
                      title: 'TeroVPN Unlimited Pass',
                      subtitle: '50GB Multi-Account Fastly Tier Active',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF261D4C) : const Color(0xFFEDE9F8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF6B42FF).withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B42FF)),
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AccountManagementScreen(controller: widget.controller)),
                        );
                      },
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 22),

              // FEATURES Section
              _buildSectionHeader('FEATURES', textSecondary),
              const SizedBox(height: 8),
              _buildCardContainer(
                cardBg: cardBg,
                cardBorder: cardBorder,
                children: [
                  // NetShield Row
                  _buildSwitchRow(
                    icon: Icons.shield_rounded,
                    title: 'NetShield Ad-blocker',
                    subtitle: 'Block malware, tracking, and intrusive ads',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    value: hasAccount && _netShieldEnabled,
                    isDark: isDark,
                    onChanged: (val) async {
                      if (!hasAccount) {
                        _promptSignIn('NetShield Ad-blocker');
                        return;
                      }
                      setState(() => _netShieldEnabled = val);
                      await AppPreferences.setNetShieldEnabled(val);
                    },
                  ),
                  _buildDivider(dividerColor),
                  // Kill Switch Row
                  _buildSwitchRow(
                    icon: Icons.gpp_maybe_rounded,
                    title: 'Kill Switch',
                    subtitle: 'Disable internet traffic if VPN connection drops',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    value: hasAccount && _killSwitchEnabled,
                    isDark: isDark,
                    onChanged: (val) async {
                      if (!hasAccount) {
                        _promptSignIn('Kill Switch');
                        return;
                      }
                      setState(() => _killSwitchEnabled = val);
                      await AppPreferences.setKillSwitchEnabled(val);
                    },
                  ),
                  _buildDivider(dividerColor),
                  // Split Tunneling Row
                  _buildActionRow(
                    icon: Icons.alt_route_rounded,
                    title: 'Split Tunneling',
                    subtitle: 'Choose which apps bypass the VPN',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    trailing: Icon(Icons.chevron_right_rounded, color: textSecondary, size: 20),
                    onTap: () {
                      if (!hasAccount) {
                        _promptSignIn('Split Tunneling');
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SplitTunnelingScreen()),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // CONNECTION Section
              _buildSectionHeader('CONNECTION', textSecondary),
              const SizedBox(height: 8),
              _buildCardContainer(
                cardBg: cardBg,
                cardBorder: cardBorder,
                children: [
                  _buildActionRow(
                    icon: Icons.security_rounded,
                    title: 'Protocol',
                    subtitle: _selectedProtocol,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    trailing: Icon(Icons.chevron_right_rounded, color: textSecondary, size: 20),
                    onTap: () {
                      if (!hasAccount) {
                        _promptSignIn('VPN Protocol Settings');
                        return;
                      }
                      _showProtocolPicker(context);
                    },
                  ),
                  _buildDivider(dividerColor),
                  _buildSwitchRow(
                    icon: Icons.speed_rounded,
                    title: 'VPN Accelerator',
                    subtitle: 'Multipath UDP & QUIC routing optimization',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    value: hasAccount && _vpnAccelerator,
                    isDark: isDark,
                    onChanged: (val) async {
                      if (!hasAccount) {
                        _promptSignIn('VPN Accelerator');
                        return;
                      }
                      setState(() => _vpnAccelerator = val);
                      await AppPreferences.setVpnAcceleratorEnabled(val);
                    },
                  ),
                  _buildDivider(dividerColor),
                  _buildSwitchRow(
                    icon: Icons.notifications_active_outlined,
                    title: 'Show Speed in Notification',
                    subtitle: 'Live transfer speeds in status bar',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    value: _showSpeedInNotification,
                    isDark: isDark,
                    onChanged: (val) async {
                      setState(() => _showSpeedInNotification = val);
                      await AppPreferences.setShowSpeedNotification(val);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ABOUT & UPDATES Section
              _buildSectionHeader('ABOUT & UPDATES', textSecondary),
              const SizedBox(height: 8),
              _buildCardContainer(
                cardBg: cardBg,
                cardBorder: cardBorder,
                children: [
                  _buildActionRow(
                    icon: Icons.info_outline_rounded,
                    title: 'About TeroVPN',
                    subtitle: 'Version 1.1.1 · Legal, Support & Acknowledgements',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    trailing: Icon(Icons.chevron_right_rounded, color: textSecondary, size: 20),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    },
                  ),
                  _buildDivider(dividerColor),
                  _buildActionRow(
                    icon: Icons.system_update_alt_rounded,
                    title: 'App Update',
                    subtitle: 'Check for updates and release preferences',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    trailing: Icon(Icons.chevron_right_rounded, color: textSecondary, size: 20),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AppUpdateScreen()),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ADVANCED Section
              _buildSectionHeader('ADVANCED', textSecondary),
              const SizedBox(height: 8),
              _buildCardContainer(
                cardBg: cardBg,
                cardBorder: cardBorder,
                children: [
                  _buildActionRow(
                    icon: Icons.palette_outlined,
                    title: 'Theme',
                    subtitle: ThemeManager.instance.currentTheme,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    trailing: Icon(Icons.chevron_right_rounded, color: textSecondary, size: 20),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
                      );
                    },
                  ),
                  _buildDivider(dividerColor),
                  _buildSwitchRow(
                    icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    title: 'Dark Mode',
                    subtitle: isDark ? 'Obsidian cosmic dark theme' : 'Frosted iridescent light theme',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    value: isDark,
                    isDark: isDark,
                    onChanged: (val) async {
                      await ThemeManager.instance.setDarkMode(val);
                    },
                  ),
                  _buildDivider(dividerColor),
                  _buildActionRow(
                    icon: Icons.tune_rounded,
                    title: 'Extra Functions',
                    subtitle: 'IPv6 Leak, DNS Fallback, LAN Bypass & Hardware Acceleration',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    trailing: Icon(Icons.chevron_right_rounded, color: textSecondary, size: 20),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ExtraFunctionsScreen()),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        color: textColor,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildCardContainer({
    required Color cardBg,
    required Color cardBorder,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider(Color dividerColor) {
    return Divider(height: 1, thickness: 1, color: dividerColor);
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textPrimary,
    required Color textSecondary,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF8B6BFF), size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textPrimary,
    required Color textSecondary,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8B6BFF), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF6B42FF),
            activeTrackColor: isDark ? const Color(0xFF261D4C) : const Color(0xFFDED8F7),
            inactiveThumbColor: isDark ? const Color(0xFF757286) : const Color(0xFFABA7BE),
            inactiveTrackColor: isDark ? const Color(0xFF1E1C2F) : const Color(0xFFE5E2F0),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
