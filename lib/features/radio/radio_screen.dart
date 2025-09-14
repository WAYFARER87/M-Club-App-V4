import 'dart:math' as math;
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
    final artist =
        track?.artist ?? 'Радио «Русские Эмираты»';
    final title =
        track?.title ?? 'По-русски про Эмираты!';
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = math.min(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    ) *
                    0.8;
                return Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24)),
                            child: SizedBox(
                              width: size,
                              height: size,
                              child: track != null && track.image.isNotEmpty
                                  ? Image.network(
                                      track.image,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      'assets/images/Radio_RE_Logo.webp',
                                      fit: BoxFit.contain,
                                    ),
                            ),
                          ),
                          if (controller.quality != null)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: SizedBox(
                                child: Material(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (context) {
                                          return SafeArea(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: controller.streams.keys
                                                  .map((quality) => ListTile(
                                                        title: Text(quality),
                                                        trailing: controller
                                                                    .quality ==
                                                                quality
                                                            ? const Icon(
                                                                Icons.check)
                                                            : null,
                                                        onTap: () {
                                                          controller.setQuality(
                                                              quality);
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                      ))
                                                  .toList(),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: Container(
                                      constraints:
                                          const BoxConstraints(minHeight: 44),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      child: Center(
                                        child: Text(
                                          controller.quality!,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (controller.hasError) ...[
                        Chip(
                          label: const Text('ERROR'),
                          labelStyle: const TextStyle(color: Colors.white),
                          backgroundColor: Colors.red,
                        ),
                        TextButton(
                          onPressed: () =>
                              context.read<RadioController>().retry(),
                          child: const Text('Повторить'),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        artist,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                      const SizedBox(height: 12),
                      if (track != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SizedBox(
              width: double.infinity,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(20),
                            minimumSize: const Size(64, 64),
                          ),
                          onPressed: () =>
                              context.read<RadioController>().togglePlay(),
                          child: controller.isConnecting ||
                                  controller.isBuffering
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  controller.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                ),
                        ),
                        if (controller.isConnecting)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text('Подключаемся…'),
                          ),
                        if (controller.isBuffering)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text('Буферизация…'),
                          ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0.5, 0),
                    child: IconButton(
                      constraints:
                          const BoxConstraints(minWidth: 44, minHeight: 44),
                      onPressed: controller.isConnecting ||
                              controller.isBuffering
                          ? null
                          : () => context.read<RadioController>().toggleMute(),
                      icon: Icon(
                        controller.volume == 0
                            ? Icons.volume_off
                            : Icons.volume_up,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
