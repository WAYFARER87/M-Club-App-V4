import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'offer_detail_screen.dart';
import 'offer_model.dart';

class OffersMapScreen extends StatefulWidget {
  final List<Offer> offers;
  final double userLat;
  final double userLng;

  const OffersMapScreen({
    super.key,
    required this.offers,
    required this.userLat,
    required this.userLng,
  });

  @override
  State<OffersMapScreen> createState() => _OffersMapScreenState();
}

class _OffersMapScreenState extends State<OffersMapScreen> {
  GoogleMapController? _controller;

  void _showOfferCard(Offer offer) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(offer.benefitText),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OfferDetailScreen(offer: offer),
                        ),
                      );
                    },
                    child: const Text('Перейти'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{};
    for (final offer in widget.offers) {
      for (final branch in offer.branches) {
        if (branch.lat != null && branch.lng != null) {
          markers.add(
            Marker(
              markerId: MarkerId('${offer.id}_${branch.code ?? ''}'),
              position: LatLng(branch.lat!, branch.lng!),
              onTap: () => _showOfferCard(offer),
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Предложения на карте'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.userLat, widget.userLng),
          zoom: 12,
        ),
        markers: markers,
        myLocationEnabled: true,
        onMapCreated: (c) => _controller = c,
      ),
    );
  }
}
