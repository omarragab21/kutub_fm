import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Extracts a chapter's text from a book PDF **online** (server-side) so the
/// raw PDF file never gets downloaded to the device — protecting copyright.
///
/// Flow (mirrors [TranscriptionApiService]):
///   1. Return the cached text from Firestore if it matches the requested range.
///   2. Otherwise call the extraction server (base URL from Remote Config) which
///      reads the PDF and returns text only.
///   3. Cache the returned text back into Firestore for next time.
///
/// Expected server contract:
///   POST {baseUrl}/extract-pdf   (multipart/form-data)
///     fields: url, start_page (optional), end_page (optional), language
///     response JSON: { "success": true, "text": "..." }
class PdfTextApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Remote Config key for the dedicated PDF server; falls back to the
  /// Whisper server URL when unset so a single server can host both.
  static const String _pdfBaseUrlKey = 'pdf_base_url';
  static const String _whisperBaseUrlKey = 'whisper_base_url';

  Future<String> getOrExtractText({
    required String bookId,
    String? chapterId,
    required String pdfUrl,
    int? startPage,
    int? endPage,
    CancelToken? cancelToken,
  }) async {
    final docRef = _docRef(bookId, chapterId);

    // 1. Firestore cache (validated against the requested page range).
    if (docRef != null) {
      final snapshot = await docRef.get();
      final data = snapshot.data();
      if (data != null) {
        final cachedText = (data['pdfText'] ?? '').toString().trim();
        if (cachedText.isNotEmpty &&
            _samePage(data['pdfTextStartPage'], startPage) &&
            _samePage(data['pdfTextEndPage'], endPage)) {
          log('[PdfTextApiService] Using cached PDF text from Firestore.');
          return cachedText;
        }
      }
    }

    if (pdfUrl.trim().isEmpty) {
      throw Exception('رابط ملف الكتاب فارغ.');
    }

    // 2. Resolve the extraction server base URL from Remote Config.
    final baseUrl = await _resolveBaseUrl();
    if (baseUrl.isEmpty) {
      throw Exception('رابط خادم استخراج النص غير متوفر في Remote Config.');
    }

    // 3. Ask the server to read the PDF online and return text only.
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5),
    ));

    final formData = FormData.fromMap({
      'url': pdfUrl.trim(),
      'start_page': ?startPage,
      'end_page': ?endPage,
      'language': 'ar',
    });

    log('[PdfTextApiService] Calling PDF extractor: POST $baseUrl/extract-pdf');
    final response = await dio.post(
      '$baseUrl/extract-pdf',
      data: formData,
      options: Options(headers: {'ngrok-skip-browser-warning': 'true'}),
      cancelToken: cancelToken,
    );

    if (response.statusCode != 200 || response.data == null) {
      throw Exception(
        'فشل استجابة خادم استخراج النص. رمز الاستجابة: ${response.statusCode}',
      );
    }

    final Map<String, dynamic> responseData = response.data is String
        ? jsonDecode(response.data as String) as Map<String, dynamic>
        : response.data as Map<String, dynamic>;

    final text = _readText(responseData);
    final success = responseData['success'] as bool? ?? text.isNotEmpty;
    if (!success || text.isEmpty) {
      throw Exception('خادم استخراج النص لم يرجع محتوى.');
    }

    // 4. Cache the extracted text back to Firestore.
    if (docRef != null) {
      await docRef.set({
        'pdfText': text,
        'pdfTextStartPage': startPage,
        'pdfTextEndPage': endPage,
        'pdfTextSourceUrl': pdfUrl.trim(),
        'pdfTextUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return text;
  }

  DocumentReference<Map<String, dynamic>>? _docRef(
    String bookId,
    String? chapterId,
  ) {
    if (bookId.trim().isEmpty) return null;
    final bookRef = _firestore.collection('books').doc(bookId);
    if (chapterId == null || chapterId.trim().isEmpty) {
      return bookRef;
    }
    return bookRef.collection('chapters').doc(chapterId);
  }

  Future<String> _resolveBaseUrl() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    try {
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 15),
        minimumFetchInterval: const Duration(minutes: 5),
      ));
      await remoteConfig.fetchAndActivate();
    } catch (e) {
      log('[PdfTextApiService] Remote Config fetch failed: $e');
      // Fall back to last activated config values.
    }
    final pdfUrl = remoteConfig.getString(_pdfBaseUrlKey).trim();
    if (pdfUrl.isNotEmpty) return pdfUrl;
    return remoteConfig.getString(_whisperBaseUrlKey).trim();
  }

  String _readText(Map<String, dynamic> data) {
    final direct = (data['text'] as String? ?? '').trim();
    if (direct.isNotEmpty) return direct;

    // Accept a sentences array (like the Whisper response) as a fallback.
    final sentences = data['sentences'] as List?;
    if (sentences != null) {
      final joined = sentences
          .whereType<Map<String, dynamic>>()
          .map((s) => (s['text']?.toString() ?? '').trim())
          .where((t) => t.isNotEmpty)
          .join('\n\n');
      return joined.trim();
    }
    return '';
  }

  bool _samePage(dynamic cached, int? requested) {
    final parsed =
        cached is int ? cached : int.tryParse(cached?.toString() ?? '');
    return parsed == requested;
  }
}
