import 'package:flutter/material.dart';
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
    final textPrimary = ThemeManager.instance.textPrimaryColor;
    final textSecondary = ThemeManager.instance.textSecondaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: textSecondary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
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
    final surfaceColor = ThemeManager.instance.surfaceColor;
    final borderColor = ThemeManager.instance.cardBorderColor;
    final textSecondary = ThemeManager.instance.textSecondaryColor;
    final dividerColor = ThemeManager.instance.dividerColor;
    final shadows = ThemeManager.instance.cardShadow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: textSecondary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(isLiquid ? 24 : 16),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            boxShadow: shadows,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: children.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: dividerColor,
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
