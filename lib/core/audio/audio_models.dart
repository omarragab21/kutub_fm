import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

enum AudioMode { idle, readingAudio, audiobook, fmRadio, podcast }

enum AudioInputType { asset, uri }

class AudioTrack {
  const AudioTrack({
    required this.id,
    required this.mode,
    required this.inputType,
    required this.source,
    required this.title,
    this.artist,
    this.album,
    this.artUri,
    this.isLive = false,
  });

  final String id;
  final AudioMode mode;
  final AudioInputType inputType;
  final String source;
  final String title;
  final String? artist;
  final String? album;
  final String? artUri;
  final bool isLive;

  String get cacheKey => '${mode.name}|${inputType.name}|$id|$source';

  AudioSource buildAudioSource() {
    final mediaItem = MediaItem(
      id: id,
      title: title,
      artist: artist,
      album: album,
      artUri: _safeUri(artUri),
    );

    switch (inputType) {
      case AudioInputType.asset:
        if (source.trim().isEmpty) {
          throw ArgumentError('Audio asset path is empty.');
        }
        return AudioSource.asset(source, tag: mediaItem);
      case AudioInputType.uri:
        final uri = Uri.tryParse(source.trim());
        if (uri == null || !uri.hasScheme) {
          throw ArgumentError('Audio URL is invalid: $source');
        }
        return AudioSource.uri(uri, tag: mediaItem);
    }
  }

  static Uri? _safeUri(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return null;
    }

    return Uri.tryParse(rawValue.trim());
  }
}

class AudioState {
  const AudioState({
    this.mode = AudioMode.idle,
    this.currentTrack,
    this.isPlaying = false,
    this.isLoading = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
    this.volume = 1.0,
    this.errorMessage,
  });

  final AudioMode mode;
  final AudioTrack? currentTrack;
  final bool isPlaying;
  final bool isLoading;
  final bool isBuffering;
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  final double speed;
  final double volume;
  final String? errorMessage;

  bool get hasSource => currentTrack != null;
  bool get canSeek => hasSource && currentTrack?.isLive != true;

  AudioState copyWith({
    AudioMode? mode,
    Object? currentTrack = _unset,
    bool? isPlaying,
    bool? isLoading,
    bool? isBuffering,
    Duration? position,
    Duration? bufferedPosition,
    Duration? duration,
    double? speed,
    double? volume,
    Object? errorMessage = _unset,
  }) {
    return AudioState(
      mode: mode ?? this.mode,
      currentTrack: identical(currentTrack, _unset)
          ? this.currentTrack
          : currentTrack as AudioTrack?,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  static const Object _unset = Object();
}
