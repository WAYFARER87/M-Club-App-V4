import 'dart:async';

import 'package:flutter/foundation.dart';
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
  }

  final RadioApiService _api = RadioApiService();
  final AudioPlayer _player = AudioPlayer();

  Map<String, String> _streams = {};
  String? _quality;
  PlayerState _playerState = const PlayerState(false, ProcessingState.idle);
  RadioTrack? _track;
  Timer? _trackTimer;

  Map<String, String> get streams => _streams;
  String? get quality => _quality;
  PlayerState get playerState => _playerState;
  RadioTrack? get track => _track;

  /// Loads available streams and starts playback using selected [quality].
  Future<void> init({String? quality}) async {
    _streams = await _api.fetchStreams();
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
    final url = _streams[_quality];
    if (url == null) return;
    await _player.stop();
    await _player.setUrl(url);
    _player.play();
    await _updateTrackInfo();
  }

  void _startTrackInfoTimer() {
    _trackTimer?.cancel();
    _trackTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateTrackInfo();
    });
  }

  Future<void> _updateTrackInfo() async {
    try {
      final info = await _api.fetchTrackInfo();
      _track = info;
      notifyListeners();
    } catch (_) {
      // ignore errors
    }
  }

  @override
  Future<void> dispose() async {
    _trackTimer?.cancel();
    await _player.dispose();
    super.dispose();
  }
}

