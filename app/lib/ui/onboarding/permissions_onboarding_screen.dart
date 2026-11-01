import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/android_core.dart';
import '../../core/app_preferences.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';

class PermissionsOnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const PermissionsOnboardingScreen({super.key, required this.onFinished});

  @override
  State<PermissionsOnboardingScreen> createState() =>
      _PermissionsOnboardingScreenState();
}

class _PermissionsOnboardingScreenState
    extends State<PermissionsOnboardingScreen> with WidgetsBindingObserver {
  bool _vpnGranted = false;
  bool _notifGranted = false;
  bool _nearbyGranted = false;
  bool _usageGranted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _refreshPermissions() async {
    if (kIsWeb || !Platform.isAndroid) {
      if (mounted) {
        setState(() {
          _vpnGranted = true;
          _notifGranted = true;
          _nearbyGranted = true;
          _usageGranted = true;
          _isLoading = false;
        });
      }
      return;
    }

    final perms = await AndroidCore.checkPermissions();
    if (mounted) {
      setState(() {
        _vpnGranted = perms['vpn'] == true;
        _notifGranted = perms['notifications'] == true;
        _nearbyGranted = perms['nearby'] == true;
        _usageGranted = perms['usage_access'] == true;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestVpn() async {
    await AndroidCore.requestVpnPermission();
    await _refreshPermissions();
  }

  Future<void> _requestNotif() async {
    await AndroidCore.requestNotificationPermission();
    await _refreshPermissions();
  }

  Future<void> _requestNearby() async {
    await AndroidCore.requestNearbyPermission();
    await _refreshPermissions();
  }

  Future<void> _requestUsage() async {
    await AndroidCore.requestUsageAccessPermission();
  }

  Future<void> _grantAll() async {
    if (!_vpnGranted) {
      await AndroidCore.requestVpnPermission();
    }
    if (!_notifGranted) {
      await AndroidCore.requestNotificationPermission();
    }
    if (!_nearbyGranted) {
      await AndroidCore.requestNearbyPermission();
    }
    await _refreshPermissions();
  }

  void _finish() {
    AppPreferences.setPermissionsOnboardingDone(true);
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.instance.isDarkMode;
    final bg = ThemeManager.instance.backgroundColor;
    final surface = ThemeManager.instance.surfaceColor;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFF6B42FF).withValues(alpha: 0.12);
    final textPrimary = ThemeManager.instance.textPrimaryColor;
    final textSecondary = ThemeManager.instance.textSecondaryColor;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6B42FF)))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Shield Icon with Liquid Glow
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF6B42FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B42FF).withValues(alpha: 0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'System Permissions',
                      style: ProtonTypography.titleLarge.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'To route your internet traffic securely and keep VPN active in the background, please grant the following permissions:',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // Permissions List
                    Expanded(
                      child: ListView(
                        children: [
                          _buildPermItem(
                            icon: Icons.vpn_lock_rounded,
                            title: 'VPN Connection Request',
                            subtitle: 'Mandatory · Encrypts traffic via Fastly MASQUE',
                            isGranted: _vpnGranted,
                            isRequired: true,
                            onTap: _requestVpn,
                            surface: surface,
                            border: border,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                          const SizedBox(height: 12),
                          _buildPermItem(
                            icon: Icons.notifications_active_rounded,
                            title: 'Notifications',
                            subtitle: 'Status bar connection indicator & alerts',
                            isGranted: _notifGranted,
                            isRequired: false,
                            onTap: _requestNotif,
                            surface: surface,
                            border: border,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                          const SizedBox(height: 12),
                          _buildPermItem(
                            icon: Icons.devices_other_rounded,
                            title: 'Nearby Devices',
                            subtitle: 'Fast QR pairing and local desktop sync',
                            isGranted: _nearbyGranted,
                            isRequired: false,
                            onTap: _requestNearby,
                            surface: surface,
                            border: border,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                          const SizedBox(height: 12),
                          _buildPermItem(
                            icon: Icons.data_usage_rounded,
                            title: 'App Usage Access',
                            subtitle: 'Per-app split tunneling & data tracking',
                            isGranted: _usageGranted,
                            isRequired: false,
                            onTap: _requestUsage,
                            surface: surface,
                            border: border,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ],
                      ),
                    ),

                    // Actions
                    const SizedBox(height: 16),
                    if (!_vpnGranted || !_notifGranted || !_nearbyGranted)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _grantAll,
                          icon: const Icon(Icons.flash_on_rounded, size: 20),
                          label: const Text(
                            'Grant Recommended Permissions',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B42FF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: _finish,
                        child: Text(
                          _vpnGranted ? 'Continue to TeroVPN' : 'Skip for now',
                          style: TextStyle(
                            color: _vpnGranted ? const Color(0xFF8B5CF6) : textSecondary,
                            fontSize: 15,
                            fontWeight: _vpnGranted ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPermItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    required bool isRequired,
    required VoidCallback onTap,
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? border : const Color(0xFF6B42FF).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isGranted
                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                  : const Color(0xFF6B42FF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isGranted ? const Color(0xFF10B981) : const Color(0xFF6B42FF),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
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
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isRequired) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Required',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isGranted)
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24)
          else
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B42FF),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text(
                'Allow',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}
