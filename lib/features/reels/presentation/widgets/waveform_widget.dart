import 'package:flutter/material.dart';

class WaveformWidget extends StatelessWidget {
  final Color color;

  const WaveformWidget({
    super.key,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // A beautiful, deterministic, symmetric voice waveform pattern
    final List<double> heights = [
      8, 12, 10, 16, 22, 18, 26, 32, 28, 38, 
      45, 38, 48, 52, 48, 38, 45, 38, 28, 32, 
      26, 18, 22, 16, 10, 12, 8
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(heights.length, (index) {
        final height = heights[index];
        return Container(
          width: 3,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
