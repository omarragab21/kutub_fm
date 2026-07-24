import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseStorageUrlResolver {
  FirebaseStorageUrlResolver._();

  static const String _seoulCamelliaCoverAsset =
      'assets/generated/book_seoul_camellia_cover_ai.png';

  static final Map<String, String> _cache = <String, String>{};

  static Future<String> resolve(String rawUrl) async {
    final trimmed = rawUrl.trim();
    
    // Handle empty or invalid URLs
    if (trimmed.isEmpty) {
      return '';
    }
    
    // Handle asset URLs
    if (trimmed.startsWith('assets/')) {
      return trimmed;
    }
    
    // Handle malformed file:// URLs
    if (trimmed.startsWith('file:///') && trimmed.length <= 8) {
      debugPrint('Invalid file URL detected: $trimmed');
      return '';
    }
    
    // Handle file:// URLs that aren't local assets
    if (trimmed.startsWith('file://')) {
      debugPrint('File URL passed to NetworkImage resolver: $trimmed');
      return ''; // Return empty to prevent NetworkImage error
    }

    final cached = _cache[trimmed];
    if (cached != null) return cached;

    if (_isTokenizedFirebaseDownloadUrl(trimmed)) {
      return trimmed;
    }

    // If already a valid HTTP/HTTPS URL, return as-is for NetworkImage
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      _cache[trimmed] = trimmed;
      return trimmed;
    }

    final storagePath = _storagePathFromUrl(trimmed);
    if (storagePath == null) {
      return trimmed;
    }

    final fallbackAsset = _assetFallbackForStoragePath(storagePath);
    if (fallbackAsset != null) {
      _cache[trimmed] = fallbackAsset;
      return fallbackAsset;
    }

    try {
      final resolvedUrl = await FirebaseStorage.instance
          .ref(storagePath)
          .getDownloadURL();
      _cache[trimmed] = resolvedUrl;
      return resolvedUrl;
    } catch (error) {
      debugPrint('Failed to resolve Firebase Storage URL: $trimmed ($error)');
      final fallbackAsset = _assetFallbackForStoragePath(storagePath) ?? '';
      _cache[trimmed] = fallbackAsset;
      return fallbackAsset;
    }
  }

  static bool _isTokenizedFirebaseDownloadUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || uri.host != 'firebasestorage.googleapis.com') {
      return false;
    }
    return uri.queryParameters.containsKey('token');
  }

  static String? _storagePathFromUrl(String rawUrl) {
    if (rawUrl.startsWith('gs://')) {
      final uri = Uri.tryParse(rawUrl);
      if (uri == null) return null;
      final path = uri.pathSegments.join('/');
      return path.isEmpty ? null : path;
    }

    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return null;

    if (uri.host == 'storage.googleapis.com') {
      if (uri.pathSegments.length < 2) return null;
      final path = uri.pathSegments.skip(1).join('/');
      return path.isEmpty ? null : path;
    }

    if (uri.host == 'firebasestorage.googleapis.com') {
      final objectIndex = uri.pathSegments.indexOf('o');
      if (objectIndex == -1 || objectIndex + 1 >= uri.pathSegments.length) {
        return null;
      }
      final encodedPath = uri.pathSegments[objectIndex + 1];
      final path = Uri.decodeComponent(encodedPath);
      return path.isEmpty ? null : path;
    }

    return null;
  }

  static String? _assetFallbackForStoragePath(String storagePath) {
    final normalized = storagePath.trim().toLowerCase();
    if (normalized == 'books/book_seoul_camellia/cover.png') {
      return _seoulCamelliaCoverAsset;
    }
    return null;
  }
}
