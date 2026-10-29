import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../core/core_controller.dart';
import '../../core/app_preferences.dart';
import '../../core/format.dart';
import '../components/signin_dialog.dart';
import 'settings_row.dart';
import 'split_tunneling_screen.dart';
import 'about_screen.dart';
import 'app_update_screen.dart';
import 'account_management_screen.dart';
import '../../theme/theme_manager.dart';
import 'theme_settings_screen.dart';
import 'extra_functions_screen.dart';

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
      builder: (ctx) => AlertDialog(
        backgroundColor: ProtonColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ProtonColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_outline_rounded, color: ProtonColors.activeLabel, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sign In Required',
                style: ProtonTypography.titleMedium.copyWith(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Please sign in with your Firefox Account to configure $featureName and unlock advanced security controls.',
          style: ProtonTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: ProtonColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              SignInDialog.show(context, widget.controller);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ProtonColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
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

        return Scaffold(
          backgroundColor: isLiquid ? const Color(0xFF0B0A13) : ProtonColors.background,
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
                    style: ProtonTypography.titleLarge,
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
                                ? ProtonColors.connected.withValues(alpha: 0.15)
                                : ProtonColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: hasAccount
                                  ? ProtonColors.connected.withValues(alpha: 0.4)
                                  : ProtonColors.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            hasAccount ? 'ACTIVE' : '+ SIGN IN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: hasAccount ? ProtonColors.connected : ProtonColors.activeLabel,
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
                              color: ProtonColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: ProtonColors.primary.withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: ProtonColors.activeLabel,
                              ),
                            ),
                          ),
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
                          activeThumbColor: ProtonColors.primary,
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
                          activeThumbColor: ProtonColors.primary,
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
                          color: ProtonColors.textMuted,
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
                          color: ProtonColors.textMuted,
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
                          activeThumbColor: ProtonColors.primary,
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
                          activeThumbColor: ProtonColors.primary,
                          onChanged: (val) {
                            setState(() => _showSpeedInNotification = val);
                            AppPreferences.setShowSpeedNotification(val);
                          },
                        ),
                      ),
                    ],
                  ),

                  // About & Update Section (Replaces Version)
                  SettingsSectionCard(
                    title: 'About TeroVPN',
                    children: [
                      SettingsRow(
                        icon: Icons.info_outline_rounded,
                        title: 'About TeroVPN',
                        subtitle: 'Version 1.0.7 · Legal, Support & Acknowledgements',
                        trailing: const Icon(Icons.chevron_right_rounded, color: ProtonColors.textMuted),
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
                        trailing: const Icon(Icons.chevron_right_rounded, color: ProtonColors.textMuted),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AppUpdateScreen()),
                          );
                        },
                      ),
                    ],
                  ),

                  // Advanced Category
                  SettingsSectionCard(
                    title: 'Advanced',
                    children: [
                      SettingsRow(
                        icon: Icons.palette_outlined,
                        title: 'Theme',
                        subtitle: ThemeManager.instance.currentTheme,
                        trailing: const Icon(Icons.chevron_right_rounded, color: ProtonColors.textMuted),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
                          );
                        },
                      ),
                      SettingsRow(
                        icon: Icons.tune_rounded,
                        title: 'Extra Functions',
                        subtitle: 'IPv6 Leak, DNS Fallback, LAN Bypass & Hardware Acceleration',
                        trailing: const Icon(Icons.chevron_right_rounded, color: ProtonColors.textMuted),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ExtraFunctionsScreen()),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: ProtonColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select VPN Protocol', style: ProtonTypography.titleMedium),
                const SizedBox(height: 16),
                _protocolTile('Smart (Automatic)', 'Automatically picks fastest tunnel'),
                _protocolTile('WireGuard MASQUE (HTTP/3)', 'Fastest speed via QUIC UDP encapsulation'),
                _protocolTile('Fastly HTTP/2 MASQUE', 'Fallback for restricted TCP networks'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _protocolTile(String title, String desc) {
    final isSelected = _selectedProtocol == title;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: ProtonTypography.bodyLarge.copyWith(
          color: isSelected ? ProtonColors.activeLabel : ProtonColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: Text(desc, style: ProtonTypography.bodySmall),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: ProtonColors.primary)
          : null,
      onTap: () {
        setState(() => _selectedProtocol = title);
        AppPreferences.setSelectedProtocol(title);
        Navigator.of(context).pop();
      },
    );
  }
}
