import '../components/liquid_glass_card.dart';
import '../components/liquid_glass_atmosphere.dart';
import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final currentTheme = ThemeManager.instance.currentTheme;
        final isDark = ThemeManager.instance.isDarkMode;
        final isLiquid = ThemeManager.instance.isLiquidGlass;

                final textColor = ThemeManager.instance.textPrimaryColor;
        final secondaryColor = ThemeManager.instance.textSecondaryColor;

        return LiquidGlassAtmosphere(
          child: Scaffold(
            backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Theme & Appearance',
              style: ProtonTypography.titleLarge.copyWith(
                fontSize: 20,
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // 1. SELECT APP THEME
                Text(
                  'SELECT APP THEME',
                  style: TextStyle(
                    color: secondaryColor,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),

                // Proton UI (Default)
                _buildThemeCard(
                  title: 'Proton UI',
                  badge: 'DEFAULT',
                  description: 'Classic official Proton VPN layout with clean borders and contrast.',
                  icon: Icons.shield_outlined,
                  isSelected: currentTheme == 'Proton UI',
                  isDark: isDark,
                  isLiquid: isLiquid,
                  onTap: () async {
                    await ThemeManager.instance.setTheme('Proton UI');
                  },
                ),
                const SizedBox(height: 14),

                // Proton UI (Liquid Glass)
                _buildThemeCard(
                  title: 'Proton UI (Liquid Glass)',
                  badge: 'PREMIUM',
                  description: 'Next-gen frosted liquid glass materials, translucent depth, floating capsule dock, and ambient glow.',
                  icon: Icons.blur_on_rounded,
                  isSelected: currentTheme == 'Proton UI (Liquid Glass)',
                  isDark: isDark,
                  isLiquid: isLiquid,
                  onTap: () async {
                    await ThemeManager.instance.setTheme('Proton UI (Liquid Glass)');
                  },
                ),

                const SizedBox(height: 32),

                // 2. APPEARANCE MODE (DARK / LIGHT)
                Text(
                  'APPEARANCE MODE',
                  style: TextStyle(
                    color: secondaryColor,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),

                // Dark Mode Card
                _buildModeCard(
                  title: 'Dark Mode',
                  subtitle: 'Deep obsidian contrast with cosmic neon atmosphere',
                  icon: Icons.dark_mode_rounded,
                  isSelected: isDark,
                  isDark: isDark,
                  isLiquid: isLiquid,
                  onTap: () async {
                    await ThemeManager.instance.setDarkMode(true);
                  },
                ),
                const SizedBox(height: 14),

                // Light Mode Card
                _buildModeCard(
                  title: 'Light Mode',
                  subtitle: 'Iridescent frosted pastel glass with bright lavender ambience',
                  icon: Icons.light_mode_rounded,
                  isSelected: !isDark,
                  isDark: isDark,
                  isLiquid: isLiquid,
                  onTap: () async {
                    await ThemeManager.instance.setDarkMode(false);
                  },
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _buildThemeCard({
    required String title,
    required String badge,
    required String description,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required bool isLiquid,
    required VoidCallback onTap,
  }) {

    final titleColor = isDark ? Colors.white : const Color(0xFF1D1536);
    final descColor = isDark ? ProtonColors.textMuted : const Color(0xFF757288);

    return LiquidGlassCard(
      radius: 20,
      padding: const EdgeInsets.all(18),
      customBorder: isSelected
          ? Border.all(color: const Color(0xFF6B42FF), width: 1.6)
          : null,
      customShadow: isSelected
          ? [
              BoxShadow(
                color: const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.35 : 0.25),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ]
          : null,
      onTap: onTap,
      child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6D4AFF).withValues(alpha: isDark ? 0.2 : 0.12)
                      : (isDark ? ProtonColors.surfaceDark : const Color(0xFFF3F2F8)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isSelected ? const Color(0xFF6B42FF) : (isDark ? ProtonColors.textSecondary : const Color(0xFF757288)),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Flexible title + badge to completely prevent ANY right overflow
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: titleColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6D4AFF).withValues(alpha: isDark ? 0.2 : 0.12)
                                : (isDark ? ProtonColors.surfaceDark : const Color(0xFFF0EDFA)),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF6D4AFF).withValues(alpha: 0.5)
                                  : (isDark ? ProtonColors.cardBorder : const Color(0xFFE5E3ED)),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: isSelected ? const Color(0xFF6B42FF) : (isDark ? ProtonColors.textMuted : const Color(0xFF757288)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        color: descColor,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF6B42FF) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6B42FF) : (isDark ? ProtonColors.textMuted : const Color(0xFFD8D5E5)),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required bool isLiquid,
    required VoidCallback onTap,
  }) {

    final titleColor = isDark ? Colors.white : const Color(0xFF1D1536);
    final descColor = isDark ? ProtonColors.textMuted : const Color(0xFF757288);

    return LiquidGlassCard(
      radius: 20,
      padding: const EdgeInsets.all(18),
      customBorder: isSelected
          ? Border.all(color: const Color(0xFF6B42FF), width: 1.6)
          : null,
      customShadow: isSelected
          ? [
              BoxShadow(
                color: const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.35 : 0.25),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ]
          : null,
      onTap: onTap,
      child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6D4AFF).withValues(alpha: isDark ? 0.2 : 0.12)
                      : (isDark ? ProtonColors.surfaceDark : const Color(0xFFF3F2F8)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isSelected ? const Color(0xFF6B42FF) : (isDark ? ProtonColors.textSecondary : const Color(0xFF757288)),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: descColor,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF6B42FF) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6B42FF) : (isDark ? ProtonColors.textMuted : const Color(0xFFD8D5E5)),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
    );
  }
}
