import '../domain/fm_station.dart';

/// Curated mock catalog (replace with API later).
final List<FmStation> mockFmStations = [
  FmStation(
    id: 'quran_live',
    name: 'القرآن الكريم',
    tagline: 'بث مباشر - تلاوات خاشعة طوال اليوم',
    frequencyMhz: 100.0,
    coverImageUrl:
        'https://images.unsplash.com/photo-1584286595398-a59f21d313f5?w=800&q=80', // an Islamic architecture or aesthetic image
    listenersApprox: 245_100,
    accentColorArgb: 0xFFE8B84A,
    streamUrl: '',
  ),
];
