import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../core/app_preferences.dart';
import '../../core/android_core.dart';
import 'settings_row.dart';

class AppUpdateScreen extends StatefulWidget {
  const AppUpdateScreen({super.key});

  @override
  State<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends State<AppUpdateScreen> {
  late bool _autoUpdateWifi;
  late bool _allowUpdateMobile;
  late bool _notifyUpdates;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _autoUpdateWifi = AppPreferences.autoUpdateWifi;
    _allowUpdateMobile = AppPreferences.allowUpdateMobile;
    _notifyUpdates = AppPreferences.notifyUpdates;
  }

  void _showBetaDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProtonColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: ProtonColors.cardBorder),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6D4AFF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.science_outlined,
                color: Color(0xFF6D4AFF),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Join Beta Program',
              style: ProtonTypography.titleMedium.copyWith(fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'This feature is currently under development and will be available very soon.',
          style: ProtonTypography.bodyMedium.copyWith(
            color: ProtonColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6D4AFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProtonColors.background,
      appBar: AppBar(
        title: Text(
          'App Update',
          style: ProtonTypography.titleLarge.copyWith(fontSize: 22),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ProtonColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background Atmospheric Glow
          Positioned(
            top: -40,
            left: 0,
            right: 0,
            height: 280,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.4),
                    radius: 1.0,
                    colors: [
                      const Color(0xFFDC3251).withValues(alpha: 0.15),
                      const Color(0xFF6D4AFF).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Update Available Card
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        // Shield with diagonal arrow
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFF573BC7),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6D4AFF).withValues(alpha: 0.5),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.shield_rounded,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                            ),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF6D4AFF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.arrow_outward_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Update Available!',
                                style: ProtonTypography.titleMedium.copyWith(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Version 1.0.6 (99.2 MB)',
                                style: ProtonTypography.bodySmall.copyWith(
                                  color: ProtonColors.textLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Your current version: 1.0.5',
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
                  const SizedBox(height: 12),

                  // Download & Install Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isDownloading
                          ? null
                          : () async {
                              setState(() => _isDownloading = true);
                              await Future.delayed(const Duration(seconds: 2));
                              if (context.mounted) {
                                setState(() => _isDownloading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Downloading TeroVPN v1.0.5 APK...'),
                                    backgroundColor: ProtonColors.surfaceDark,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6D4AFF),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isDownloading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Download & Install',
                              style: ProtonTypography.labelLarge.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // WHAT'S NEW Section
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      "WHAT'S NEW",
                      style: ProtonTypography.labelSmall.copyWith(
                        color: ProtonColors.textSecondary,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: ProtonColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ProtonColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBulletPoint('Added WireGuard MASQUE (HTTP/3) support'),
                        _buildBulletPoint('NetShield engine upgrades for better ad-blocking'),
                        _buildBulletPoint('Improved reconnection speed after connection drops'),
                        _buildBulletPoint('Fixed crash issues on older Android versions'),
                        _buildBulletPoint('Performance improvements & bug fixes'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // PREFERENCES & SETTINGS Section
                  SettingsSectionCard(
                    title: 'PREFERENCES & SETTINGS',
                    children: [
                      SettingsRow(
                        icon: Icons.wifi_rounded,
                        title: 'Auto-update over Wi-Fi',
                        subtitle: 'Automatically download package on Wi-Fi',
                        trailing: Switch(
                          value: _autoUpdateWifi,
                          activeThumbColor: const Color(0xFF6D4AFF),
                          onChanged: (val) {
                            setState(() => _autoUpdateWifi = val);
                            AppPreferences.setAutoUpdateWifi(val);
                          },
                        ),
                      ),
                      SettingsRow(
                        icon: Icons.signal_cellular_alt_rounded,
                        title: 'Allow updates over mobile data',
                        subtitle: 'Download updates using cellular network',
                        trailing: Switch(
                          value: _allowUpdateMobile,
                          activeThumbColor: const Color(0xFF6D4AFF),
                          onChanged: (val) {
                            setState(() => _allowUpdateMobile = val);
                            AppPreferences.setAllowUpdateMobile(val);
                          },
                        ),
                      ),
                      SettingsRow(
                        icon: Icons.notifications_active_outlined,
                        title: 'Notify me when updates are available',
                        subtitle: 'Push alert for critical security releases',
                        trailing: Switch(
                          value: _notifyUpdates,
                          activeThumbColor: const Color(0xFF6D4AFF),
                          onChanged: (val) {
                            setState(() => _notifyUpdates = val);
                            AppPreferences.setNotifyUpdates(val);
                            if (val) {
                              AndroidCore.askNotifications();
                            }
                          },
                        ),
                      ),
                      SettingsRow(
                        icon: Icons.science_outlined,
                        title: 'Join Beta Program',
                        subtitle: 'Try preview features & early builds',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6D4AFF).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF6D4AFF).withValues(alpha: 0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: const Text(
                                'BETA',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF6D4AFF),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: ProtonColors.textMuted,
                              size: 20,
                            ),
                          ],
                        ),
                        onTap: _showBetaDialog,
                      ),
                    ],
                  ),

                  // ABOUT UPDATE Section
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'ABOUT UPDATE',
                      style: ProtonTypography.labelSmall.copyWith(
                        color: ProtonColors.textSecondary,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: ProtonColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ProtonColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last checked: Just now',
                          style: ProtonTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Release date: October 2026',
                          style: ProtonTypography.bodySmall.copyWith(
                            color: ProtonColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: ProtonColors.textLight, fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: ProtonTypography.bodyMedium.copyWith(
                color: ProtonColors.textLight,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
