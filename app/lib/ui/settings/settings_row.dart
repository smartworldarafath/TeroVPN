import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: ProtonColors.textSecondary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ProtonTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: ProtonTypography.bodySmall.copyWith(
                          color: ProtonColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing case final Widget t) t,
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isLiquid = ThemeManager.instance.isLiquidGlass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: ProtonTypography.labelSmall.copyWith(
              color: ProtonColors.textSecondary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isLiquid
                ? const Color(0xFF1E1B2E).withValues(alpha: 0.65)
                : ProtonColors.surface,
            borderRadius: BorderRadius.circular(isLiquid ? 20 : 16),
            border: Border.all(
              color: isLiquid ? Colors.white.withValues(alpha: 0.10) : ProtonColors.cardBorder,
              width: 1,
            ),
            boxShadow: isLiquid
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: children.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: isLiquid ? Colors.white.withValues(alpha: 0.07) : ProtonColors.cardBorder,
              indent: 56,
            ),
            itemBuilder: (_, index) => children[index],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
