import 'package:flutter/material.dart';

import '../theme/fm_radio_theme.dart';

/// Play / pause + mute controls styled for live radio
class RadioTransportControls extends StatelessWidget {
  const RadioTransportControls({
    super.key,
    required this.playing,
    required this.loading,
    required this.isMuted,
    required this.onToggleMute,
    required this.onPlayPause,
    required this.onStop,
  });

  final bool playing;
  final bool loading;
  final bool isMuted;
  final VoidCallback onToggleMute;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleGlassButton(
          diameter: 52,
          onPressed: onToggleMute,
          child: Icon(
            isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 28),
        _PlayPauseOrb(
          playing: playing,
          loading: loading,
          onPressed: onPlayPause,
        ),
        const SizedBox(width: 28),
        _CircleGlassButton(
          diameter: 52,
          onPressed: onStop,
          child: Icon(
            Icons.stop_rounded,
            color: theme.colorScheme.onSurfaceVariant,
            size: 26,
          ),
        ),
      ],
    );
  }
}

class _PlayPauseOrb extends StatefulWidget {
  const _PlayPauseOrb({
    required this.playing,
    required this.loading,
    required this.onPressed,
  });

  final bool playing;
  final bool loading;
  final VoidCallback onPressed;

  @override
  State<_PlayPauseOrb> createState() => _PlayPauseOrbState();
}

class _PlayPauseOrbState extends State<_PlayPauseOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.94,
      upperBound: 1.0,
    )..value = 1.0;
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    await _scale.reverse();
    widget.onPressed();
    if (mounted) await _scale.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF2CA50),
              const Color(0xFFD4AF37),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF2CA50).withValues(alpha: 0.45),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _tap,
            child: SizedBox(
              width: 76,
              height: 76,
              child: Center(
                child: widget.loading && !widget.playing
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF3C2F00),
                        ),
                      )
                    : Icon(
                        widget.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 40,
                        color: const Color(0xFF3C2F00),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleGlassButton extends StatelessWidget {
  const _CircleGlassButton({
    required this.diameter,
    required this.onPressed,
    required this.child,
  });

  final double diameter;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Ink(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: FmRadioTheme.glassBorder),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
