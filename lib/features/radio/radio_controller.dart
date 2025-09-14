import 'dart:async';
import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:m_club/core/services/radio_api_service.dart';
import 'package:m_club/features/radio/models/radio_track.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static AudioHandler? _sharedHandler;
  late final AudioHandler _audioHandler;
  final Completer<void> _audioHandlerCompleter = Completer<void>();

  Future<void> get _audioHandlerReady => _audioHandlerCompleter.future;

  Map<String, String> _streams = {};
  String? _quality;
  PlayerState _playerState = PlayerState(false, ProcessingState.idle);
  RadioTrack? _track;
  Timer? _trackTimer;
  bool _hasError = false;
  bool _streamsUnavailable = false;
  double _volume = 1.0;
  double _previousVolume = 1.0;
  String? _errorMessage;

  static const String _cachedStreamsKey = 'radio_streams';

  Map<String, String> get streams => _streams;
  String? get quality => _quality;
  PlayerState get playerState => _playerState;
  RadioTrack? get track => _track;
  bool get hasError => _hasError;
  bool get streamsUnavailable => _streamsUnavailable;
  double get volume => _volume;
  String? get errorMessage => _errorMessage;

  bool get isConnecting =>
      _playerState.processingState == ProcessingState.loading;
  bool get isBuffering =>
      _playerState.processingState == ProcessingState.buffering;
  bool get isPlaying =>
      _playerState.playing &&
      _playerState.processingState == ProcessingState.ready;
  bool get isPaused =>
      !_playerState.playing &&
      _playerState.processingState == ProcessingState.ready;

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
    _errorMessage = null;
    notifyListeners();
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

  /// Retries playback of the current stream.
  Future<void> retry() async {
    _hasError = false;
    _errorMessage = null;
    if (_streams.isEmpty) {
      await init(quality: _quality);
    } else {
      await _startStream();
    }
    notifyListeners();
  }

  /// Loads available streams and starts playback using selected [quality].
  Future<void> init({String? quality}) async {
    await _initAudioHandler();
    if (!_audioHandlerCompleter.isCompleted) {
      _audioHandlerCompleter.complete();
    }
    if (_hasError) {
      notifyListeners();
      return;
    }

    _streamsUnavailable = false;
    try {
      _streams = await _api.fetchStreams();
      if (_streams.isNotEmpty) {
        await _saveStreamsToCache(_streams);
      } else {
        _streams = await _loadStreamsFromCache();
        if (_streams.isEmpty) {
          _streamsUnavailable = true;
          notifyListeners();
          return;
        }
      }
    } catch (e, s) {
      _streams = await _loadStreamsFromCache();
      if (_streams.isEmpty) {
        _streamsUnavailable = true;
        notifyListeners();
        debugPrint('Failed to fetch radio streams: $e\n$s');
        return;
      }
    }

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
    _errorMessage = null;
    try {
      await _audioHandler.stop();
      await _player.setUrl(url);
      await _audioHandler.play();
      await _updateTrackInfo();
      notifyListeners();
    } catch (e, s) {
      _hasError = true;
      _errorMessage = 'Failed to start radio playback: ${e.toString()}';
      _logPlaybackFailure('startStream', e, s);
      notifyListeners();
    }
  }

  Future<void> _saveStreamsToCache(Map<String, String> streams) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedStreamsKey, jsonEncode(streams));
    } catch (_) {
      // ignore cache errors
    }
  }

  Future<Map<String, String>> _loadStreamsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_cachedStreamsKey);
      if (data == null) return {};
      final Map<String, dynamic> decoded = jsonDecode(data);
      return decoded.map((key, value) => MapEntry(key, value as String));
    } catch (_) {
      return {};
    }
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
    if (_sharedHandler != null) {
      _audioHandler = _sharedHandler!;
      return;
    }
    try {
      _sharedHandler = await AudioService.init(
        builder: () => _RadioAudioHandler(_player),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'm_club_radio_channel',
          androidNotificationChannelName: 'M-Club Radio',
          androidNotificationIcon: 'assets/images/Radio_RE_Logo.webp',
          androidNotificationOngoing: true,
        ),
      );
      _audioHandler = _sharedHandler!;
    } catch (e, s) {
      _hasError = true;
      _errorMessage = 'Audio service error: ${e.toString()}';
      _logPlaybackFailure('initAudioHandler', e, s);
      _audioHandler = _sharedHandler ?? _RadioAudioHandler(_player);
      _sharedHandler ??= _audioHandler;
    }
  }

  void _logPlaybackFailure(String context, Object error, StackTrace stack) {
    debugPrint('Playback failure in $context: $error\n$stack');
    // TODO: integrate analytics reporting here.
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

