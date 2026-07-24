import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/stats/user_stats_tracker.dart';

class ReadingProgressService {
  static const _prefix = 'reading_progress';

  static String _key(String bookId, String chapterId) {
    return '${_prefix}_${bookId}_$chapterId';
  }

  static Future<double> getProgress(String bookId, String chapterId) async {
    if (bookId.isEmpty || chapterId.isEmpty) return 0.0;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_key(bookId, chapterId)) ?? 0.0;
  }

  static Future<void> setProgress(
    String bookId,
    String chapterId,
    double progress,
  ) async {
    if (bookId.isEmpty || chapterId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final clamped = progress.clamp(0.0, 1.0);
    final previous = prefs.getDouble(_key(bookId, chapterId)) ?? 0.0;
    await prefs.setDouble(_key(bookId, chapterId), clamped);

    // If progress increased by at least 2% (approx 1 page), track pages read
    if (clamped > previous) {
      final diff = clamped - previous;
      final pagesDelta = (diff / 0.02).floor();
      if (pagesDelta >= 1) {
        UserStatsTracker.instance.recordPagesRead(pagesDelta);
      }
    }
  }
}
