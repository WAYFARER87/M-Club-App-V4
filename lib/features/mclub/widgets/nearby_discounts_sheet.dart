import 'dart:math';

import 'package:flutter/material.dart';

class NearbyDiscountsSheet extends StatelessWidget {
  final List<dynamic> offers;
  final VoidCallback? onShowAll;

  const NearbyDiscountsSheet({
    super.key,
    required this.offers,
    this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    const itemHeight = 72.0;
    const headerHeight = 64.0;
    const actionsHeight = 120.0;
    final visibleItems = min(offers.length, 3);
    final contentHeight =
        headerHeight + actionsHeight + itemHeight * visibleItems;
    final height = min(contentHeight, MediaQuery.of(context).size.height);

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Рядом есть скидки!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: offers.length,
              itemBuilder: (context, index) {
                final offer = offers[index];
                final photo = (offer['photo_url'] ?? '').toString();
                final title = (offer['title'] ?? '').toString();
                final benefit = (offer['benefit'] ?? '').toString();
                return ListTile(
                  leading: photo.isNotEmpty
                      ? Image.network(
                          photo,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            color: Colors.grey.shade200,
                          ),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey.shade200,
                        ),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    benefit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onShowAll,
                      child: const Text('Показать все'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Закрыть'),
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

