import 'package:flutter/material.dart';
import '../core/app_preferences.dart';

class ThemeManager extends ChangeNotifier {
  static final ThemeManager instance = ThemeManager._internal();

  ThemeManager._internal() {
    _currentTheme = AppPreferences.selectedTheme;
    _isDarkMode = AppPreferences.isDarkMode;
  }

  late String _currentTheme;
  late bool _isDarkMode;

  String get currentTheme => _currentTheme;
  // True only when 'Proton UI (Liquid Glass)' is selected; false for classic 'Proton UI'
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

  // Exact Adaptive Color System matching Dark UI and Light UI reference screenshots
  Color get backgroundColor => _isDarkMode
      ? const Color(0xFF0C0916) // Deep Obsidian Violet
      : const Color(0xFFF5F6FC); // Clean serene off-white canvas

  Color get surfaceColor {
    if (!isLiquidGlass) {
      return _isDarkMode ? const Color(0xFF181427) : Colors.white;
    }
    return _isDarkMode
        ? const Color(0xFF1B172B).withValues(alpha: 0.72) // Translucent dark violet frosted glass
        : Colors.white.withValues(alpha: 0.85); // Pure translucent white frosted glass
  }

  Color get surfaceDarkColor => _isDarkMode
      ? const Color(0xFF141122)
      : const Color(0xFFEEEAF7);

  Color get cardBorderColor {
    if (!isLiquidGlass) {
      return _isDarkMode ? const Color(0xFF2E2A42) : const Color(0xFFE5E3ED);
    }
    return _isDarkMode
        ? Colors.white.withValues(alpha: 0.09) // Subtle crisp glass etch
        : Colors.white.withValues(alpha: 0.95); // Luminous white specular rim
  }

  Color get textPrimaryColor => _isDarkMode
      ? Colors.white
      : const Color(0xFF1D1536);

  Color get textSecondaryColor => _isDarkMode
      ? const Color(0xFF8F8C9E)
      : const Color(0xFF6E6B80);

  Color get textMutedColor => _isDarkMode
      ? const Color(0xFF625F72)
      : const Color(0xFF9693A8);

  Color get dividerColor => _isDarkMode
      ? Colors.white.withValues(alpha: 0.06)
      : const Color(0xFF5D5380).withValues(alpha: 0.08);

  // Soft Liquid Glass Elevation Shadows
  List<BoxShadow> get cardShadow {
    if (!isLiquidGlass) {
      return const [];
    }
    return _isDarkMode
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 22,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ]
        : [
            BoxShadow(
              color: const Color(0xFF524577).withValues(alpha: 0.08),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.85),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ];
  }
}
