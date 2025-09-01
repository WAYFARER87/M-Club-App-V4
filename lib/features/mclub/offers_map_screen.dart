import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'offer_detail_screen.dart';
import 'offer_model.dart';

class OffersMapScreen extends StatefulWidget {
  final List<dynamic> offers;

  const OffersMapScreen({super.key, required this.offers});

  @override
  State<OffersMapScreen> createState() => _OffersMapScreenState();
}

class _OffersMapScreenState extends State<OffersMapScreen> {
  final Set<Marker> _markers = {};
  GoogleMapController? _controller;

  static const _fallbackLat = 25.1972;
  static const _fallbackLng = 55.2744;

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  void _buildMarkers() {
    for (final raw in widget.offers) {
      Offer? offer;
      if (raw is Offer) {
        offer = raw;
      } else if (raw is Map<String, dynamic>) {
        offer = Offer.fromJson(raw);
      }
      if (offer == null) continue;
      final Offer mappedOffer = offer;

      for (var i = 0; i < mappedOffer.branches.length; i++) {
        final br = mappedOffer.branches[i];
        final lat = br.lat;
        final lng = br.lng;
        final code = br.code;
        if (lat == null || lng == null) continue;
        _markers.add(
          Marker(
            markerId: MarkerId('${mappedOffer.id}_${code ?? i}'),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: mappedOffer.title),
            onTap: () => _onMarkerTap(mappedOffer),
          ),
        );
      }
    }
  }

  void _onMarkerTap(Offer offer) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(offer.title, style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(offer.descriptionShort),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OfferDetailScreen(offer: offer),
                    ),
                  );
                },
                child: const Text('Подробнее'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CameraPosition get _initialCamera {
    if (_markers.isNotEmpty) {
      final first = _markers.first.position;
      return CameraPosition(target: first, zoom: 10);
    }
    return const CameraPosition(
      target: LatLng(_fallbackLat, _fallbackLng),
      zoom: 10,
    );
  }

  void _fitBounds() {
    if (_controller == null || _markers.isEmpty) return;
    double? minLat, maxLat, minLng, maxLng;
    for (final m in _markers) {
      minLat = min(minLat ?? m.position.latitude, m.position.latitude);
      maxLat = max(maxLat ?? m.position.latitude, m.position.latitude);
      minLng = min(minLng ?? m.position.longitude, m.position.longitude);
      maxLng = max(maxLng ?? m.position.longitude, m.position.longitude);
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
    _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Предложения на карте')),
      body: GoogleMap(
        initialCameraPosition: _initialCamera,
        markers: _markers,
        onMapCreated: (c) {
          _controller = c;
          _fitBounds();
        },
      ),
    );
  }
}
