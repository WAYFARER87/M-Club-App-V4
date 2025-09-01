import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    var id = 0;
    for (final rawOffer in widget.offers) {
      String title;
      Iterable<dynamic> branches;
      if (rawOffer is Offer) {
        title = rawOffer.title;
        branches = rawOffer.branches;
      } else if (rawOffer is Map<String, dynamic>) {
        title = (rawOffer['title'] ?? '').toString();
        branches = rawOffer['branches'] as List<dynamic>? ?? const [];
      } else {
        continue;
      }

      for (final br in branches) {
        double? lat;
        double? lng;
        if (br is Branch) {
          lat = br.lat;
          lng = br.lng;
        } else if (br is Map<String, dynamic>) {
          lat = double.tryParse((br['lattitude'] ?? '').toString());
          lng = double.tryParse((br['longitude'] ?? '').toString());
        }
        if (lat == null || lng == null) continue;
        _markers.add(
          Marker(
            markerId: MarkerId('m${id++}'),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: title),
          ),
        );
      }
    }
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
