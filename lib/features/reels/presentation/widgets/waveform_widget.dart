import 'dart:math';
import 'package:flutter/material.dart';

class WaveformWidget extends StatelessWidget {
  final int count;
  final Color color;

  const WaveformWidget({
    super.key,
    this.count = 20,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(count, (index) {
        // Random heights to simulate a waveform for mock purpose
        final height = 10 + Random().nextDouble() * 20;
        return Container(
          width: 3,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
