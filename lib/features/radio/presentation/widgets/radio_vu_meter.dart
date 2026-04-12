import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/fm_radio_theme.dart';

/// Lightweight faux spectrum animation for radio-style chrome.
class RadioVuMeter extends StatefulWidget {
  const RadioVuMeter({
    super.key,
    required this.accentArgb,
    this.barCount = 28,
  });

  final int accentArgb;
  final int barCount;

  @override
  State<RadioVuMeter> createState() => _RadioVuMeterState();
}

class _RadioVuMeterState extends State<RadioVuMeter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Color(widget.accentArgb);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value * math.pi * 2;
        return SizedBox(
          height: 44,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.barCount, (i) {
              final phase = t + i * 0.35;
              final norm = (math.sin(phase) * 0.5 + 0.5).clamp(0.15, 1.0);
              final h = 8.0 + norm * 32;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  width: 3,
                  height: h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        accent.withValues(alpha: 0.25),
                        accent.withValues(alpha: 0.95),
                        Colors.white.withValues(alpha: 0.35),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: FmRadioTheme.liveRed.withValues(alpha: 0.12),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
