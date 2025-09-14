import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:m_club/features/radio/radio_controller.dart';

class RadioScreen extends StatelessWidget {
  const RadioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RadioController()..init(),
      child: const _RadioView(),
    );
  }
}

class _RadioView extends StatelessWidget {
  const _RadioView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RadioController>();
    if (controller.streamsUnavailable) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Radio streams are currently unavailable. Please try again later.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => controller.init(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final track = controller.track;
    final size = MediaQuery.of(context).size.width * 0.6;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: track != null && track.image.isNotEmpty
                                ? NetworkImage(track.image)
                                : const AssetImage(
                                        'assets/images/Radio_RE_Logo.webp')
                                    as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (controller.quality != null)
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              onSelected: (quality) {
                                controller.setQuality(quality);
                              },
                              itemBuilder: (context) {
                                return controller.streams.keys
                                    .map((quality) => PopupMenuItem<String>(
                                          value: quality,
                                          child: Text('HQ $quality'),
                                        ))
                                    .toList();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'HQ ${controller.quality}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (track != null) ...[
                    Text(
                      track.artist,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.title,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (controller.hasError) ...[
                    Text(
                      controller.errorMessage ??
                          'Playback error. Press Play to try again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: () =>
                      context.read<RadioController>().togglePlay(),
                  child: Icon(
                    controller.playerState.playing
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => _showVolumeDialog(context),
                  icon: Icon(
                    controller.volume == 0
                        ? Icons.volume_off
                        : Icons.volume_up,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showVolumeDialog(BuildContext context) {
    final controller = context.read<RadioController>();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Volume'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: controller.volume,
                    onChanged: (value) {
                      controller.setVolume(value);
                      setState(() {});
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      controller.volume == 0
                          ? Icons.volume_off
                          : Icons.volume_up,
                    ),
                    onPressed: () {
                      controller.toggleMute();
                      setState(() {});
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

