import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../core/core_controller.dart';
import 'settings_row.dart';
import 'split_tunneling_screen.dart';

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
  bool _netShieldEnabled = true;
  bool _killSwitchEnabled = true;
  bool _vpnAccelerator = true;
  bool _showSpeedInNotification = true;
  String _selectedProtocol = 'WireGuard MASQUE (HTTP/3)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProtonColors.background,
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
                  SettingsRow(
                    icon: Icons.workspace_premium_rounded,
                    title: 'TeroVPN Unlimited Pass',
                    subtitle: '50GB Multi-Account Fastly Tier Active',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ProtonColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ProtonColors.primary.withOpacity(0.5)),
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

              // Security & Features
              SettingsSectionCard(
                title: 'Features',
                children: [
                  SettingsRow(
                    icon: Icons.shield_rounded,
                    title: 'NetShield Ad-blocker',
                    subtitle: 'Block malware, tracking, and intrusive ads',
                    trailing: Switch(
                      value: _netShieldEnabled,
                      activeColor: ProtonColors.primary,
                      onChanged: (val) => setState(() => _netShieldEnabled = val),
                    ),
                  ),
                  SettingsRow(
                    icon: Icons.gpp_maybe_rounded,
                    title: 'Kill Switch',
                    subtitle: 'Disable internet traffic if VPN connection drops',
                    trailing: Switch(
                      value: _killSwitchEnabled,
                      activeColor: ProtonColors.primary,
                      onChanged: (val) => setState(() => _killSwitchEnabled = val),
                    ),
                  ),
                  SettingsRow(
                    icon: Icons.alt_route_rounded,
                    title: 'Split Tunneling',
                    subtitle: 'Choose which apps bypass the VPN',
                    trailing: const Icon(Icons.chevron_right_rounded, color: ProtonColors.textMuted),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SplitTunnelingScreen()),
                      );
                    },
                  ),
                ],
              ),

              // Connection & Protocol
              SettingsSectionCard(
                title: 'Connection',
                children: [
                  SettingsRow(
                    icon: Icons.security_rounded,
                    title: 'Protocol',
                    subtitle: _selectedProtocol,
                    trailing: const Icon(Icons.chevron_right_rounded, color: ProtonColors.textMuted),
                    onTap: () => _showProtocolPicker(context),
                  ),
                  SettingsRow(
                    icon: Icons.speed_rounded,
                    title: 'VPN Accelerator',
                    subtitle: 'Multipath UDP & QUIC routing optimization',
                    trailing: Switch(
                      value: _vpnAccelerator,
                      activeColor: ProtonColors.primary,
                      onChanged: (val) => setState(() => _vpnAccelerator = val),
                    ),
                  ),
                  SettingsRow(
                    icon: Icons.notifications_active_outlined,
                    title: 'Show Speed in Notification',
                    subtitle: 'Live transfer speeds in Android status bar',
                    trailing: Switch(
                      value: _showSpeedInNotification,
                      activeColor: ProtonColors.primary,
                      onChanged: (val) => setState(() => _showSpeedInNotification = val),
                    ),
                  ),
                ],
              ),

              // About TeroVPN
              SettingsSectionCard(
                title: 'About',
                children: [
                  SettingsRow(
                    icon: Icons.info_outline_rounded,
                    title: 'Version',
                    subtitle: '1.0.0 (Build 1)',
                  ),
                  SettingsRow(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Zero-Logs Policy',
                    subtitle: 'Verified Fastly MASQUE Privacy Protocol',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
        Navigator.of(context).pop();
      },
    );
  }
}
