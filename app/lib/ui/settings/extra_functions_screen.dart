import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../../core/app_preferences.dart';
import 'settings_row.dart';

class ExtraFunctionsScreen extends StatefulWidget {
  const ExtraFunctionsScreen({super.key});

  @override
  State<ExtraFunctionsScreen> createState() => _ExtraFunctionsScreenState();
}

class _ExtraFunctionsScreenState extends State<ExtraFunctionsScreen> {
  late bool _ipv6Leak;
  late bool _dnsFallback;
  late bool _lanBypass;
  late bool _hardwareAccel;

  @override
  void initState() {
    super.initState();
    _ipv6Leak = AppPreferences.ipv6LeakProtection;
    _dnsFallback = AppPreferences.dnsFallback;
    _lanBypass = AppPreferences.lanBypass;
    _hardwareAccel = AppPreferences.hardwareAcceleration;
  }

  @override
  Widget build(BuildContext context) {
    final isLiquid = ThemeManager.instance.isLiquidGlass;

    return Scaffold(
      backgroundColor: isLiquid ? const Color(0xFF0B0A13) : ProtonColors.background,
      appBar: AppBar(
        title: Text(
          'Extra Functions',
          style: ProtonTypography.titleLarge.copyWith(fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ProtonColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            SettingsSectionCard(
              title: 'NETWORK & PRIVACY',
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
                  icon: Icons.dns_rounded,
                  title: 'DNS Fallback',
                  subtitle: 'Automatic failover to Cloudflare DNS (1.1.1.1) if MASQUE resolver stalls',
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
            SettingsSectionCard(
              title: 'ENGINE & HARDWARE',
              children: [
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
          ],
        ),
      ),
    );
  }
}
