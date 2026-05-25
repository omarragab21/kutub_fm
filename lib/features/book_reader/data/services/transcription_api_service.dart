import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:kutub_fm/features/book_reader/data/models/transcript_segment.dart';

class TranscriptionResponse {
  final bool success;
  final String text;
  final List<TranscriptSentence> sentences;

  TranscriptionResponse({
    required this.success,
    required this.text,
    required this.sentences,
  });

  factory TranscriptionResponse.fromJson(Map<String, dynamic> json) {
    final list = json['sentences'] as List?;
    return TranscriptionResponse(
      success: json['success'] as bool? ?? false,
      text: json['text'] as String? ?? '',
      sentences: list != null
          ? list.map((s) => TranscriptSentence.fromJson(s as Map<String, dynamic>)).toList()
          : [],
    );
  }
}

class TranscriptSentence {
  final int index;
  final double start;
  final double end;
  final String startTime;
  final String endTime;
  final String text;

  TranscriptSentence({
    required this.index,
    required this.start,
    required this.end,
    required this.startTime,
    required this.endTime,
    required this.text,
  });

  factory TranscriptSentence.fromJson(Map<String, dynamic> json) {
    return TranscriptSentence(
      index: json['index'] is int
          ? json['index'] as int
          : int.tryParse(json['index'].toString()) ?? 0,
      start: (json['start'] as num?)?.toDouble() ?? 0.0,
      end: (json['end'] as num?)?.toDouble() ?? 0.0,
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
    );
  }
}

class TranscriptionApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches a transcript for the given chapter.
  /// If it exists in Firestore, parses it and returns.
  /// Otherwise, generates it using custom Whisper API, saves it in Firestore, and returns.
  Future<TranscriptDocument> getOrGenerateTranscript({
    required String bookId,
    required String chapterId,
    required String chapterTitle,
    required String audioUrl,
    required String bookTitle,
    required String authorName,
    required String genre,
    required String translator,
    required String narrator,
    required String publisher,
    CancelToken? cancelToken,
  }) async {
    // 1. Check Firestore first
    final chapterDocRef = _firestore
        .collection('books')
        .doc(bookId)
        .collection('chapters')
        .doc(chapterId);

    final chapterDoc = await chapterDocRef.get();
    if (chapterDoc.exists) {
      final data = chapterDoc.data();
      if (data != null && data['transcript'] != null) {
        final transcriptStr = data['transcript'].toString().trim();
        if (transcriptStr.isNotEmpty) {
          try {
            final decoded = jsonDecode(transcriptStr) as Map<String, dynamic>;
            final cachedDoc = TranscriptDocument.fromJson(decoded);
            if (!cachedDoc.isEmpty) {
              log('Using cached transcript from Firestore.');
              return cachedDoc;
            }
          } catch (e) {
            log('Malformed cached JSON transcript: $e');
          }
        }
      }
    }

    if (audioUrl.isEmpty) {
      throw Exception('رابط الملف الصوتي فارغ للشابتر الحالي.');
    }

    // 2. Fetch Base URL from Remote Config
    log('Fetching whisper_base_url from Firebase Remote Config...');
    final remoteConfig = FirebaseRemoteConfig.instance;
    try {
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 15),
        minimumFetchInterval: const Duration(minutes: 5),
      ));
      await remoteConfig.fetchAndActivate();
    } catch (e) {
      log('Firebase Remote Config fetch failed: $e');
      // If fetching fails, we can try to proceed using last known active config
    }

    final baseUrl = remoteConfig.getString('whisper_base_url').trim();
    if (baseUrl.isEmpty) {
      throw Exception('رابط API النسخ (whisper_base_url) غير متوفر في Remote Config.');
    }

    log('Using Whisper base URL: $baseUrl');

    // 3. Make Dio request to Whisper API
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 10), // Transcription can take time for long audios
    ));

    final formData = FormData.fromMap({
      'url': audioUrl,
      'language': 'ar',
      'task': 'transcribe',
    });

    log('Calling Whisper API: POST $baseUrl/transcribe');
    final response = await dio.post(
      '$baseUrl/transcribe',
      data: formData,
      options: Options(
        headers: {
          'ngrok-skip-browser-warning': 'true',
        },
      ),
      cancelToken: cancelToken,
    );

    if (response.statusCode != 200 || response.data == null) {
      throw Exception('فشل استجابة خادم النسخ. رمز الاستجابة: ${response.statusCode}');
    }

    // 4. Parse the response
    final Map<String, dynamic> responseData = response.data is String
        ? jsonDecode(response.data as String) as Map<String, dynamic>
        : response.data as Map<String, dynamic>;

    final whisperResponse = TranscriptionResponse.fromJson(responseData);
    if (!whisperResponse.success) {
      throw Exception('فشل تحويل الصوت إلى نص: خادم النسخ لم يرجع استجابة ناجحة.');
    }

    // Map sentences to TranscriptSegments
    final segments = whisperResponse.sentences.map((s) {
      return TranscriptSegment(
        id: s.index,
        text: s.text.trim(),
        start: s.start,
        end: s.end,
        type: TranscriptSegmentType.normal,
      );
    }).toList();

    final metadata = BookMetadata(
      title: chapterTitle,
      author: authorName,
      genre: genre,
      translator: translator,
      narrator: narrator,
      publisher: publisher,
    );

    final doc = TranscriptDocument(
      metadata: metadata,
      segments: segments,
    );

    if (doc.isEmpty) {
      throw Exception('لم يتم توليد أي جمل من ملف الصوت.');
    }

    // 5. Cache back to Firestore
    final docJson = jsonEncode(doc.toJson());
    await chapterDocRef.set({
      'transcript': docJson,
      'transcriptAudioUrl': audioUrl,
      'transcriptGeneratedFromAudio': true,
      'transcriptUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    log('Transcript successfully generated and saved to Firestore.');
    return doc;
  }
}
