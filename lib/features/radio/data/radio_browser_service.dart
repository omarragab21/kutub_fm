import 'package:dio/dio.dart';
import '../domain/fm_station.dart';

class RadioBrowserService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://de1.api.radio-browser.info/json',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Fetch Egyptian stations explicitly
  Future<List<FmStation>> fetchEgyptStations({bool quranOnly = false}) async {
    try {
      final queryParams = {
        'countrycode': 'EG',
        'hidebroken': 'true',
        'order': 'clickcount',
        'reverse': 'true',
        'limit': '50',
      };

      if (quranOnly) {
        queryParams['name'] = 'Quran';
      }

      final response = await _dio.get('/stations/search', queryParameters: queryParams);
      
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        // Filter out insecure http streams to comply with iOS ATS and ensure 100% playback success
        return data
            .where((json) => json['url'] != null && json['url'].toString().startsWith('https://'))
            .map((json) => FmStation.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch Egyptian stations: $e');
    }
  }

  /// Get the exact playable stream URL by pinging the click tracking endpoint
  Future<String?> getPlayableUrl(String stationUuid) async {
    try {
      final response = await _dio.get('/url/$stationUuid');
      if (response.statusCode == 200 && response.data != null) {
        // The endpoint returns a JSON object like {"ok":true,"message":"ok","stationuuid":"...","name":"...","url":"http://..."}
        if (response.data['url'] != null) {
          return response.data['url'].toString();
        }
      }
    } catch (e) {
      // Provide silent failure; fallback to the url provided in model
    }
    return null;
  }
}
