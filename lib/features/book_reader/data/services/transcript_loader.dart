import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/transcript_segment.dart';

class TranscriptLoader {
  static const String assetPath = 'assets/transcript.json';

  Future<TranscriptDocument> loadTranscript() async {
    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      return TranscriptDocument.fromJson(jsonData);
    } catch (e) {
      // In a production app, you might want to log this to a service like Sentry
      throw Exception('Failed to load transcript: $e');
    }
  }
}
