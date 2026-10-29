import 'package:flutter/foundation.dart';
import '../core/app_preferences.dart';

class ThemeManager extends ChangeNotifier {
  static final ThemeManager instance = ThemeManager._internal();

  ThemeManager._internal() {
    _currentTheme = AppPreferences.selectedTheme;
  }

  late String _currentTheme;

  String get currentTheme => _currentTheme;
  bool get isLiquidGlass => _currentTheme == 'Proton UI (Liquid Glass)';

  Future<void> setTheme(String theme) async {
    if (_currentTheme == theme) return;
    _currentTheme = theme;
    await AppPreferences.setSelectedTheme(theme);
    notifyListeners();
  }
}
