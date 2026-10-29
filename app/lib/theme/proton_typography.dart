import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'proton_colors.dart';

class ProtonTypography {
  ProtonTypography._();

  static TextStyle titleLarge = GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: ProtonColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle titleMedium = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: ProtonColors.textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle headline = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: ProtonColors.textPrimary,
  );

  static TextStyle bodyLarge = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: ProtonColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ProtonColors.textLight,
  );

  static TextStyle bodySmall = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: ProtonColors.textSecondary,
  );

  static TextStyle labelLarge = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: ProtonColors.textPrimary,
  );

  static TextStyle labelSmall = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: ProtonColors.textMuted,
    letterSpacing: 0.2,
  );

  static TextStyle mono = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: ProtonColors.connected,
  );
}
