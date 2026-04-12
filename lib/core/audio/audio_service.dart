import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_models.dart';

class AudioService {
  AudioService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  final ValueNotifier<AudioState> stateListenable = ValueNotifier(
    const AudioState(),
  );

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<Duration>? _bufferedPositionSub;
  StreamSubscription<double>? _speedSub;

  bool _initialized = false;
  int _loadRequestId = 0;

  AudioState get state => stateListenable.value;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _playerStateSub = _player.playerStateStream.listen(
      _handlePlayerState,
      onError: _handleStreamError,
    );
    _positionSub = _player.positionStream.listen(
      _handlePosition,
      onError: _handleStreamError,
    );
    _durationSub = _player.durationStream.listen(
      _handleDuration,
      onError: _handleStreamError,
    );
    _bufferedPositionSub = _player.bufferedPositionStream.listen(
      _handleBufferedPosition,
      onError: _handleStreamError,
    );
    _speedSub = _player.speedStream.listen(
      _handleSpeed,
      onError: _handleStreamError,
    );

    await _player.setVolume(state.volume);
  }

  Future<void> loadTrack(
    AudioTrack track, {
    bool autoplay = false,
    Duration initialPosition = Duration.zero,
    double speed = 1.0,
  }) async {
    await initialize();

    final requestId = ++_loadRequestId;
    final isSameTrack = state.currentTrack?.cacheKey == track.cacheKey;

    _emit(
      state.copyWith(
        mode: track.mode,
        currentTrack: track,
        isPlaying: false,
        isLoading: true,
        isBuffering: false,
        position: initialPosition,
        duration: isSameTrack ? state.duration : Duration.zero,
        errorMessage: null,
      ),
    );

    try {
      if (!isSameTrack || _player.processingState == ProcessingState.idle) {
        await _player.stop();
        if (requestId != _loadRequestId) return;

        await _player.setAudioSource(
          track.buildAudioSource(),
          initialPosition: initialPosition,
        );
      } else if (_player.position != initialPosition) {
        await _player.seek(initialPosition);
      }

      if (requestId != _loadRequestId) return;

      if (_player.speed != speed) {
        await _player.setSpeed(speed);
      }

      if (requestId != _loadRequestId) return;

      if (autoplay) {
        await _player.play();
      } else {
        _emit(
          state.copyWith(
            isLoading: false,
            isBuffering: _player.processingState == ProcessingState.buffering,
            isPlaying: false,
          ),
        );
      }
    } catch (error) {
      if (requestId != _loadRequestId) return;

      _emit(
        state.copyWith(
          isPlaying: false,
          isLoading: false,
          isBuffering: false,
          errorMessage: _normalizeError(error),
        ),
      );
      rethrow;
    }
  }

  Future<void> play() async {
    await initialize();
    if (!state.hasSource) return;

    try {
      await _player.play();
    } catch (error) {
      _emit(state.copyWith(errorMessage: _normalizeError(error)));
    }
  }

  Future<void> pause() async {
    await initialize();
    if (!state.hasSource) return;

    try {
      await _player.pause();
    } catch (error) {
      _emit(state.copyWith(errorMessage: _normalizeError(error)));
    }
  }

  Future<void> seek(Duration position) async {
    await initialize();
    if (!state.canSeek) return;

    try {
      await _player.seek(position);
    } catch (error) {
      _emit(state.copyWith(errorMessage: _normalizeError(error)));
    }
  }

  Future<void> setSpeed(double speed) async {
    await initialize();

    try {
      await _player.setSpeed(speed);
      _emit(state.copyWith(speed: speed));
    } catch (error) {
      _emit(state.copyWith(errorMessage: _normalizeError(error)));
    }
  }

  Future<void> setVolume(double volume) async {
    await initialize();

    try {
      await _player.setVolume(volume);
      _emit(state.copyWith(volume: volume));
    } catch (error) {
      _emit(state.copyWith(errorMessage: _normalizeError(error)));
    }
  }

  Future<void> stop() async {
    await initialize();
    ++_loadRequestId;

    try {
      await _player.stop();
      _emit(AudioState(volume: state.volume));
    } catch (error) {
      _emit(state.copyWith(errorMessage: _normalizeError(error)));
    }
  }

  Future<void> dispose() async {
    await _playerStateSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _bufferedPositionSub?.cancel();
    await _speedSub?.cancel();
    await _player.dispose();
    stateListenable.dispose();
  }

  void _handlePlayerState(PlayerState playerState) {
    final processingState = playerState.processingState;

    _emit(
      state.copyWith(
        isPlaying:
            playerState.playing && processingState != ProcessingState.completed,
        isLoading: processingState == ProcessingState.loading,
        isBuffering: processingState == ProcessingState.buffering,
        position: processingState == ProcessingState.completed
            ? state.duration
            : state.position,
      ),
    );
  }

  void _handlePosition(Duration position) {
    _emit(state.copyWith(position: position));
  }

  void _handleDuration(Duration? duration) {
    _emit(state.copyWith(duration: duration ?? Duration.zero));
  }

  void _handleBufferedPosition(Duration position) {
    _emit(state.copyWith(bufferedPosition: position));
  }

  void _handleSpeed(double speed) {
    _emit(state.copyWith(speed: speed));
  }

  void _handleStreamError(Object error, [StackTrace? stackTrace]) {
    _emit(
      state.copyWith(
        isPlaying: false,
        isLoading: false,
        isBuffering: false,
        errorMessage: _normalizeError(error),
      ),
    );
  }

  void _emit(AudioState newState) {
    stateListenable.value = newState;
  }

  String _normalizeError(Object error) {
    if (error is PlayerException) {
      return error.message ?? 'Audio player error (${error.code}).';
    }

    return error.toString();
  }
}
