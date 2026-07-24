/// Represents a single audio episode/track within a radio program.
class RadioAudio {
  const RadioAudio({
    required this.id,
    required this.title,
    required this.url,
    this.subtitle,
  });

  final String id;
  final String title;
  final String url;
  final String? subtitle;
}

/// Represents a program within a radio station, containing multiple audio episodes.
class RadioProgram {
  const RadioProgram({
    required this.id,
    required this.title,
    this.audios = const [],
  });

  final String id;
  final String title;
  final List<RadioAudio> audios;
}

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
    this.programs = const [],
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

  /// Programs broadcasted by this station with audio episodes.
  final List<RadioProgram> programs;

  String get frequencyLabel => frequencyMhz.toStringAsFixed(1);

  static String heroTag(String id) => 'fm_station_cover_$id';
}

