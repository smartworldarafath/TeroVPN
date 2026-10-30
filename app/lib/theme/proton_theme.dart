import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'proton_typography.dart';

class ProtonTheme {
  ProtonTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0C0916),
      primaryColor: const Color(0xFF6B42FF),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6B42FF),
        surface: Color(0xFF181427),
        onSurface: Colors.white,
        outline: Color(0xFF2E2A42),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF0C0916),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF181427),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF2E2A42), width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2E2A42),
        thickness: 1,
        space: 1,
      ),
      textTheme: TextTheme(
        headlineLarge: ProtonTypography.titleLarge.copyWith(color: Colors.white),
        headlineMedium: ProtonTypography.titleMedium.copyWith(color: Colors.white),
        titleLarge: ProtonTypography.headline.copyWith(color: Colors.white),
        titleMedium: ProtonTypography.bodyLarge.copyWith(color: Colors.white),
        bodyLarge: ProtonTypography.bodyLarge.copyWith(color: Colors.white),
        bodyMedium: ProtonTypography.bodyMedium.copyWith(color: Colors.white),
        bodySmall: ProtonTypography.bodySmall.copyWith(color: const Color(0xFF8F8C9E)),
        labelLarge: ProtonTypography.labelLarge.copyWith(color: Colors.white),
        labelSmall: ProtonTypography.labelSmall.copyWith(color: const Color(0xFF8F8C9E)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F6FC),
      primaryColor: const Color(0xFF6B42FF),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6B42FF),
        surface: Colors.white,
        onSurface: Color(0xFF1D1536),
        outline: Color(0xFFE5E3ED),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFFF5F6FC),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE5E3ED), width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E3ED),
        thickness: 1,
        space: 1,
      ),
      textTheme: TextTheme(
        headlineLarge: ProtonTypography.titleLarge.copyWith(color: const Color(0xFF1D1536)),
        headlineMedium: ProtonTypography.titleMedium.copyWith(color: const Color(0xFF1D1536)),
        titleLarge: ProtonTypography.headline.copyWith(color: const Color(0xFF1D1536)),
        titleMedium: ProtonTypography.bodyLarge.copyWith(color: const Color(0xFF1D1536)),
        bodyLarge: ProtonTypography.bodyLarge.copyWith(color: const Color(0xFF1D1536)),
        bodyMedium: ProtonTypography.bodyMedium.copyWith(color: const Color(0xFF1D1536)),
        bodySmall: ProtonTypography.bodySmall.copyWith(color: const Color(0xFF757288)),
        labelLarge: ProtonTypography.labelLarge.copyWith(color: const Color(0xFF1D1536)),
        labelSmall: ProtonTypography.labelSmall.copyWith(color: const Color(0xFF757288)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
