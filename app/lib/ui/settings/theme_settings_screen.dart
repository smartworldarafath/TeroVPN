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
        final isLiquid = ThemeManager.instance.isLiquidGlass;

        return Scaffold(
          backgroundColor: isLiquid ? const Color(0xFF0B0A13) : ProtonColors.background,
          appBar: AppBar(
            title: Text(
              'Theme',
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
                Text(
                  'SELECT APP THEME',
                  style: ProtonTypography.labelSmall.copyWith(
                    color: ProtonColors.textSecondary,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                // 1. Proton UI (Default)
                _buildThemeCard(
                  title: 'Proton UI',
                  badge: 'DEFAULT',
                  description: 'Classic official Proton VPN dark mode with deep obsidian contrast and subtle card borders.',
                  icon: Icons.dark_mode_rounded,
                  isSelected: currentTheme == 'Proton UI',
                  onTap: () async {
                    await ThemeManager.instance.setTheme('Proton UI');
                  },
                ),
                const SizedBox(height: 14),

                // 2. Proton UI (Liquid Glass)
                _buildThemeCard(
                  title: 'Proton UI (Liquid Glass)',
                  badge: 'PREMIUM',
                  description: 'Next-gen frosted liquid glass materials, translucent depth, floating capsule dock, and ambient cosmic glow.',
                  icon: Icons.blur_on_rounded,
                  isSelected: currentTheme == 'Proton UI (Liquid Glass)',
                  onTap: () async {
                    await ThemeManager.instance.setTheme('Proton UI (Liquid Glass)');
                  },
                ),
              ],
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
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: ThemeManager.instance.isLiquidGlass
                ? const Color(0xFF1E1B2E).withValues(alpha: 0.65)
                : ProtonColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6D4AFF)
                  : (ThemeManager.instance.isLiquidGlass ? Colors.white.withValues(alpha: 0.09) : ProtonColors.cardBorder),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFF6D4AFF).withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6D4AFF).withValues(alpha: 0.2)
                      : ProtonColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isSelected ? const Color(0xFF8B6CFF) : ProtonColors.textSecondary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: ProtonTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6D4AFF).withValues(alpha: 0.2)
                                : ProtonColors.surfaceDark,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF6D4AFF).withValues(alpha: 0.5)
                                  : ProtonColors.cardBorder,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: isSelected ? const Color(0xFF8B6CFF) : ProtonColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: ProtonTypography.bodySmall.copyWith(
                        color: ProtonColors.textMuted,
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
                  color: isSelected ? const Color(0xFF6D4AFF) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6D4AFF) : ProtonColors.textMuted,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
