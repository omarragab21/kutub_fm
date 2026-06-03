import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:path_provider/path_provider.dart';

class ReelApiService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(
        minutes: 10,
      ), // Reel generation can take up to a few minutes
    ),
  );

  /// Gets the base URL for the reel service from Remote Config with fallback.
  Future<String> getBaseUrl() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    try {
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(minutes: 5),
        ),
      );
      await remoteConfig.fetchAndActivate();
    } catch (e) {
      log(
        'Remote Config fetch failed in ReelApiService, using cached values: $e',
      );
    }

    final url = remoteConfig.getString('reel_base_url').trim();
    if (url.isNotEmpty) {
      return url;
    }
    // Fallback URL from user request
    return 'https://sympathy-instructions-earn-listed.trycloudflare.com';
  }

  /// Gets the logo URL for the reel generation from Remote Config with fallback.
  Future<String> getLogoUrl() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    try {
      final logoUrl = remoteConfig.getString('reel_logo_url').trim();
      if (logoUrl.isNotEmpty) {
        return logoUrl;
      }
    } catch (_) {}
    // Standard branding fallback logo
    return 'https://lh3.googleusercontent.com/aida-public/AB6AXuBxB5ydabQuh1USFu2pTGm0SvVp0akGtBgz2qh4GtC2jclIYLdgTUr_P3INAM5NT6y6seNosB20rrIit5RDHuBI3NVpDvhDKZtgG-wWU7NWex-vCQ4SMPFaqbaoLuPR3LSTnFYIhsi4IuHgeIpi-p0iOBZ0OWKVPNeC2gItmjnVDGEcnP_VWZLrw9TnJLySUIuEzB0q6twz2UyBhDy-th-1qaVAGFo40ssKqIuGSKTpUiNznbFmwNGz9SFOGD0n6YqiMpJZzPgyK38';
  }

  /// Requests the remote server to create a video reel.
  /// Returns a Map with the response data (download_url, output_file, etc.).
  Future<Map<String, dynamic>> createReel({
    required String audioUrl,
    required String coverUrl,
    required String start,
    required String end,
  }) async {
    if (audioUrl.isEmpty)
      throw Exception('رابط الملف الصوتي مطلوب لإنشاء الريل.');
    if (coverUrl.isEmpty)
      throw Exception('رابط غلاف الكتاب مطلوب لإنشاء الريل.');

    final baseUrl = await getBaseUrl();
    final logoUrl = await getLogoUrl();

    final requestBody = {
      'audio_url': audioUrl,
      'cover_url': coverUrl,
      'logo_url': logoUrl,
      'start': start,
      'end': end,
      'cover_size': 700,
      'logo_size': 180,
    };

    log('Calling Reel API: POST $baseUrl/make_reel');
    log('Payload: $requestBody');

    try {
      final response = await _dio.post(
        '$baseUrl/make_reel',
        data: requestBody,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'ngrok-skip-browser-warning':
                'true', // Skip ngrok browser warning page if applicable
          },
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception(
          'فشل الاتصال بخادم الريلز. رمز الحالة: ${response.statusCode}',
        );
      }

      final Map<String, dynamic> data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : response.data; // Handles decoded maps from Dio

      final status = data['status']?.toString();
      if (status != 'success') {
        final message =
            data['message']?.toString() ?? 'فشل غير معروف في إنشاء الريل.';
        throw Exception(message);
      }

      return data;
    } catch (e) {
      log('Error creating reel: $e');
      if (e is DioException) {
        final errorMsg = e.response?.data?['message']?.toString() ?? e.message;
        throw Exception('حدث خطأ في الخادم أثناء إنشاء الريل: $errorMsg');
      }
      rethrow;
    }
  }

  /// Downloads the generated MP4 reel file to the device local documents directory.
  /// Returns the absolute path of the downloaded file.
  Future<String> downloadReel(String downloadUrl, String outputFileName) async {
    if (downloadUrl.isEmpty) throw Exception('رابط تحميل مقطع الريل غير متاح.');

    try {
      final appDocDir = await getApplicationDocumentsDirectory();

      // Ensure the reels subdirectory exists
      final reelsDir = Directory('${appDocDir.path}/reels');
      if (!await reelsDir.exists()) {
        await reelsDir.create(recursive: true);
      }

      final localFilePath = '${reelsDir.path}/$outputFileName';
      log('Downloading reel to: $localFilePath');

      final response = await _dio.download(
        downloadUrl,
        localFilePath,
        options: Options(headers: {'ngrok-skip-browser-warning': 'true'}),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'فشل تحميل ملف مقطع الريل. رمز الحالة: ${response.statusCode}',
        );
      }

      // Verify file exists and is not empty
      final file = File(localFilePath);
      if (!await file.exists() || await file.length() == 0) {
        throw Exception('فشل تحميل الملف؛ الملف المحفوظ فارغ.');
      }

      log('Reel downloaded successfully: $localFilePath');
      return localFilePath;
    } catch (e) {
      log('Error downloading reel file: $e');
      if (e is DioException) {
        throw Exception('فشل تحميل مقطع الفيديو من السيرفر: ${e.message}');
      }
      rethrow;
    }
  }
}
