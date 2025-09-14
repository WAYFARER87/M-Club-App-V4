import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:m_club/core/services/radio_api_service.dart';
import 'package:m_club/features/radio/models/radio_track.dart';

/// Controller responsible for playing radio streams and
/// providing information about current track and player state.
class RadioController extends ChangeNotifier {
  RadioController() {
    _player.playerStateStream.listen((state) {
      _playerState = state;
      notifyListeners();
    });

    _player.processingStateStream.listen((state) async {
      if (state == ProcessingState.idle && _player.audioSource != null) {
        _hasError = true;
        await _audioHandlerReady;
        await _audioHandler.stop();
      }
      notifyListeners();
    });
  }

  final RadioApiService _api = RadioApiService();
  final AudioPlayer _player = AudioPlayer();
  late final AudioHandler _audioHandler;
  final Completer<void> _audioHandlerCompleter = Completer<void>();

  Future<void> get _audioHandlerReady => _audioHandlerCompleter.future;

  Map<String, String> _streams = {};
  String? _quality;
  PlayerState _playerState = PlayerState(false, ProcessingState.idle);
  RadioTrack? _track;
  Timer? _trackTimer;
  bool _hasError = false;
  double _volume = 1.0;
  double _previousVolume = 1.0;

  Map<String, String> get streams => _streams;
  String? get quality => _quality;
  PlayerState get playerState => _playerState;
  RadioTrack? get track => _track;
  bool get hasError => _hasError;
  double get volume => _volume;

  /// Starts playback if the stream is not playing and stops otherwise.
  Future<void> togglePlay() async {
    await _audioHandlerReady;
    if (_player.playing) {
      await _audioHandler.stop();
    } else {
      if (_player.audioSource == null && _streams.isNotEmpty) {
        await _startStream();
      } else {
        await _audioHandler.play();
      }
    }
    _hasError = false;
  }

  /// Sets the player volume to a value between 0.0 and 1.0.
  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0);
    if (_volume > 0) {
      _previousVolume = _volume;
    }
    await _player.setVolume(_volume);
    notifyListeners();
  }

  /// Toggles mute state preserving the last non-zero volume value.
  Future<void> toggleMute() async {
    if (_volume > 0) {
      _previousVolume = _volume;
      _volume = 0;
    } else {
      _volume = _previousVolume;
    }
    await _player.setVolume(_volume);
    notifyListeners();
  }

  /// Loads available streams and starts playback using selected [quality].
  Future<void> init({String? quality}) async {
    await _initAudioHandler();
    if (!_audioHandlerCompleter.isCompleted) {
      _audioHandlerCompleter.complete();
    }

    try {
      _streams = await _api.fetchStreams();
    } catch (e, s) {
      _hasError = true;
      notifyListeners();
      debugPrint('Failed to fetch radio streams: $e\n$s');
      return;
    }
    if (_streams.isEmpty) return;

    _quality = quality ?? _streams.keys.first;
    await _startStream();
    _startTrackInfoTimer();
  }

  /// Changes stream quality and restarts playback with a new URL.
  Future<void> setQuality(String quality) async {
    if (!_streams.containsKey(quality) || _quality == quality) return;
    _quality = quality;
    await _startStream();
    notifyListeners();
  }

  Future<void> _startStream() async {
    await _audioHandlerReady;
    final url = _streams[_quality];
    if (url == null) return;
    _hasError = false;
    await _audioHandler.stop();
    try {
      await _player.setUrl(url);
    } catch (e, s) {
      _hasError = true;
      notifyListeners();
      debugPrint('Failed to set radio stream URL: $e\n$s');
      return;
    }
    await _audioHandler.play();
    await _updateTrackInfo();
  }

  void _startTrackInfoTimer() {
    _trackTimer?.cancel();
    _trackTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateTrackInfo();
    });
  }

  Future<void> _updateTrackInfo() async {
    await _audioHandlerReady;
    try {
      final info = await _api.fetchTrackInfo();
      if (info == null) return;
      _track = info;
      (_audioHandler as _RadioAudioHandler).updateTrack(info);
      notifyListeners();
    } catch (_) {
      // ignore errors
    }
  }

  @override
  void dispose() {
    _trackTimer?.cancel();
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _initAudioHandler() async {
    _audioHandler = await AudioService.init(
      builder: () => _RadioAudioHandler(_player),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'm_club_radio_channel',
        androidNotificationChannelName: 'M-Club Radio',
        androidNotificationIcon: 'assets/images/Radio_RE_Logo.webp',
        androidNotificationOngoing: true,
      ),
    );
  }
}

class _RadioAudioHandler extends BaseAudioHandler with SeekHandler {
  _RadioAudioHandler(this._player) {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  final AudioPlayer _player;

  /// Updates the current track information for external clients.
  void updateTrack(RadioTrack track) {
    mediaItem.add(
      MediaItem(
        id: 'mclub_radio',
        title: track.title,
        artist: track.artist,
        artUri: Uri.parse('asset:///assets/images/Radio_RE_Logo.webp'),
      ),
    );
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [MediaControl.stop],
      androidCompactActionIndices: const [0],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[event.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();
}

