import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/transcript_segment.dart';

class TranscriptAssetLoader {
  const TranscriptAssetLoader();

  Future<TranscriptDocument> loadFromAsset(String assetPath) async {
    final rawJson = await rootBundle.loadString(assetPath);
    final decodedJson = jsonDecode(rawJson);
    return TranscriptDocument.fromJson(decodedJson);
  }
}
