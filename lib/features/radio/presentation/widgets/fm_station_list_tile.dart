import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/fm_station.dart';
import 'fm_station_artwork.dart';
import 'live_broadcast_badge.dart';
import '../provider/fm_radio_provider.dart';

typedef OnStationTap = void Function(FmStation station);

/// Premium row for the stations list with play states.
class FmStationListTile extends StatelessWidget {
  const FmStationListTile({
    super.key,
    required this.station,
    required this.animation,
    required this.onTap,
  });

  final FmStation station;
  final Animation<double> animation;
  final OnStationTap onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Consumer<FmRadioProvider>(
      builder: (context, provider, child) {
        final isActive = provider.currentStation?.id == station.id;
        final isPlaying = isActive && provider.isPlaying;
        final isLoading = isActive && provider.isLoading;

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final t = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return Opacity(
              opacity: t.value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, 24 * (1 - t.value)),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTap(station),
                borderRadius: BorderRadius.circular(20),
                splashColor: Color(station.accentColorArgb).withValues(alpha: 0.1),
                highlightColor: Color(station.accentColorArgb).withValues(alpha: 0.05),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isActive
                          ? [
                              Color(station.accentColorArgb).withValues(alpha: 0.2),
                              Color(station.accentColorArgb).withValues(alpha: 0.05),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.white.withValues(alpha: 0.02),
                            ],
                    ),
                    border: Border.all(
                      color: isActive
                          ? Color(station.accentColorArgb).withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.08),
                      width: isActive ? 1.5 : 1.0,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Color(station.accentColorArgb).withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            )
                          ]
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            FmStationArtwork(
                              stationId: station.id,
                              imageUrl: station.coverImageUrl,
                              size: 64,
                              accentArgb: station.accentColorArgb,
                            ),
                            if (isLoading)
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(station.accentColorArgb),
                                  ),
                                ),
                              ),
                            if (isPlaying && !isLoading)
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.graphic_eq_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      station.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                        color: isActive
                                            ? Color(station.accentColorArgb)
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                  const LiveBroadcastBadge(compact: true),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                station.tagline,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    isActive ? Icons.play_arrow_rounded : Icons.radio_rounded,
                                    size: 16,
                                    color: Color(station.accentColorArgb)
                                        .withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${station.frequencyLabel} FM',
                                    style: textTheme.labelMedium?.copyWith(
                                      color: Color(station.accentColorArgb),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  if (station.listenersApprox != null) ...[
                                    const Spacer(),
                                    Text(
                                      _formatListeners(station.listenersApprox!),
                                      style: textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isActive ? Icons.volume_up_rounded : Icons.chevron_left_rounded,
                          color: isActive
                              ? Color(station.accentColorArgb)
                              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _formatListeners(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)} ألف مستمع';
    }
    return '$n مستمع';
  }
}
