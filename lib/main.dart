import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'm_club_radio_channel',
    androidNotificationChannelName: 'M-Club Radio',
    androidNotificationIcon: 'assets/images/Radio_RE_Logo.webp',
    androidNotificationOngoing: true,
  );
  runApp(const MyApp());
}
