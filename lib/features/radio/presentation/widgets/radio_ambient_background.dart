import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/fm_radio_theme.dart';

/// Layered gradients and soft orbs for a premium broadcast backdrop.
class RadioAmbientBackground extends StatelessWidget {
  const RadioAmbientBackground({
    super.key,
    required this.accentArgb,
    this.child = const SizedBox.shrink(),
  });

  final int accentArgb;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final accent = Color(accentArgb);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: FmRadioTheme.stationGradient(accentArgb),
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -40,
          child: _BlurOrb(
            diameter: 280,
            color: accent.withValues(alpha: 0.35),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -60,
          child: _BlurOrb(
            diameter: 320,
            color: FmRadioTheme.auroraViolet.withValues(alpha: 0.28),
          ),
        ),
        Positioned(
          top: 180,
          left: 40,
          child: _BlurOrb(
            diameter: 180,
            color: FmRadioTheme.auroraMagenta.withValues(alpha: 0.15),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({
    required this.diameter,
    required this.color,
  });

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 64, sigmaY: 64),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
