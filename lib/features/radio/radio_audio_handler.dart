import 'dart:io';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:m_club/features/radio/models/radio_track.dart';
import 'package:path_provider/path_provider.dart';

class RadioAudioHandler extends BaseAudioHandler with SeekHandler {
  RadioAudioHandler(this._player) {
    _player.playbackEventStream.map(_transformEvent).listen(playbackState.add);
  }

  final AudioPlayer _player;

  /// Кладём ассет иконки во временный файл и возвращаем file:// URI.
  /// Результат кэшируем между вызовами.
  Uri? _cachedDefaultArtUri;

  Future<Uri> _loadDefaultArtUri() async {
    if (_cachedDefaultArtUri != null) return _cachedDefaultArtUri!;

    const defaultAssetPath = 'assets/images/radio_notification_icon.png';
    const fallbackAssetPath = 'assets/images/Radio_RE_Logo.webp';

    var assetPath = defaultAssetPath;
    late ByteData byteData;

    try {
      byteData = await rootBundle.load(assetPath);
    } on FlutterError catch (error, stackTrace) {
      debugPrint(
        'Failed to load $assetPath. Falling back to $fallbackAssetPath. Error: '
        '$error',
      );
      debugPrint(stackTrace.toString());
      assetPath = fallbackAssetPath;
      byteData = await rootBundle.load(assetPath);
    }

    final dir = await getTemporaryDirectory();
    final fileName = assetPath.split('/').last;
    final file = File('${dir.path}/$fileName');

    // Пишем файл только если его ещё нет или размер 0.
    if (!await file.exists() || (await file.length()) == 0) {
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    }

    _cachedDefaultArtUri = Uri.file(file.path);
    return _cachedDefaultArtUri!;
  }

  /// Обновляет информацию о текущем треке для внешних клиентов (уведомления/lockscreen).
  Future<void> updateTrack(RadioTrack track) async {
    debugPrint('Updating track: ${track.title} - ${track.artist}');

    Uri? artUri;

    // 1) Пытаемся взять картинку из трека, но только http/https.
    if (track.image.isNotEmpty) {
      final uri = Uri.tryParse(track.image);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        artUri = uri;
      }
    }

    // 2) Если не получилось — используем ассет из временного файла (file://).
    artUri ??= await _loadDefaultArtUri();

    // Безопасные дефолты на случай пустых строк.
    final title = (track.title.isNotEmpty) ? track.title : 'M-Club Radio';
    final artist = (track.artist.isNotEmpty) ? track.artist : 'Live';

    mediaItem.add(
      MediaItem(
        id: 'mclub-radio',
        title: title,
        artist: artist,
        artUri: artUri,
      ),
    );
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    final playing = _player.playing;
    debugPrint(
      'Playback event - playing: $playing, processingState: ${event.processingState}',
    );
    const controls = <MediaControl>[
      MediaControl.play,
      MediaControl.pause,
      MediaControl.stop,
    ];

    return PlaybackState(
      controls: controls,
      androidCompactActionIndices: const [0, 1, 2],
      systemActions: const {
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
      },
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
  Future<void> play() async {
    await _player.play();
    playbackState.add(_transformEvent(_player.playbackEvent));
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    playbackState.add(_transformEvent(_player.playbackEvent));
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    final session = await AudioSession.instance;
    await session.setActive(false);
    playbackState.add(_transformEvent(_player.playbackEvent));
  }
}
