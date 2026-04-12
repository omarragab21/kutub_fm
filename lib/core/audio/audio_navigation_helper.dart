import '../../features/book_reader/presentation/pages/book_reader_screen.dart';
import '../../features/radio/domain/fm_station.dart';
import '../navigation/app_navigation_service.dart';
import '../navigation/app_navigation_state.dart';
import '../routes/app_routes.dart';
import 'audio_models.dart';
import 'audio_provider.dart';

class AudioNavigationHelper {
  AudioNavigationHelper._();

  static Future<void> openCurrentPlayingScreen({
    required AudioProvider audioProvider,
    required AppNavigationState navigationState,
  }) async {
    final destination = _resolveDestination(audioProvider);
    if (destination == null || destination.matches(navigationState)) {
      return;
    }

    await AppNavigationService.pushNamed(
      destination.routeName,
      arguments: destination.arguments,
    );
  }

  static _AudioNavigationDestination? _resolveDestination(
    AudioProvider audioProvider,
  ) {
    switch (audioProvider.currentMode) {
      case AudioMode.audiobook:
        return const _AudioNavigationDestination(
          routeName: AppRoutes.audioPlayer,
        );
      case AudioMode.fmRadio:
        final station = audioProvider.currentStation;
        if (station == null) return null;
        return _AudioNavigationDestination(
          routeName: AppRoutes.fmStationDetail,
          arguments: station,
        );
      case AudioMode.readingAudio:
        final bookId = audioProvider.currentReadingBookId;
        final bookTitle = audioProvider.currentReadingBookTitle;
        if (bookId == null || bookTitle == null) return null;
        return _AudioNavigationDestination(
          routeName: AppRoutes.bookReader,
          arguments: BookReaderScreenArgs(
            pdfAssetPath: bookId,
            bookTitle: bookTitle,
          ),
        );
      case AudioMode.podcast:
        final episodeId = audioProvider.currentPodcastEpisodeId;
        if (episodeId == null) return null;
        return _AudioNavigationDestination(
          routeName: AppRoutes.podcastDetail,
          arguments: episodeId,
        );
      case AudioMode.idle:
        return null;
    }
  }
}

class _AudioNavigationDestination {
  const _AudioNavigationDestination({required this.routeName, this.arguments});

  final String routeName;
  final Object? arguments;

  bool matches(AppNavigationState navigationState) {
    if (!navigationState.isCurrentRoute(routeName)) {
      return false;
    }

    final targetArguments = arguments;
    if (targetArguments == null) {
      return true;
    }

    final currentArguments = navigationState.currentRouteArguments;

    if (targetArguments is FmStation && currentArguments is FmStation) {
      return targetArguments.id == currentArguments.id;
    }

    if (targetArguments is BookReaderScreenArgs &&
        currentArguments is BookReaderScreenArgs) {
      return targetArguments.pdfAssetPath == currentArguments.pdfAssetPath &&
          targetArguments.bookTitle == currentArguments.bookTitle;
    }

    if (routeName == AppRoutes.podcastDetail &&
        targetArguments is String &&
        currentArguments is String) {
      return targetArguments == currentArguments;
    }

    return false;
  }
}
