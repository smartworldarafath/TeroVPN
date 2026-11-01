import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/android_core.dart';
import '../../core/core_controller.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../components/top_dock_toast.dart';

class PermissionsScreen extends StatefulWidget {
  final CoreController? controller;

  const PermissionsScreen({super.key, this.controller});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  Map<String, bool> _permissions = {
    'vpn': false,
    'network': true,
    'notifications': false,
    'nearby': false,
    'usage_access': false,
    'camera': false,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPermissions();
    }
  }

  Future<void> _loadPermissions() async {
    if (kIsWeb || !Platform.isAndroid) {
      if (mounted) {
        setState(() {
          _permissions = {
            'vpn': true,
            'network': true,
            'notifications': true,
            'nearby': true,
            'usage_access': true,
            'camera': true,
          };
          _isLoading = false;
        });
      }
      return;
    }

    final perms = await AndroidCore.checkPermissions();
    if (mounted) {
      setState(() {
        _permissions = perms;
        _isLoading = false;
      });
    }
  }

  Future<void> _grantVpn() async {
    final granted = await AndroidCore.requestVpnPermission();
    await _loadPermissions();
    if (mounted) {
      TopDockToast.show(
        context,
        title: granted ? 'VPN Allowed' : 'Permission Denied',
        message: granted
            ? 'VPN tunnel configuration successfully authorized.'
            : 'VPN permission was not granted. Secure tunnel cannot be created.',
        icon: granted ? Icons.check_circle_rounded : Icons.error_outline_rounded,
        iconColor: granted ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      );
    }
  }

  Future<void> _grantNotifications() async {
    final granted = await AndroidCore.requestNotificationPermission();
    await _loadPermissions();
    if (mounted) {
      TopDockToast.show(
        context,
        title: granted ? 'Notifications Enabled' : 'Notification Permission',
        message: granted
            ? 'Background VPN alerts and speed tracking enabled.'
            : 'Please allow notifications in Android settings.',
        icon: granted ? Icons.check_circle_rounded : Icons.error_outline_rounded,
        iconColor: granted ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      );
    }
  }

  Future<void> _grantNearby() async {
    final granted = await AndroidCore.requestNearbyPermission();
    await _loadPermissions();
    if (mounted) {
      TopDockToast.show(
        context,
        title: granted ? 'Nearby Devices Allowed' : 'Nearby Devices',
        message: granted
            ? 'Fast local device discovery enabled.'
            : 'Nearby devices permission is required for local sync.',
        icon: granted ? Icons.check_circle_rounded : Icons.error_outline_rounded,
        iconColor: granted ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      );
    }
  }

  Future<void> _grantUsageAccess() async {
    await AndroidCore.requestUsageAccessPermission();
    if (mounted) {
      TopDockToast.show(
        context,
        title: 'Usage Access Settings',
        message: 'Enable TeroVPN under Usage Access, then return to the app.',
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF10B981),
      );
    }
  }

  Future<void> _grantCamera() async {
    final granted = await AndroidCore.requestCameraPermission();
    await _loadPermissions();
    if (mounted) {
      TopDockToast.show(
        context,
        title: granted ? 'Camera Allowed' : 'Camera Denied',
        message: granted
            ? 'Camera permission granted for QR code sign-in.'
            : 'Camera permission is required to scan QR codes.',
        icon: granted ? Icons.check_circle_rounded : Icons.error_outline_rounded,
        iconColor: granted ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      );
    }
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

    final grantedCount = _permissions.values.where((v) => v).length;
    final totalCount = _permissions.length;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Permissions',
          style: ProtonTypography.titleMedium.copyWith(color: textPrimary, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textSecondary, size: 22),
            onPressed: _loadPermissions,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B42FF)),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              children: [
                // Top Summary Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF6B42FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B42FF).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.security_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'System Access & Trust',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$grantedCount of $totalCount permissions authorized',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (grantedCount == totalCount)
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : const Color(0xFF6B42FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (grantedCount == totalCount)
                                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                : const Color(0xFF6B42FF).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          grantedCount == totalCount ? 'Full Trust' : '$grantedCount/$totalCount',
                          style: TextStyle(
                            color: (grantedCount == totalCount)
                                ? const Color(0xFF10B981)
                                : const Color(0xFF8B5CF6),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Note banner about permanent grant policy
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF6B42FF).withValues(alpha: 0.08)
                        : const Color(0xFF6B42FF).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF6B42FF).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFF8B5CF6), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Permissions can be granted here directly. To revoke permissions, visit Android App Settings.',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // 1. VPN Configuration (CRITICAL)
                _buildPermissionCard(
                  icon: Icons.vpn_lock_rounded,
                  title: 'VPN Configuration',
                  badgeText: 'Mandatory',
                  badgeColor: const Color(0xFFEF4444),
                  description:
                      'Required to establish an encrypted local TUN interface and secure all outbound network traffic.',
                  isGranted: _permissions['vpn'] == true,
                  onGrant: _grantVpn,
                  isDark: isDark,
                  surface: surface,
                  border: border,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),

                const SizedBox(height: 14),

                // 2. Network Access
                _buildPermissionCard(
                  icon: Icons.wifi_rounded,
                  title: 'Internet & Network Access',
                  badgeText: 'System',
                  badgeColor: const Color(0xFF10B981),
                  description:
                      'Allows the app to reach external Fastly MASQUE endpoints and query DNS resolvers.',
                  isGranted: _permissions['network'] == true,
                  onGrant: null, // Always granted by system
                  isDark: isDark,
                  surface: surface,
                  border: border,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),

                const SizedBox(height: 14),

                // 3. Notifications
                _buildPermissionCard(
                  icon: Icons.notifications_active_rounded,
                  title: 'Notifications',
                  badgeText: 'Important',
                  badgeColor: const Color(0xFFF59E0B),
                  description:
                      'Required to display live VPN connection status, speed monitoring, and kill-switch alerts.',
                  isGranted: _permissions['notifications'] == true,
                  onGrant: _grantNotifications,
                  isDark: isDark,
                  surface: surface,
                  border: border,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),

                const SizedBox(height: 14),

                // 4. Nearby Devices
                _buildPermissionCard(
                  icon: Icons.devices_other_rounded,
                  title: 'Nearby Devices',
                  badgeText: 'LAN Sync',
                  badgeColor: const Color(0xFF3B82F6),
                  description:
                      'Allows fast cross-device QR code pairing and discovery with your desktop client.',
                  isGranted: _permissions['nearby'] == true,
                  onGrant: _grantNearby,
                  isDark: isDark,
                  surface: surface,
                  border: border,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),

                const SizedBox(height: 14),

                // 5. Usage Access
                _buildPermissionCard(
                  icon: Icons.data_usage_rounded,
                  title: 'App Usage Access',
                  badgeText: 'Special',
                  badgeColor: const Color(0xFF8B5CF6),
                  description:
                      'Enables app traffic monitoring and selective per-app bypass in Split Tunneling.',
                  isGranted: _permissions['usage_access'] == true,
                  onGrant: _grantUsageAccess,
                  isDark: isDark,
                  surface: surface,
                  border: border,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),

                const SizedBox(height: 14),

                // 6. Camera (QR Scanner)
                _buildPermissionCard(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Camera Access',
                  badgeText: 'QR Only',
                  badgeColor: const Color(0xFF64748B),
                  description:
                      'Camera permission is strictly used when scanning desktop QR codes for instant sign-in.',
                  isGranted: _permissions['camera'] == true,
                  onGrant: _grantCamera,
                  isDark: isDark,
                  surface: surface,
                  border: border,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),

                const SizedBox(height: 32),

                // Bottom App Settings link
                Center(
                  child: TextButton.icon(
                    onPressed: () => AndroidCore.openAppSettings(),
                    icon: const Icon(Icons.settings_outlined, size: 18, color: Color(0xFF8B5CF6)),
                    label: const Text(
                      'Open Android System Settings',
                      style: TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required String description,
    required bool isGranted,
    required VoidCallback? onGrant,
    required bool isDark,
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isGranted
              ? border
              : const Color(0xFF6B42FF).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isGranted
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isGranted ? const Color(0xFF10B981) : badgeColor,
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
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isGranted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                      SizedBox(width: 5),
                      Text(
                        'Allowed',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              else if (onGrant != null)
                ElevatedButton(
                  onPressed: onGrant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B42FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text(
                    'Grant',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'System',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              color: textSecondary,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
