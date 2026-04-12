import 'package:flutter/material.dart';

import '../../domain/fm_station.dart';
import '../theme/fm_radio_theme.dart';

/// Square cover with optional [Hero] for station → detail transition.
class FmStationArtwork extends StatelessWidget {
  const FmStationArtwork({
    super.key,
    required this.stationId,
    required this.imageUrl,
    required this.size,
    this.heroTag,
    this.borderRadius,
    this.accentArgb,
    this.showLiveHalo = false,
  });

  final String stationId;
  final String imageUrl;
  final double size;
  final Object? heroTag;
  final BorderRadius? borderRadius;
  final int? accentArgb;
  final bool showLiveHalo;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.2);
    final tag = heroTag ?? FmStation.heroTag(stationId);
    final accent = Color(accentArgb ?? 0xFFF2CA50);

    Widget image = ClipRRect(
      borderRadius: radius,
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: const Color(0xFF2A2A2E),
          child: Icon(
            Icons.radio_rounded,
            size: size * 0.42,
            color: accent.withValues(alpha: 0.85),
          ),
        ),
      ),
    );

    if (showLiveHalo) {
      image = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.45),
              blurRadius: 28,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: FmRadioTheme.liveRed.withValues(alpha: 0.25),
              blurRadius: 36,
              spreadRadius: 0,
            ),
          ],
        ),
        child: image,
      );
    }

    return Hero(
      tag: tag,
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: image,
        ),
      ),
    );
  }
}
