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

  factory FmStation.fromJson(Map<String, dynamic> json) {
    final rawName = (json['name']?.toString() ?? 'محطة راديو').trim();
    final rawTags = json['tags']?.toString() ?? '';
    final rawFavicon = json['favicon']?.toString() ?? '';
    
    return FmStation(
      id: json['stationuuid']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: rawName.isEmpty ? 'محطة راديو' : rawName,
      tagline: rawTags.isNotEmpty ? rawTags.split(',').first.trim() : 'بث مباشر',
      streamUrl: json['url_resolved']?.toString() ?? json['url']?.toString() ?? '',
      coverImageUrl: rawFavicon.isNotEmpty 
          ? rawFavicon 
          : 'https://images.unsplash.com/photo-1584286595398-a59f21d313f5?w=500&q=80',
      listenersApprox: json['votes'] is int ? json['votes'] as int : null,
      accentColorArgb: 0xFFF2CA50,
    );
  }
}
