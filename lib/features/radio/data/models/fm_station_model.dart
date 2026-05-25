import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/fm_station.dart';

class FmStationModel extends FmStation {
  const FmStationModel({
    required super.id,
    required super.name,
    required super.tagline,
    required super.streamUrl,
    required super.coverImageUrl,
    super.frequencyMhz,
    super.listenersApprox,
    super.accentColorArgb,
    this.isActive = true,
    this.isQuranStation = false,
    this.sortOrder = 0,
  });

  final bool isActive;
  final bool isQuranStation;
  final int sortOrder;

  factory FmStationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return FmStationModel.fromMap(
      snapshot.data() ?? const <String, dynamic>{},
      fallbackId: snapshot.id,
    );
  }

  factory FmStationModel.fromMap(
    Map<String, dynamic> data, {
    required String fallbackId,
  }) {
    return FmStationModel(
      id: _readString(data, [
        'id',
        'stationId',
        'station_id',
      ]).ifEmpty(fallbackId),
      name: _readString(data, [
        'name',
        'title',
        'stationName',
        'station_name',
      ]).ifEmpty('محطة راديو'),
      tagline: _readString(data, [
        'tagline',
        'description',
        'subtitle',
        'summary',
        'genre',
        'category',
      ]).ifEmpty('بث مباشر'),
      streamUrl: _readString(data, [
        'streamUrl',
        'stream_url',
        'streamURL',
        'audioUrl',
        'audio_url',
        'liveUrl',
        'live_url',
        'url',
        'source',
        'stream.url',
        'streamUrl.url',
      ]),
      coverImageUrl:
          _readString(data, [
            'coverImageUrl',
            'cover_image_url',
            'imageUrl',
            'image_url',
            'artworkUrl',
            'artwork_url',
            'logoUrl',
            'logo_url',
            'favicon',
            'thumbnail',
            'thumbnailUrl',
          ]).ifEmpty(
            'https://images.unsplash.com/photo-1584286595398-a59f21d313f5?w=500&q=80',
          ),
      frequencyMhz:
          _readDouble(data, ['frequencyMhz', 'frequency_mhz', 'frequency']) ??
          100.0,
      listenersApprox: _readInt(data, [
        'listenersApprox',
        'listeners_approx',
        'listeners',
        'votes',
      ]),
      accentColorArgb: _readColor(data) ?? 0xFFF2CA50,
      isActive:
          _readBool(data, ['isActive', 'is_active', 'active', 'enabled']) ??
          true,
      isQuranStation:
          _readBool(data, [
            'isQuranStation',
            'is_quran_station',
            'quranOnly',
            'quran_only',
          ]) ??
          _looksLikeQuranStation(data),
      sortOrder:
          _readInt(data, [
            'sortOrder',
            'sort_order',
            'order',
            'orderIndex',
            'order_index',
          ]) ??
          0,
    );
  }

  bool get hasPlayableStream => streamUrl.trim().isNotEmpty;

  static String _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = _readValue(data, key);
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static int? _readInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = _readValue(data, key);
      if (value is int) return value;
      if (value is num) return value.round();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static double? _readDouble(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = _readValue(data, key);
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static bool? _readBool(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = _readValue(data, key);
      if (value is bool) return value;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') return true;
        if (normalized == 'false' || normalized == '0') return false;
      }
      if (value is num) return value != 0;
    }
    return null;
  }

  static int? _readColor(Map<String, dynamic> data) {
    final intColor = _readInt(data, [
      'accentColorArgb',
      'accent_color_argb',
      'accentColor',
      'accent_color',
    ]);
    if (intColor != null) return intColor;

    final hex = _readString(data, [
      'accentColorHex',
      'accent_color_hex',
      'accentHex',
      'color',
    ]);
    if (hex.isEmpty) return null;

    final cleaned = hex.replaceAll('#', '').replaceAll('0x', '');
    final normalized = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    return int.tryParse(normalized, radix: 16);
  }

  static bool _looksLikeQuranStation(Map<String, dynamic> data) {
    final text = [
      _readString(data, ['name', 'title', 'stationName', 'station_name']),
      _readString(data, ['tagline', 'description', 'subtitle', 'summary']),
      _readString(data, ['tags', 'category']),
    ].join(' ').toLowerCase();

    return text.contains('quran') ||
        text.contains('koran') ||
        text.contains('قرآن') ||
        text.contains('القران') ||
        text.contains('القرآن');
  }

  static Object? _readValue(Map<String, dynamic> data, String key) {
    if (!key.contains('.')) return data[key];

    Object? current = data;
    for (final part in key.split('.')) {
      if (current is! Map) return null;
      current = current[part];
    }
    return current;
  }
}

extension _StringFallback on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
