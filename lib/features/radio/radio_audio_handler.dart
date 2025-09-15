import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:m_club/features/radio/models/radio_track.dart';

class RadioAudioHandler extends BaseAudioHandler with SeekHandler {
  RadioAudioHandler(this._player) {
    _player.playbackEventStream
        .map(_transformEvent)
        .listen(playbackState.add);
  }

  final AudioPlayer _player;

  /// Updates the current track information for external clients.
  void updateTrack(RadioTrack track) {
    Uri? artUri;
    if (track.image.isNotEmpty) {
      final uri = Uri.tryParse(track.image);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        artUri = uri;
      }
    }
    artUri ??= Uri.parse('asset:///assets/images/Radio_RE_Logo.webp');

    mediaItem.add(
      MediaItem(
        id: 'mclub_radio',
        title: track.title,
        artist: track.artist,
        artUri: artUri,
      ),
    );
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    final playing = _player.playing;
    final controls = <MediaControl>[
      playing ? MediaControl.pause : MediaControl.play,
      MediaControl.stop,
    ];

    return PlaybackState(
      controls: controls,
      androidCompactActionIndices: const [0, 1],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[event.processingState]!,
      playing: playing,
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
  Future<void> stop() async {
    await _player.stop();
    final session = await AudioSession.instance;
    await session.setActive(false);
  }
}

