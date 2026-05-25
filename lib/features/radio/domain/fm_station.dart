/// Broadcast station shown in the FM radio experience.
class FmStation {
  const FmStation({
    required this.id,
    required this.name,
    required this.tagline,
    required this.streamUrl,
    required this.coverImageUrl,
    this.frequencyMhz = 100.0,
    this.listenersApprox,
    this.accentColorArgb = 0xFFF2CA50,
  });

  final String id;
  final String name;
  final String tagline;

  /// Direct audio stream URL.
  final String streamUrl;

  final String coverImageUrl;
  final double frequencyMhz;
  final int? listenersApprox;
  final int accentColorArgb;

  String get frequencyLabel => frequencyMhz.toStringAsFixed(1);

  static String heroTag(String id) => 'fm_station_cover_$id';
}
