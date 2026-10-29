import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import 'settings_row.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLiquid = ThemeManager.instance.isLiquidGlass;

    return Scaffold(
      backgroundColor: isLiquid ? const Color(0xFF0B0A13) : ProtonColors.background,
      appBar: AppBar(
        title: Text(
          'About TeroVPN',
          style: ProtonTypography.titleLarge.copyWith(fontSize: 22),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ProtonColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Glowing Shield Logo
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B4BFF),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7E5DFF).withValues(alpha: 0.5),
                        blurRadius: 36,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shield_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Brand Name
              Text(
                'TeroVPN',
                style: ProtonTypography.titleLarge.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),

              // Version & Copyright
              Text(
                'Version 1.0.8',
                style: ProtonTypography.bodySmall.copyWith(
                  color: ProtonColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '© 2026 Tero Security',
                style: ProtonTypography.bodySmall.copyWith(
                  color: ProtonColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 32),

              // LEGAL & PRIVACY Section
              SettingsSectionCard(
                title: 'LEGAL & PRIVACY',
                children: [
                  SettingsRow(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'Our commitment to your privacy',
                    trailing: const Icon(Icons.chevron_right_rounded, color: ProtonColors.textMuted),
                    onTap: () => _showTextDialog(
                      context,
                      'Privacy Policy',
                      'TeroVPN enforces a strict zero-logs policy. None of your browsing activities, DNS queries, or originating IP addresses are stored or monitored.',
                    ),
                  ),
                  SettingsRow(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    subtitle: 'Rules and guidelines for using the app',
                    trailing: const Icon(Icons.chevron_right_rounded, color: ProtonColors.textMuted),
                    onTap: () => _showTextDialog(
                      context,
                      'Terms of Service',
                      'By using TeroVPN, you agree to respect local and international network regulations while enjoying encrypted, secure communications.',
                    ),
                  ),
                ],
              ),

              // SUPPORT & LINKS Section
              SettingsSectionCard(
                title: 'SUPPORT & LINKS',
                children: [
                  SettingsRow(
                    icon: Icons.language_rounded,
                    title: 'Website',
                    subtitle: 'visit terovpn.com',
                    trailing: const Icon(Icons.chevron_right_rounded, color: ProtonColors.textMuted),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opening https://terovpn.com...'),
                          backgroundColor: ProtonColors.surfaceDark,
                        ),
                      );
                    },
                  ),
                  SettingsRow(
                    icon: Icons.support_agent_rounded,
                    title: 'Contact Support',
                    subtitle: 'Get help and send feedback',
                    trailing: const Icon(Icons.chevron_right_rounded, color: ProtonColors.textMuted),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Support email: support@terovpn.com'),
                          backgroundColor: ProtonColors.surfaceDark,
                        ),
                      );
                    },
                  ),
                  SettingsRow(
                    icon: Icons.star_rate_rounded,
                    title: 'Rate Us',
                    subtitle: 'Show your love on the Play Store',
                    trailing: const Icon(Icons.chevron_right_rounded, color: ProtonColors.textMuted),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thank you for rating TeroVPN!'),
                          backgroundColor: ProtonColors.surfaceDark,
                        ),
                      );
                    },
                  ),
                ],
              ),

              // ACKNOWLEDGEMENTS Section
              SettingsSectionCard(
                title: 'ACKNOWLEDGEMENTS',
                children: [
                  SettingsRow(
                    icon: Icons.code_rounded,
                    title: 'Open Source Licenses',
                    subtitle: 'Third-party software we use',
                    trailing: const Icon(Icons.chevron_right_rounded, color: ProtonColors.textMuted),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'TeroVPN',
                      applicationVersion: '1.0.5',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTextDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ProtonColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: ProtonTypography.titleMedium),
        content: Text(content, style: ProtonTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: ProtonColors.primary)),
          ),
        ],
      ),
    );
  }
}
