import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'proton_colors.dart';
import 'proton_typography.dart';

class ProtonTheme {
  ProtonTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ProtonColors.background,
      primaryColor: ProtonColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: ProtonColors.primary,
        surface: ProtonColors.surface,
        onSurface: ProtonColors.textPrimary,
        outline: ProtonColors.cardBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: ProtonColors.surfaceDark,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: ProtonColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ProtonColors.cardBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ProtonColors.cardBorder,
        thickness: 1,
        space: 1,
      ),
      textTheme: TextTheme(
        headlineLarge: ProtonTypography.titleLarge,
        headlineMedium: ProtonTypography.titleMedium,
        titleLarge: ProtonTypography.headline,
        titleMedium: ProtonTypography.bodyLarge,
        bodyLarge: ProtonTypography.bodyLarge,
        bodyMedium: ProtonTypography.bodyMedium,
        bodySmall: ProtonTypography.bodySmall,
        labelLarge: ProtonTypography.labelLarge,
        labelSmall: ProtonTypography.labelSmall,
      ),
    );
  }
}
