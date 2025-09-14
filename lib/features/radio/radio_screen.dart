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
    final track = controller.track;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth * 0.6;
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            Column(
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
                      Positioned(
                        top: 8,
                        right: 8,
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
                  ],
                ),
                const SizedBox(height: 12),
                if (track != null) ...[
                  Text(
                    track.artist,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    track.title,
                    style: Theme.of(context).textTheme.titleMedium,
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
                  const Text(
                    'Playback error. Press Play to try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
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
                    onPressed: () {},
                    icon: const Icon(Icons.volume_up),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

