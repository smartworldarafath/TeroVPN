import 'package:flutter/material.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../../core/app_preferences.dart';
import '../../core/core_controller.dart';
import 'settings_row.dart';

class ExtraFunctionsScreen extends StatefulWidget {
  final CoreController? controller;

  const ExtraFunctionsScreen({
    super.key,
    this.controller,
  });

  @override
  State<ExtraFunctionsScreen> createState() => _ExtraFunctionsScreenState();
}

class _ExtraFunctionsScreenState extends State<ExtraFunctionsScreen> {
  late bool _ipv6Leak;
  late bool _dnsLeak;
  late bool _dnsFallback;
  late bool _lanBypass;
  late bool _customDns;
  late TextEditingController _primaryDnsController;
  late TextEditingController _secondaryDnsController;
  late bool _altRouting;
  late bool _moderateNat;
  late bool _portForwarding;
  late int _mtuSize;
  late bool _hardwareAccel;
  late bool _autoConnectOnLaunch;

  @override
  void initState() {
    super.initState();
    _ipv6Leak = AppPreferences.ipv6LeakProtection;
    _dnsLeak = AppPreferences.dnsLeakProtection;
    _dnsFallback = AppPreferences.dnsFallback;
    _lanBypass = AppPreferences.lanBypass;
    _customDns = AppPreferences.customDnsEnabled;
    _primaryDnsController = TextEditingController(text: AppPreferences.customDnsPrimary);
    _secondaryDnsController = TextEditingController(text: AppPreferences.customDnsSecondary);
    _altRouting = AppPreferences.alternativeRouting;
    _moderateNat = AppPreferences.moderateNat;
    _portForwarding = AppPreferences.portForwarding;
    _mtuSize = AppPreferences.tunnelMtu;
    _hardwareAccel = AppPreferences.hardwareAcceleration;
    _autoConnectOnLaunch = AppPreferences.autoConnectOnLaunch;
  }

  @override
  void dispose() {
    _primaryDnsController.dispose();
    _secondaryDnsController.dispose();
    super.dispose();
  }

  void _saveDnsSettings() {
    widget.controller?.applyCustomDns(
      _customDns,
      _primaryDnsController.text.trim(),
      _secondaryDnsController.text.trim(),
    );
  }

  void _setDnsPreset(String name, String primary, String secondary) {
    setState(() {
      _customDns = true;
      _primaryDnsController.text = primary;
      _secondaryDnsController.text = secondary;
    });
    _saveDnsSettings();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied DNS preset: $name ($primary)'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;
        final textPrimary = ThemeManager.instance.textPrimaryColor;
        final textSecondary = ThemeManager.instance.textSecondaryColor;

        return Scaffold(
          backgroundColor: ThemeManager.instance.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Advanced Settings (Extra Functions)',
              style: ProtonTypography.titleLarge.copyWith(
                fontSize: 19,
                color: textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                // 1. NETWORK & LEAK PROTECTION
                SettingsSectionCard(
                  title: 'NETWORK & LEAK PROTECTION',
                  children: [
                    SettingsRow(
                      icon: Icons.security_rounded,
                      title: 'IPv6 Leak Protection',
                      subtitle: 'Completely drop untunneled IPv6 packets to prevent IP leakage',
                      trailing: Switch(
                        value: _ipv6Leak,
                        activeThumbColor: const Color(0xFF6B42FF),
                        activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),
                        onChanged: (val) {
                          setState(() => _ipv6Leak = val);
                          AppPreferences.setIpv6LeakProtection(val);
                        },
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.verified_user_rounded,
                      title: 'DNS Leak Protection',
                      subtitle: 'Strictly force all DNS queries through private encrypted VPN tunnel',
                      trailing: Switch(
                        value: _dnsLeak,
                        activeThumbColor: const Color(0xFF6B42FF),
                        activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),
                        onChanged: (val) {
                          setState(() => _dnsLeak = val);
                          AppPreferences.setDnsLeakProtection(val);
                        },
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.dns_rounded,
                      title: 'DNS Fallback',
                      subtitle: 'Automatic failover to Cloudflare DNS (1.1.1.1) if primary DNS stalls',
                      trailing: Switch(
                        value: _dnsFallback,
                        activeThumbColor: const Color(0xFF6B42FF),
                        activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),
                        onChanged: (val) {
                          setState(() => _dnsFallback = val);
                          AppPreferences.setDnsFallback(val);
                        },
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.router_rounded,
                      title: 'LAN Traffic Bypass',
                      subtitle: 'Allow direct connection to printers, smart TVs, and NAS on local network',
                      trailing: Switch(
                        value: _lanBypass,
                        activeThumbColor: const Color(0xFF6B42FF),
                        activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),
                        onChanged: (val) {
                          setState(() => _lanBypass = val);
                          AppPreferences.setLanBypass(val);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 2. CUSTOM DNS SERVERS (Proton VPN Spec)
                SettingsSectionCard(
                  title: 'CUSTOM DNS RESOLVERS',
                  children: [
                    SettingsRow(
                      icon: Icons.alt_route_rounded,
                      title: 'Custom DNS',
                      subtitle: 'Resolve domains using custom DNS instead of default encrypted DNS',
                      trailing: Switch(
                        value: _customDns,
                        activeThumbColor: const Color(0xFF6B42FF),
                        activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),
                        onChanged: (val) {
                          setState(() => _customDns = val);
                          _saveDnsSettings();
                        },
                      ),
                    ),
                    if (_customDns) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Primary DNS Server',
                              style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _primaryDnsController,
                              style: TextStyle(color: textPrimary, fontSize: 13.5),
                              decoration: InputDecoration(
                                hintText: 'e.g. 1.1.1.1',
                                filled: true,
                                fillColor: isDark ? const Color(0xFF141222) : const Color(0xFFF2F1F8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              onChanged: (_) => _saveDnsSettings(),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Secondary DNS Server (Optional)',
                              style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _secondaryDnsController,
                              style: TextStyle(color: textPrimary, fontSize: 13.5),
                              decoration: InputDecoration(
                                hintText: 'e.g. 1.0.0.1',
                                filled: true,
                                fillColor: isDark ? const Color(0xFF141222) : const Color(0xFFF2F1F8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              onChanged: (_) => _saveDnsSettings(),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Quick Presets:',
                              style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _buildPresetChip('Cloudflare', '1.1.1.1', '1.0.0.1', isDark),
                                _buildPresetChip('Google', '8.8.8.8', '8.8.4.4', isDark),
                                _buildPresetChip('Quad9', '9.9.9.9', '149.112.112.112', isDark),
                                _buildPresetChip('AdGuard', '94.140.14.14', '94.140.15.15', isDark),
                              ],
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 18),

                // 3. ADVANCED ROUTING & PROTOCOL ENHANCEMENTS
                SettingsSectionCard(
                  title: 'ADVANCED ROUTING & NAT',
                  children: [
                    SettingsRow(
                      icon: Icons.shuffle_rounded,
                      title: 'Alternative Routing',
                      subtitle: 'Bypass ISP censorship using 3rd-party CDN routing (Cloudflare/AWS)',
                      trailing: Switch(
                        value: _altRouting,
                        activeThumbColor: const Color(0xFF6B42FF),
                        activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),
                        onChanged: (val) {
                          setState(() => _altRouting = val);
                          AppPreferences.setAlternativeRouting(val);
                        },
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.sports_esports_rounded,
                      title: 'Moderate NAT',
                      subtitle: 'Improves gaming, VoIP, and video calls by optimizing NAT translation',
                      trailing: Switch(
                        value: _moderateNat,
                        activeThumbColor: const Color(0xFF6B42FF),
                        activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),
                        onChanged: (val) {
                          setState(() => _moderateNat = val);
                          AppPreferences.setModerateNat(val);
                        },
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.swap_calls_rounded,
                      title: 'Port Forwarding (NAT-PMP)',
                      subtitle: 'Enable active incoming port for accelerated P2P and BitTorrent seeding',
                      trailing: Switch(
                        value: _portForwarding,
                        activeThumbColor: const Color(0xFF6B42FF),
                        activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),
                        onChanged: (val) {
                          setState(() => _portForwarding = val);
                          AppPreferences.setPortForwarding(val);
                        },
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.tune_rounded,
                      title: 'Tunnel MTU Size',
                      subtitle: 'Current: $_mtuSize (Auto: 1420) • Optimizes throughput on mobile hotspots',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B42FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_mtuSize',
                          style: const TextStyle(
                            color: Color(0xFF8B6BFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      onTap: () => _showMtuPicker(context),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 4. ENGINE & HARDWARE
                SettingsSectionCard(
                  title: 'ENGINE & HARDWARE',
                  children: [
                    SettingsRow(
                      icon: Icons.power_settings_new_rounded,
                      title: 'Auto-Connect on Startup',
                      subtitle: 'Automatically connect to fastest server when TeroVPN opens',
                      trailing: Switch(
                        value: _autoConnectOnLaunch,
                        activeThumbColor: const Color(0xFF6B42FF),
                        activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),
                        onChanged: (val) {
                          setState(() => _autoConnectOnLaunch = val);
                          AppPreferences.setAutoConnectOnLaunch(val);
                        },
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.speed_rounded,
                      title: 'Hardware Shader Acceleration',
                      subtitle: 'Use GPU Vulkan/OpenGL shaders for real-time liquid glass blurring and 120Hz physics',
                      trailing: Switch(
                        value: _hardwareAccel,
                        activeThumbColor: const Color(0xFF6B42FF),
                        activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),
                        onChanged: (val) {
                          setState(() => _hardwareAccel = val);
                          AppPreferences.setHardwareAcceleration(val);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresetChip(String label, String p, String s, bool isDark) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
      backgroundColor: isDark ? const Color(0xFF261D4C) : const Color(0xFFEDE9F8),
      labelStyle: const TextStyle(color: Color(0xFF8B6BFF)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onPressed: () => _setDnsPreset(label, p, s),
    );
  }

  void _showMtuPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        int selected = _mtuSize;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: ThemeManager.instance.isDarkMode ? const Color(0xFF161426) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Tunnel MTU Size', style: TextStyle(fontWeight: FontWeight.w700)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _mtuTile('Auto (1420 - Recommended)', 1420, selected, (v) => setModalState(() => selected = v)),
                  const SizedBox(height: 6),
                  _mtuTile('Conservative (1360 - High Latency / Hotspots)', 1360, selected, (v) => setModalState(() => selected = v)),
                  const SizedBox(height: 6),
                  _mtuTile('Minimal (1280 - Strict Cellular Hotspots)', 1280, selected, (v) => setModalState(() => selected = v)),
                  const SizedBox(height: 6),
                  _mtuTile('Standard Ethernet (1500)', 1500, selected, (v) => setModalState(() => selected = v)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B42FF)),
                  onPressed: () async {
                    setState(() => _mtuSize = selected);
                    await AppPreferences.setTunnelMtu(selected);
                    if (context.mounted) Navigator.of(ctx).pop();
                  },
                  child: const Text('Apply', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _mtuTile(String title, int val, int currentSelected, ValueChanged<int> onSelect) {
    final isSelected = val == currentSelected;
    final isDark = ThemeManager.instance.isDarkMode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(val),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.20 : 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF6B42FF) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? const Color(0xFF6B42FF) : (isDark ? const Color(0xFF757286) : const Color(0xFFA09DAF)),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : const Color(0xFF1D1536))
                        : (isDark ? const Color(0xFF9E9BAE) : const Color(0xFF6E6B80)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
