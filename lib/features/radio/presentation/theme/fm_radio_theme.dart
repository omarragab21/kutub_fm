import 'package:flutter/material.dart';

/// Feature-local palette (Spotify Live / Apple Music Radio inspired).
abstract final class FmRadioTheme {
  static const Color deepSpace = Color(0xFF0A0A0F);
  static const Color auroraViolet = Color(0xFF6D28D9);
  static const Color auroraMagenta = Color(0xFFDB2777);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color liveRed = Color(0xFFFF4D4D);
  static const Color liveRedDeep = Color(0xFFB91C1C);

  static List<Color> stationGradient(int accentArgb) {
    final accent = Color(accentArgb);
    return [
      deepSpace,
      Color.lerp(deepSpace, accent, 0.12)!,
      Color.lerp(deepSpace, auroraViolet, 0.18)!,
    ];
  }
}
