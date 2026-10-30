import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import 'settings_row.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;

        return Scaffold(
          backgroundColor: ThemeManager.instance.backgroundColor,
          appBar: AppBar(
            backgroundColor: ThemeManager.instance.backgroundColor,
            elevation: 0,
            title: Text(
              'About TeroVPN',
              style: ProtonTypography.titleLarge.copyWith(
                fontSize: 22,
                color: ThemeManager.instance.textPrimaryColor,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: ThemeManager.instance.textPrimaryColor),
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
                        color: const Color(0xFF6B42FF),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.5 : 0.25),
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
                      color: ThemeManager.instance.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Version & Copyright
                  Text(
                    'Version 1.0.9',
                    style: ProtonTypography.bodySmall.copyWith(
                      color: ThemeManager.instance.textSecondaryColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© 2026 Tero Security',
                    style: ProtonTypography.bodySmall.copyWith(
                      color: ThemeManager.instance.textMutedColor,
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
                        trailing: Icon(Icons.chevron_right_rounded, color: ThemeManager.instance.textMutedColor),
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
                        trailing: Icon(Icons.chevron_right_rounded, color: ThemeManager.instance.textMutedColor),
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
                        trailing: Icon(Icons.chevron_right_rounded, color: ThemeManager.instance.textMutedColor),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Opening https://terovpn.com...'),
                              backgroundColor: isDark ? ProtonColors.surfaceDark : const Color(0xFF1D1536),
                            ),
                          );
                        },
                      ),
                      SettingsRow(
                        icon: Icons.support_agent_rounded,
                        title: 'Contact Support',
                        subtitle: 'Get help and send feedback',
                        trailing: Icon(Icons.chevron_right_rounded, color: ThemeManager.instance.textMutedColor),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Support email: support@terovpn.com'),
                              backgroundColor: isDark ? ProtonColors.surfaceDark : const Color(0xFF1D1536),
                            ),
                          );
                        },
                      ),
                      SettingsRow(
                        icon: Icons.star_rate_rounded,
                        title: 'Rate Us',
                        subtitle: 'Show your love on the Play Store',
                        trailing: Icon(Icons.chevron_right_rounded, color: ThemeManager.instance.textMutedColor),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Thank you for rating TeroVPN!'),
                              backgroundColor: isDark ? ProtonColors.surfaceDark : const Color(0xFF1D1536),
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
                        trailing: Icon(Icons.chevron_right_rounded, color: ThemeManager.instance.textMutedColor),
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: 'TeroVPN',
                          applicationVersion: '1.0.9',
                        ),
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
  }

  void _showTextDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ThemeManager.instance.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: ThemeManager.instance.cardBorderColor),
        ),
        title: Text(
          title,
          style: ProtonTypography.titleMedium.copyWith(
            color: ThemeManager.instance.textPrimaryColor,
          ),
        ),
        content: Text(
          content,
          style: ProtonTypography.bodyMedium.copyWith(
            color: ThemeManager.instance.textSecondaryColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Color(0xFF6B42FF))),
          ),
        ],
      ),
    );
  }
}
