import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AudioWaveformVisualizer extends StatefulWidget {
  final bool isPlaying;

  const AudioWaveformVisualizer({
    super.key,
    required this.isPlaying,
  });

  @override
  State<AudioWaveformVisualizer> createState() => _AudioWaveformVisualizerState();
}

class _AudioWaveformVisualizerState extends State<AudioWaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  late List<double> _targetHeights;
  late List<double> _currentHeights;
  late List<double> _phaseOffsets;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150), // Faster updates for smoother animation
    )..addListener(() {
        setState(() {});
      });

    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _generateHeights();
    _currentHeights = List.filled(_targetHeights.length, 4.0);
    _generatePhaseOffsets();

    if (widget.isPlaying) {
      _startAnimLoop();
    }
  }

  void _generateHeights() {
    // We draw ~50 bars for more detail
    _targetHeights = List.generate(50, (index) {
      // Create more realistic wave patterns
      final baseHeight = 20.0;
      final variation = _random.nextDouble() * 30 + 10;
      final waveInfluence = sin(index * 0.3) * 10;
      return baseHeight + variation + waveInfluence;
    });
  }

  void _generatePhaseOffsets() {
    _phaseOffsets = List.generate(50, (index) => _random.nextDouble() * 2 * pi);
  }

  void _startAnimLoop() {
    if (!mounted) return;
    
    // Smoothly interpolate current heights to target heights
    for (int i = 0; i < _targetHeights.length; i++) {
      final diff = _targetHeights[i] - _currentHeights[i];
      _currentHeights[i] += diff * 0.3; // Smooth interpolation
    }
    
    // Occasionally generate new target heights for variation
    if (_random.nextDouble() < 0.1) {
      _generateHeights();
    }
    
    _controller.forward(from: 0.0).then((_) {
      if (widget.isPlaying && mounted) {
        _startAnimLoop();
      }
    });
  }

  @override
  void didUpdateWidget(AudioWaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimLoop();
      } else {
        _controller.stop();
        // Gradually return to flat line
        for (int i = 0; i < _currentHeights.length; i++) {
          _currentHeights[i] = 4.0;
        }
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80, // Increased height for better visibility
      width: double.infinity,
      child: ClipRect(
        child: CustomPaint(
          painter: _WaveformPainter(
            heights: _currentHeights,
            phaseOffsets: _phaseOffsets,
            progress: _controller.value,
            gradientProgress: _gradientAnimation.value,
            isPlaying: widget.isPlaying,
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> heights;
  final List<double> phaseOffsets;
  final double progress;
  final double gradientProgress;
  final bool isPlaying;

  _WaveformPainter({
    required this.heights,
    required this.phaseOffsets,
    required this.progress,
    required this.gradientProgress,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (heights.isEmpty) return;

    final spacing = size.width / heights.length;
    final centerY = size.height / 2;

    // Create gradient for the waveform
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        AppTheme.primary,
        const Color(0xFFD4AF37),
        AppTheme.primary,
      ],
      stops: [
        0.0,
        0.5 + sin(gradientProgress * 2 * pi) * 0.2,
        1.0,
      ],
    );

    for (int i = 0; i < heights.length; i++) {
      final x = i * spacing + (spacing / 2);
      
      // Enhanced wave calculation with phase offsets
      double barH;
      if (isPlaying) {
        final waveInfluence = sin(progress * 2 * pi + phaseOffsets[i]) * 0.3;
        final pulseInfluence = sin(progress * 4 * pi + i * 0.1) * 0.2;
        final heightMultiplier = (0.6 + waveInfluence + pulseInfluence).clamp(0.2, 1.0);
        barH = heights[i] * heightMultiplier;
      } else {
        barH = 4.0; // Flat line when paused
      }

      // Draw multiple layers for depth
      _drawWaveBar(canvas, x, centerY, barH, spacing, gradient, i, isPlaying);
    }
  }

  void _drawWaveBar(Canvas canvas, double x, double centerY, double barHeight, 
      double spacing, Gradient gradient, int index, bool isPlaying) {
    
    // Background glow layer
    if (isPlaying) {
      final glowPaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(x - spacing/2, centerY - barHeight/2, spacing, barHeight),
        )
        ..strokeWidth = spacing * 0.8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..color = AppTheme.primary.withOpacity(0.3);
      
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        glowPaint,
      );
    }

    // Main bar with gradient
    final mainPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(x - spacing/2, centerY - barHeight/2, spacing, barHeight),
      )
      ..strokeWidth = spacing * 0.6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(x, centerY - barHeight / 2),
      Offset(x, centerY + barHeight / 2),
      mainPaint,
    );

    // Inner bright core
    if (isPlaying && barHeight > 8) {
      final corePaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..strokeWidth = spacing * 0.2
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(
        Offset(x, centerY - barHeight / 4),
        Offset(x, centerY + barHeight / 4),
        corePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.gradientProgress != gradientProgress || 
           oldDelegate.isPlaying != isPlaying;
  }
}
