import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../../core/app_preferences.dart';
import '../../core/core_controller.dart';
import '../components/signin_dialog.dart';
import 'dart:io' show Platform;
import 'settings_row.dart';
import 'split_tunneling_screen.dart';
import 'about_screen.dart';
import 'app_update_screen.dart';
import 'theme_settings_screen.dart';
import 'extra_functions_screen.dart';
import 'account_management_screen.dart';
import 'sign_in_with_phone_screen.dart';

class SettingsScreen extends StatefulWidget {
  final CoreController controller;

  const SettingsScreen({
    super.key,
    required this.controller,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

  void _promptLoginRequired(String featureName) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = ThemeManager.instance.isDarkMode;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1728) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.lock_rounded, color: Color(0xFF6B42FF), size: 24),
              const SizedBox(width: 10),
              Text(
                'Firefox Account Required',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1D1536),
                ),
              ),
            ],
          ),
          content: Text(
            '$featureName requires an active Firefox Account session on Fastly MASQUE.\n\nPlease log in to activate advanced routing features.',
            style: TextStyle(
              color: isDark ? const Color(0xFF8F8C9E) : const Color(0xFF757288),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? const Color(0xFF8F8C9E) : const Color(0xFF757288)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                SignInDialog.show(context, widget.controller);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B42FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Sign In Now'),
            ),
          ],
        );
      },
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final hasAccount = widget.controller.hasAccount;
            final activeAccount = widget.controller.activeAccount;
            final isLiquid = ThemeManager.instance.isLiquidGlass;
            final isDark = ThemeManager.instance.isDarkMode;
            final textPrimary = ThemeManager.instance.textPrimaryColor;
            final textSecondary = ThemeManager.instance.textSecondaryColor;

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 12,
                    bottom: 120,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: isLiquid
                            ? TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                letterSpacing: -0.5,
                              )
                            : ProtonTypography.titleLarge.copyWith(color: textPrimary),
                      ),
                      const SizedBox(height: 20),

                      // Account Section
                      SettingsSectionCard(
                        title: 'Account',
                        children: [
                          // 1. Add Account Option
                          SettingsRow(
                            icon: hasAccount ? Icons.manage_accounts_rounded : Icons.person_add_alt_1_rounded,
                            title: hasAccount ? 'Account (${maskEmail(activeAccount?.email ?? 'user')})' : 'Add Account',
                            subtitle: hasAccount
                                ? 'Firefox Account Active · Tap to switch or add'
                                : 'Sign in with Firefox Account for Fastly MASQUE',
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: hasAccount
                                    ? (isDark ? ProtonColors.connected.withValues(alpha: 0.15) : const Color(0xFFE0F7EF))
                                    : (isDark ? ProtonColors.primary.withValues(alpha: 0.2) : const Color(0xFFF0EDFA)),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: hasAccount
                                      ? (isDark ? ProtonColors.connected.withValues(alpha: 0.4) : const Color(0xFFBBEEDF))
                                      : (isDark ? ProtonColors.primary.withValues(alpha: 0.5) : const Color(0xFFDCD4F8)),
                                ),
                              ),
                              child: Text(
                                hasAccount ? 'ACTIVE' : '+ SIGN IN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: hasAccount
                                      ? (isDark ? ProtonColors.connected : const Color(0xFF00A36C))
                                      : const Color(0xFF6B42FF),
                                ),
                              ),
                            ),
                            onTap: hasAccount
                                ? () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => AccountManagementScreen(controller: widget.controller),
                                      ),
                                    )
                                : () => SignInDialog.show(context, widget.controller),
                          ),

                          // 2. TeroVPN Unlimited Pass - ONLY visible when account is logged in!
                          if (hasAccount)
                            SettingsRow(
                              icon: Icons.workspace_premium_rounded,
                              title: 'TeroVPN Unlimited Pass',
                              subtitle: '50GB Multi-Account Fastly Tier Active',
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF261D42) : const Color(0xFFF0EDFA),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF6B42FF).withValues(alpha: 0.5) : const Color(0xFFDCD4F8),
                                  ),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF6B42FF),
                                  ),
                                ),
                              ),
                            ),
                          SettingsRow(
                            icon: Icons.qr_code_scanner_rounded,
                            title: 'Sign in with phone',
                            subtitle: 'Scan desktop QR code to instant sign in',
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B42FF).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF6B42FF),
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SignInWithPhoneScreen(controller: widget.controller),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      // Security & Features (Login required)
                      SettingsSectionCard(
                        title: 'Features',
                        children: [
                          SettingsRow(
                            icon: Icons.shield_rounded,
                            title: 'NetShield Ad-blocker',
                            subtitle: 'Block malware, tracking, and intrusive ads',
                            trailing: Switch(
                              value: hasAccount && _netShieldEnabled,
                              activeThumbColor: const Color(0xFF6B42FF),
                              activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),
                              inactiveTrackColor: isDark ? null : const Color(0xFFD8D5E5),
                              onChanged: (val) {
                                if (!hasAccount) {
                                  _promptLoginRequired('NetShield Ad-blocker');
                                  return;
                                }
                                setState(() => _netShieldEnabled = val);
                                AppPreferences.setNetShieldEnabled(val);
                              },
                            ),
                            onTap: !hasAccount ? () => _promptLoginRequired('NetShield Ad-blocker') : null,
                          ),
                          SettingsRow(
                            icon: Icons.gpp_maybe_rounded,
                            title: 'Kill Switch',
                            subtitle: 'Disable internet traffic if VPN connection drops',
                            trailing: Switch(
                              value: hasAccount && _killSwitchEnabled,
                              activeThumbColor: const Color(0xFF6B42FF),
                              activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),
                              inactiveTrackColor: isDark ? null : const Color(0xFFD8D5E5),
                              onChanged: (val) {
                                if (!hasAccount) {
                                  _promptLoginRequired('Kill Switch');
                                  return;
                                }
                                setState(() => _killSwitchEnabled = val);
                                AppPreferences.setKillSwitchEnabled(val);
                              },
                            ),
                            onTap: !hasAccount ? () => _promptLoginRequired('Kill Switch') : null,
                          ),
                          SettingsRow(
                            icon: Icons.alt_route_rounded,
                            title: 'Split Tunneling',
                            subtitle: 'Choose which apps bypass the VPN',
                            trailing: Icon(
                              hasAccount ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
                              color: textSecondary,
                              size: 20,
                            ),
                            onTap: () {
                              if (!hasAccount) {
                                _promptLoginRequired('Split Tunneling');
                                return;
                              }
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SplitTunnelingScreen()),
                              );
                            },
                          ),
                        ],
                      ),

                      // Connection & Protocol (Login required)
                      SettingsSectionCard(
                        title: 'Connection',
                        children: [
                          SettingsRow(
                            icon: Icons.security_rounded,
                            title: 'Protocol',
                            subtitle: _selectedProtocol,
                            trailing: Icon(
                              hasAccount ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
                              color: textSecondary,
                              size: 20,
                            ),
                            onTap: () {
                              if (!hasAccount) {
                                _promptLoginRequired('VPN Protocol Settings');
                                return;
                              }
                              _showProtocolPicker(context);
                            },
                          ),
                          SettingsRow(
                            icon: Icons.speed_rounded,
                            title: 'VPN Accelerator',
                            subtitle: 'Multipath UDP & QUIC routing optimization',
                            trailing: Switch(
                              value: hasAccount && _vpnAccelerator,
                              activeThumbColor: const Color(0xFF6B42FF),
                              activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),
                              inactiveTrackColor: isDark ? null : const Color(0xFFD8D5E5),
                              onChanged: (val) {
                                if (!hasAccount) {
                                  _promptLoginRequired('VPN Accelerator');
                                  return;
                                }
                                setState(() => _vpnAccelerator = val);
                                AppPreferences.setVpnAcceleratorEnabled(val);
                              },
                            ),
                            onTap: !hasAccount ? () => _promptLoginRequired('VPN Accelerator') : null,
                          ),
                          SettingsRow(
                            icon: Icons.notifications_active_outlined,
                            title: 'Show Speed in Notification',
                            subtitle: 'Live transfer speeds in Android status bar',
                            trailing: Switch(
                              value: _showSpeedInNotification,
                              activeThumbColor: const Color(0xFF6B42FF),
                              activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),
                              inactiveTrackColor: isDark ? null : const Color(0xFFD8D5E5),
                              onChanged: (val) {
                                setState(() => _showSpeedInNotification = val);
                                AppPreferences.setShowSpeedNotification(val);
                              },
                            ),
                          ),
                        ],
                      ),

                      // About & Update Section
                      SettingsSectionCard(
                        title: 'About TeroVPN',
                        children: [
                          SettingsRow(
                            icon: Icons.info_outline_rounded,
                            title: 'About TeroVPN',
                            subtitle: 'Version 1.1.1 · Legal, Support & Acknowledgements',
                            trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AboutScreen()),
                              );
                            },
                          ),
                          SettingsRow(
                            icon: Icons.system_update_alt_rounded,
                            title: 'App Update',
                            subtitle: 'Check for updates and release preferences',
                            trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AppUpdateScreen()),
                              );
                            },
                          ),
                        ],
                      ),

                      // Advanced Category (Theme, Dark/Light Mode Switcher, Extra Functions)
                      SettingsSectionCard(
                        title: 'Advanced',
                        children: [
                          SettingsRow(
                            icon: Icons.palette_outlined,
                            title: 'Theme',
                            subtitle: ThemeManager.instance.currentTheme,
                            trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
                              );
                            },
                          ),
                          // Dark/Light Mode Switcher
                          SettingsRow(
                            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            title: 'Dark Mode',
                            subtitle: isDark ? 'Obsidian cosmic dark theme' : 'Frosted iridescent light theme',
                            trailing: Switch(
                              value: isDark,
                              activeThumbColor: const Color(0xFF6B42FF),
                              activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),
                              inactiveTrackColor: isDark ? null : const Color(0xFFD8D5E5),
                              onChanged: (val) async {
                                await ThemeManager.instance.setDarkMode(val);
                              },
                            ),
                            onTap: () async {
                              await ThemeManager.instance.setDarkMode(!isDark);
                            },
                          ),
                          SettingsRow(
                            icon: Icons.tune_rounded,
                            title: 'Extra Functions',
                            subtitle: 'Custom DNS, Leak Protection, LAN Bypass, Moderate NAT & MTU',
                            trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => ExtraFunctionsScreen(controller: widget.controller)),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showProtocolPicker(BuildContext context) {
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
                  _protocolTile(
                    'Smart (Automatic)',
                    'Automatically chooses fastest protocol and bypasses network blocks',
                    'RECOMMENDED',
                    isDark,
                  ),
                  const SizedBox(height: 10),
                  _protocolTile(
                    'WireGuard (UDP)',
                    'Fastest throughput and lowest latency via modern WireGuard',
                    'FASTEST',
                    isDark,
                  ),
                  const SizedBox(height: 10),
                  _protocolTile(
                    'WireGuard (TCP)',
                    'WireGuard over TCP port 443 to bypass restrictive firewalls',
                    'STABLE',
                    isDark,
                  ),
                  const SizedBox(height: 10),
                  _protocolTile(
                    'Stealth (TLS Obfuscated)',
                    'Anti-censorship TLS protocol disguised as normal HTTPS traffic',
                    'OBFUSCATED',
                    isDark,
                  ),
                  const SizedBox(height: 10),
                  _protocolTile(
                    'OpenVPN (UDP)',
                    'Traditional battle-tested OpenVPN protocol over UDP',
                    'SECURE',
                    isDark,
                  ),
                  const SizedBox(height: 10),
                  _protocolTile(
                    'OpenVPN (TCP)',
                    'Resilient OpenVPN over TCP through restrictive networks',
                    'RELIABLE',
                    isDark,
                  ),
                  if (Platform.isMacOS) ...[
                    const SizedBox(height: 10),
                    _protocolTile(
                      'IKEv2 (macOS Native)',
                      'Native Apple network extension with seamless handoff',
                      'MACOS',
                      isDark,
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _protocolTile(String title, String desc, String badge, bool isDark) {
    final isSelected = _selectedProtocol == title;
    final itemBg = isSelected
        ? const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.18 : 0.10)
        : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          setState(() => _selectedProtocol = title);
          await widget.controller.setProtocol(title);
          if (mounted) Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? const Color(0xFF6B42FF)
                                  : (isDark ? Colors.white : const Color(0xFF1D1536)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.25 : 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF8B6BFF),
                            ),
                          ),
                        ),
                      ],
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
}
