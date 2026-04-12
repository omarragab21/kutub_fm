import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/audio/audio_provider.dart';
import '../../domain/fm_station.dart';
import '../theme/fm_radio_theme.dart';
import '../widgets/fm_station_artwork.dart';
import '../widgets/live_broadcast_badge.dart';
import '../widgets/radio_ambient_background.dart';
import '../widgets/radio_transport_controls.dart';
import '../widgets/radio_vu_meter.dart';
import '../provider/fm_radio_provider.dart';

/// Full-screen live station view with radio-style controls.
class FmStationDetailScreen extends StatefulWidget {
  const FmStationDetailScreen({super.key, required this.station});

  final FmStation station;

  @override
  State<FmStationDetailScreen> createState() => _FmStationDetailScreenState();
}

class _FmStationDetailScreenState extends State<FmStationDetailScreen>
    with TickerProviderStateMixin {
  bool _muted = false;
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late FmRadioProvider _provider;

  FmStation get _s => widget.station;

  @override
  void initState() {
    super.initState();
    _provider = context.read<FmRadioProvider>();
    _provider.addListener(_onProviderChange);

    // Entrance animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    // Pulse animation for artwork when playing
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceController.forward();
      // Ensure pulse syncs
      _onProviderChange();
    });
  }

  void _onProviderChange() {
    if (!mounted) return;
    if (_provider.isPlaying) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChange);
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _muted = !_muted;
    });
    context.read<AudioProvider>().setVolume(_muted ? 0.0 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const maxContentWidth = 500.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: FmRadioTheme.deepSpace,
        body: Consumer<FmRadioProvider>(
          builder: (context, provider, child) {
            final isPlaying = provider.isPlaying;
            final isLoading = provider.isLoading;

            return RadioAmbientBackground(
              accentArgb: _s.accentColorArgb,
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth > maxContentWidth
                        ? maxContentWidth
                        : constraints.maxWidth;

                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: w),
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          Navigator.of(context).maybePop(),
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 32,
                                      ),
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                    const Spacer(),
                                    const LiveBroadcastBadge(),
                                  ],
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 12),
                                    // Artwork Hero with Pulsing Glow
                                    Center(
                                      child: AnimatedBuilder(
                                        animation: _pulseController,
                                        builder: (context, child) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color:
                                                      Color(
                                                        _s.accentColorArgb,
                                                      ).withValues(
                                                        alpha:
                                                            0.1 +
                                                            (_pulseController
                                                                    .value *
                                                                0.15),
                                                      ),
                                                  blurRadius:
                                                      40 +
                                                      (_pulseController.value *
                                                          20),
                                                  spreadRadius:
                                                      _pulseController.value *
                                                      10,
                                                ),
                                              ],
                                            ),
                                            child: child,
                                          );
                                        },
                                        child: FmStationArtwork(
                                          heroTag: 'mini_${_s.id}',
                                          stationId: _s.id,
                                          imageUrl: _s.coverImageUrl,
                                          size: 160,
                                          accentArgb: _s.accentColorArgb,
                                          showLiveHalo: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    // Title and Text sliding up
                                    _SlideUpElement(
                                      controller: _entranceController,
                                      delay: 0.2,
                                      child: Column(
                                        children: [
                                          Text(
                                            _s.name,
                                            textAlign: TextAlign.center,
                                            style: theme
                                                .textTheme
                                                .headlineMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: -0.4,
                                                  color: Colors.white,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _s.tagline,
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.7),
                                                  height: 1.4,
                                                ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.trip_origin_rounded,
                                                size: 18,
                                                color: Color(
                                                  _s.accentColorArgb,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${_s.frequencyLabel} FM',
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: Color(
                                                        _s.accentColorArgb,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing: 1,
                                                    ),
                                              ),
                                              if (_s.listenersApprox !=
                                                  null) ...[
                                                const SizedBox(width: 16),
                                                Text(
                                                  '≈ ${_s.listenersApprox} مستمع',
                                                  style: theme
                                                      .textTheme
                                                      .labelMedium
                                                      ?.copyWith(
                                                        color: Colors.white54,
                                                      ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 36),
                                    _SlideUpElement(
                                      controller: _entranceController,
                                      delay: 0.4,
                                      child: AnimatedOpacity(
                                        opacity: isPlaying ? 1.0 : 0.4,
                                        duration: const Duration(
                                          milliseconds: 400,
                                        ),
                                        child: RadioVuMeter(
                                          accentArgb: _s.accentColorArgb,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 28),
                                    _SlideUpElement(
                                      controller: _entranceController,
                                      delay: 0.6,
                                      child: _StreamPanel(
                                        station: _s,
                                        isPlaying: isPlaying,
                                      ),
                                    ),

                                    const SizedBox(height: 36),
                                    _SlideUpElement(
                                      controller: _entranceController,
                                      delay: 0.8,
                                      child: RadioTransportControls(
                                        playing: isPlaying,
                                        loading: isLoading,
                                        isMuted: _muted,
                                        onToggleMute: _toggleMute,
                                        onPlayPause: () =>
                                            provider.togglePlayPause(),
                                        onStop: () => provider.stop(),
                                      ),
                                    ),
                                    const SizedBox(height: 48),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SlideUpElement extends StatelessWidget {
  const _SlideUpElement({
    required this.controller,
    required this.delay,
    required this.child,
  });

  final AnimationController controller;
  final double delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = delay;
    final end = (delay + 0.4).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _StreamPanel extends StatelessWidget {
  const _StreamPanel({required this.station, required this.isPlaying});

  final FmStation station;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Color(
                      station.accentColorArgb,
                    ).withValues(alpha: isPlaying ? 0.25 : 0.1),
                    border: Border.all(
                      color: Color(
                        station.accentColorArgb,
                      ).withValues(alpha: isPlaying ? 0.5 : 0.0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPlaying) ...[
                        Icon(
                          Icons.sensors_rounded,
                          size: 14,
                          color: Color(station.accentColorArgb),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        isPlaying ? 'بث مباشر نشط' : 'استعد للبث',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Color(station.accentColorArgb),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.hd_rounded,
                  color: Colors.white.withValues(alpha: 0.45),
                  size: 26,
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(22),
            ),
            child: Stack(
              children: [
                AspectRatio(aspectRatio: 16 / 9, child: Container()),
                Positioned.fill(
                  child: Image.network(
                    station.coverImageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: FmRadioTheme.deepSpace.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Icon(
                      Icons.radio_rounded,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        color: Colors.white.withValues(alpha: 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: child,
    );
  }
}
