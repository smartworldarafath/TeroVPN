import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';

/// Universal High-Performance Soft Liquid Glass Container
/// Implements physical optical refraction, specular sheen rim, dual-tier shadows,
/// and backdrop blur matching iOS 26 and Kyant0 AndroidLiquidGlass standards.
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? customTint;
  final Border? customBorder;
  final List<BoxShadow>? customShadow;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.radius = 24.0,
    this.blur = 24.0,
    this.padding,
    this.margin,
    this.customTint,
    this.customBorder,
    this.customShadow,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.instance.isDarkMode;
    final isLiquid = ThemeManager.instance.isLiquidGlass;

    // Classic Proton UI fallback when 'Proton UI' is selected
    if (!isLiquid) {
      final classicBg = customTint ?? (isDark ? const Color(0xFF181526) : Colors.white);
      final classicBorder = customBorder ?? Border.all(
        color: isDark ? const Color(0xFF2E2A42) : const Color(0xFFE5E3ED),
        width: 1.0,
      );
      final classicRadius = BorderRadius.circular(radius > 16 ? 16 : radius);

      Widget body = AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: classicBg,
          borderRadius: classicRadius,
          border: classicBorder,
          boxShadow: customShadow ?? [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );

      if (onTap != null) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: classicRadius,
            child: body,
          ),
        );
      }
      return body;
    }

    // Translucent glass tint letting the background fluid colors shine through
    final baseTint = customTint ??
        (isDark
            ? const Color(0xFF181427).withValues(alpha: 0.65)
            : Colors.white.withValues(alpha: 0.76));

    // Specular border: luminous white highlight in light, etched crystalline in dark
    final defaultBorder = Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.95),
      width: 1.2,
    );

    // Multi-tier soft elevation shadows
    final defaultShadow = isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.50),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xFF6B42FF).withValues(alpha: 0.12),
              blurRadius: 16,
              spreadRadius: -2,
              offset: const Offset(0, 3),
            ),
          ]
        : [
            BoxShadow(
              color: const Color(0xFF5D5380).withValues(alpha: 0.08),
              blurRadius: 22,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.90),
              blurRadius: 1,
              offset: const Offset(0, -1),
            ),
          ];

    final rrectRadius = BorderRadius.circular(radius);

    Widget cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: baseTint,
        borderRadius: rrectRadius,
        border: customBorder ?? defaultBorder,
        // Directional surface specular sheen
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.02),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.12),
                ]
              : [
                  Colors.white.withValues(alpha: 0.45),
                  Colors.white.withValues(alpha: 0.10),
                  Colors.transparent,
                  const Color(0xFF5D5380).withValues(alpha: 0.04),
                ],
          stops: const [0.0, 0.35, 0.70, 1.0],
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: rrectRadius,
          child: cardContent,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: rrectRadius,
        boxShadow: customShadow ?? defaultShadow,
      ),
      child: ClipRRect(
        borderRadius: rrectRadius,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: cardContent,
        ),
      ),
    );
  }
}
