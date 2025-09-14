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

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/Radio_RE_Logo.webp',
            width: 150,
          ),
          const SizedBox(height: 16),
          if (track != null) ...[
            if (track.image.isNotEmpty)
              Image.network(
                track.image,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 8),
            Text('${track.artist} – ${track.title}',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
          ],
          if (controller.streams.isNotEmpty)
            DropdownButton<String>(
              value: controller.quality,
              items: controller.streams.keys
                  .map(
                    (q) => DropdownMenuItem(
                      value: q,
                      child: Text('$q kbps'),
                    ),
                  )
                  .toList(),
              onChanged: (q) {
                if (q != null) {
                  context.read<RadioController>().setQuality(q);
                }
              },
            ),
          const SizedBox(height: 16),
          if (controller.hasError) ...[
            const Text(
              'Playback error. Press Play to try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          ElevatedButton.icon(
            onPressed: () => context.read<RadioController>().togglePlay(),
            icon: Icon(controller.playerState.playing
                ? Icons.stop
                : Icons.play_arrow),
            label: Text(
                controller.playerState.playing ? 'Stop' : 'Play'),
          ),
        ],
      ),
    );
  }
}

