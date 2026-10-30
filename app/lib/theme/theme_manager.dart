import 'package:flutter/material.dart';
import '../core/app_preferences.dart';
import 'proton_colors.dart';

class ThemeManager extends ChangeNotifier {
  static final ThemeManager instance = ThemeManager._internal();

  ThemeManager._internal() {
    _currentTheme = AppPreferences.selectedTheme;
    _isDarkMode = AppPreferences.isDarkMode;
  }

  late String _currentTheme;
  late bool _isDarkMode;

  String get currentTheme => _currentTheme;
  bool get isLiquidGlass => _currentTheme == 'Proton UI (Liquid Glass)';
  bool get isDarkMode => _isDarkMode;

  void init() {
    _currentTheme = AppPreferences.selectedTheme;
    _isDarkMode = AppPreferences.isDarkMode;
    notifyListeners();
  }

  Future<void> setTheme(String theme) async {
    _currentTheme = theme;
    await AppPreferences.setSelectedTheme(theme);
    notifyListeners();
  }

  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    await AppPreferences.setIsDarkMode(isDark);
    notifyListeners();
  }

  // Adaptive Color System matching reference images
  Color get backgroundColor => _isDarkMode
      ? (isLiquidGlass ? const Color(0xFF0D0C15) : ProtonColors.background)
      : const Color(0xFFF1F3F9);

  Color get surfaceColor => _isDarkMode
      ? (isLiquidGlass
          ? const Color(0xFF1A1728).withValues(alpha: 0.72)
          : ProtonColors.surface)
      : (isLiquidGlass
          ? Colors.white.withValues(alpha: 0.90)
          : Colors.white);

  Color get surfaceDarkColor => _isDarkMode
      ? (isLiquidGlass ? const Color(0xFF151322) : ProtonColors.surfaceDark)
      : (isLiquidGlass ? const Color(0xFFF6F5FA) : const Color(0xFFF3F2F8));

  Color get cardBorderColor => _isDarkMode
      ? (isLiquidGlass
          ? Colors.white.withValues(alpha: 0.08)
          : ProtonColors.cardBorder)
      : (isLiquidGlass
          ? Colors.white.withValues(alpha: 0.95)
          : const Color(0xFFE5E3ED));

  Color get textPrimaryColor => _isDarkMode
      ? Colors.white
      : const Color(0xFF1D1536);

  Color get textSecondaryColor => _isDarkMode
      ? const Color(0xFF8F8C9E)
      : const Color(0xFF757288);

  Color get textMutedColor => _isDarkMode
      ? const Color(0xFF676579)
      : const Color(0xFF8F8C9E);

  Color get dividerColor => _isDarkMode
      ? (isLiquidGlass
          ? Colors.white.withValues(alpha: 0.05)
          : ProtonColors.cardBorder)
      : const Color(0xFFEFEFF6);

  List<BoxShadow> get cardShadow => _isDarkMode
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFF5D5380).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ];
}
