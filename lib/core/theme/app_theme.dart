import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFFF2CA50);
  static const Color primaryContainer = Color(0xFFD4AF37);
  static const Color primaryFixedDim = Color(0xFFE9C349);
  static const Color onPrimary = Color(0xFF3C2F00);
  
  static const Color background = Color(0xFF131313);
  static const Color surface = Color(0xFF131313);
  static const Color surfaceContainerHighest = Color(0xFF353534);
  
  static const Color onSurface = Color(0xFFE5E2E1);
  static const Color onSurfaceVariant = Color(0xD0D0C5AF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        primaryContainer: primaryContainer,
        onPrimary: onPrimary,
        background: background,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        surfaceContainerHighest: surfaceContainerHighest,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.amiri(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: primary,
          height: 1.2,
        ),
        bodyLarge: GoogleFonts.manrope(
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.manrope(
          color: onSurfaceVariant,
        ),
        labelSmall: GoogleFonts.manrope(
          color: onSurfaceVariant,
        ),
      ),
    );
  }
}
