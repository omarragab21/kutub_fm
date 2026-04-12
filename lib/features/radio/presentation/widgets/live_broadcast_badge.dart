import 'package:flutter/material.dart';

import '../theme/fm_radio_theme.dart';

/// Pulsing on-air pill with glow (reusable).
class LiveBroadcastBadge extends StatefulWidget {
  const LiveBroadcastBadge({super.key, this.compact = false});

  final bool compact;

  @override
  State<LiveBroadcastBadge> createState() => _LiveBroadcastBadgeState();
}

class _LiveBroadcastBadgeState extends State<LiveBroadcastBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          fontSize: widget.compact ? 9 : 10,
        );

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);
        final glow = 0.45 + t.value * 0.55;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 8 : 12,
            vertical: widget.compact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: [
                FmRadioTheme.liveRed.withValues(alpha: 0.9),
                FmRadioTheme.liveRedDeep,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: FmRadioTheme.liveRed.withValues(alpha: 0.35 * glow),
                blurRadius: 18 * glow,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PulsingDot(scale: 0.85 + t.value * 0.2),
              SizedBox(width: widget.compact ? 5 : 8),
              Text('مباشر', style: textStyle),
            ],
          ),
        );
      },
    );
  }
}

class _PulsingDot extends StatelessWidget {
  const _PulsingDot({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.9),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}
