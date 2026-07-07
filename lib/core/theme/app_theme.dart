import 'package:flutter/material.dart';

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
    final baseTheme = ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'ThmanyahSans',
    );
    return baseTheme.copyWith(
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
      textTheme: baseTheme.textTheme.copyWith(
        displayLarge: baseTheme.textTheme.displayLarge?.copyWith(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: primary,
          height: 1.2,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final baseTheme = ThemeData(
      brightness: Brightness.light,
      fontFamily: 'ThmanyahSans',
    );
    return baseTheme.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF9F9F9),
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryContainer,
        onPrimary: onPrimary,
        background: const Color(0xFFF9F9F9),
        surface: Colors.white,
        onSurface: const Color(0xFF131313),
        onSurfaceVariant: const Color(0xFF757575),
      ),
    );
  }
}
