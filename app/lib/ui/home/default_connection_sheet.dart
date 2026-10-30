import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/app_preferences.dart';
import '../../core/core_controller.dart';
import '../../theme/theme_manager.dart';
import '../components/country_flag.dart';
import '../components/top_dock_toast.dart';
import '../countries/country_manager.dart';

class DefaultConnectionSheet extends StatefulWidget {
  final CoreController controller;
  final ValueChanged<String> onSelected;

  const DefaultConnectionSheet({
    super.key,
    required this.controller,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required CoreController controller,
    required ValueChanged<String> onSelected,
  }) {
    final isDark = ThemeManager.instance.isDarkMode;
    final isLiquid = ThemeManager.instance.isLiquidGlass;

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final content = DefaultConnectionSheet(
          controller: controller,
          onSelected: onSelected,
        );

        if (isLiquid) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF161324).withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.90),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.95),
                      width: 1.2,
                    ),
                  ),
                ),
                child: content,
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF181526) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF2E2A42) : const Color(0xFFE5E3ED),
                width: 1,
              ),
            ),
          ),
          child: content,
        );
      },
    );
  }

  @override
  State<DefaultConnectionSheet> createState() => _DefaultConnectionSheetState();
}

class _DefaultConnectionSheetState extends State<DefaultConnectionSheet> {
  late String _currentType;

  @override
  void initState() {
    super.initState();
    _currentType = AppPreferences.defaultConnectionType;
  }

  void _select(String type) async {
    setState(() => _currentType = type);
    await AppPreferences.setDefaultConnectionType(type);

    if (type == 'fastest') {
      final fastest = CountryManager.instance.getFastestCountry();
      await AppPreferences.setSelectedLocation(fastest.code);
      await widget.controller.setLocation(fastest.code.toLowerCase());
      if (widget.controller.hasAccount) {
        if (widget.controller.isConnected) {
          widget.controller.setOn(false);
          Future.delayed(const Duration(milliseconds: 250), () {
            widget.controller.setLocation(fastest.code.toLowerCase());
            widget.controller.setOn(true);
          });
        } else {
          widget.controller.setOn(true);
        }
      }
      widget.onSelected('fastest');
      if (mounted) {
        TopDockToast.show(
          context,
          title: 'Connected to Fastest Country',
          message: '${fastest.name} · ${fastest.pingMs} ms (Load: ${fastest.load}%)',
          icon: Icons.bolt_rounded,
          iconColor: const Color(0xFF00E676),
        );
      }
    } else if (type == 'last') {
      final last = AppPreferences.lastConnection;
      await AppPreferences.setSelectedLocation(last);
      await widget.controller.setLocation(last.toLowerCase());
      if (widget.controller.hasAccount && !widget.controller.isConnected) {
        widget.controller.setOn(true);
      }
      widget.onSelected(last);
      if (mounted) {
        TopDockToast.show(
          context,
          title: 'Selected Last Connection',
          message: 'Server: $last',
          icon: Icons.history_rounded,
        );
      }
    } else {
      await AppPreferences.setSelectedLocation(type);
      await widget.controller.setLocation(type.toLowerCase());
      if (widget.controller.hasAccount && !widget.controller.isConnected) {
        widget.controller.setOn(true);
      }
      widget.onSelected(type);
      if (mounted) {
        TopDockToast.show(
          context,
          title: 'Default Location Set',
          message: 'Connecting to $type',
          icon: Icons.location_on_rounded,
        );
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.instance.isDarkMode;
    final textPrimary = ThemeManager.instance.textPrimaryColor;
    final textSecondary = ThemeManager.instance.textSecondaryColor;

    final recentCodes = AppPreferences.recentLocations;
    final dynamicCountries = CountryManager.instance.countries;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFD8D5E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Sheet Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Select your default connection',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Option 1: Fastest Country
            _buildOption(
              icon: Icons.bolt_rounded,
              iconColor: isDark ? const Color(0xFF1FE5BD) : const Color(0xFF00A36C),
              iconBg: isDark ? const Color(0xFF133226) : const Color(0xFFD8F5EB),
              title: 'Fastest country',
              subtitle: 'The best server based on your location',
              isSelected: _currentType == 'fastest',
              onTap: () => _select('fastest'),
            ),

            // Option 2: Last connection
            _buildOption(
              icon: Icons.history_rounded,
              iconColor: const Color(0xFF6B42FF),
              iconBg: isDark ? const Color(0xFF261D42) : const Color(0xFFF0EDFA),
              title: 'Last connection',
              subtitle: 'Your most recently used connection',
              isSelected: _currentType == 'last',
              onTap: () => _select('last'),
            ),

            // Recents Section
            if (recentCodes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Text(
                  'Recents',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
              ),
              ...recentCodes.map((code) {
                final match = dynamicCountries.firstWhere(
                  (c) => c.code.toUpperCase() == code.toUpperCase(),
                  orElse: () => DynamicCountry(code: code, name: code, cities: '', load: 30, pingMs: 25),
                );
                return _buildCountryOption(
                  code: match.code,
                  name: match.name,
                  subtitle: match.cities.isNotEmpty ? match.cities.split(',').first : null,
                  isSelected: _currentType.toUpperCase() == code.toUpperCase(),
                  onTap: () => _select(code),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final textPrimary = ThemeManager.instance.textPrimaryColor;
    final textSecondary = ThemeManager.instance.textSecondaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 20),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildRadio(isSelected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryOption({
    required String code,
    required String name,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final textPrimary = ThemeManager.instance.textPrimaryColor;
    final textSecondary = ThemeManager.instance.textSecondaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
          child: Row(
            children: [
              CountryFlag(
                countryCode: code,
                width: 34,
                height: 24,
                borderRadius: 4,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildRadio(isSelected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadio(bool isSelected) {
    final isDark = ThemeManager.instance.isDarkMode;

    if (isSelected) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: Color(0xFF6B42FF),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.check, size: 14, color: Colors.white),
        ),
      );
    }

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? const Color(0xFF4B4762) : const Color(0xFFC7C5D6),
          width: 2,
        ),
      ),
    );
  }
}
