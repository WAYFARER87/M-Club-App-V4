import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'offer_detail_screen.dart';
import 'offer_model.dart';

class OffersMapScreen extends StatefulWidget {
  final List<Offer> offers;
  const OffersMapScreen({super.key, required this.offers});

  @override
  State<OffersMapScreen> createState() => _OffersMapScreenState();
}

class _OffersMapScreenState extends State<OffersMapScreen> {
  late final Set<Marker> _markers;
  late final CameraPosition _initialPosition;

  @override
  void initState() {
    super.initState();
    final markers = <Marker>{};
    final points = <LatLng>[];
    for (final offer in widget.offers) {
      for (final branch in offer.branches) {
        final lat = branch.lat;
        final lng = branch.lng;
        if (lat == null || lng == null) continue;
        final markerId = MarkerId('${offer.id}_${lat}_${lng}');
        markers.add(
          Marker(
            markerId: markerId,
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: offer.title,
              snippet: branch.address,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OfferDetailScreen(offer: offer),
                  ),
                );
              },
            ),
          ),
        );
        points.add(LatLng(lat, lng));
      }
    }
    _markers = markers;
    LatLng center;
    if (points.isNotEmpty) {
      final avgLat =
          points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
      final avgLng = points
              .map((p) => p.longitude)
              .reduce((a, b) => a + b) /
          points.length;
      center = LatLng(avgLat, avgLng);
    } else {
      center = const LatLng(0, 0);
    }
    _initialPosition = CameraPosition(target: center, zoom: 12);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('На карте'),
      ),
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        markers: _markers,
      ),
    );
  }
}

