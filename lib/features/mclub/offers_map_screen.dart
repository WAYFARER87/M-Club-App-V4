import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:font_awesome_flutter/fa_icon_name_mapping.dart';

import 'offer_detail_screen.dart';
import 'offer_model.dart';
import 'category_model.dart';

class OffersMapScreen extends StatefulWidget {
  final List<dynamic> offers;
  final List<Category> categories;
  final String? selectedCategoryId;
  final double? curLat;
  final double? curLng;
  final String sortMode; // 'alphabet' | 'distance'

  const OffersMapScreen({
    super.key,
    required this.offers,
    required this.categories,
    this.selectedCategoryId,
    this.curLat,
    this.curLng,
    this.sortMode = 'alphabet',
  });

  @override
  State<OffersMapScreen> createState() => _OffersMapScreenState();
}

class _OffersMapScreenState extends State<OffersMapScreen> {
  final Set<Marker> _markers = {};
  GoogleMapController? _controller;
  String? _selectedCategoryId;
  late String _sortMode;

  final Map<String, BitmapDescriptor> _categoryIcons = {};
  final Map<String, Color> _categoryColors = {};

  static const _fallbackLat = 25.1972;
  static const _fallbackLng = 55.2744;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.selectedCategoryId;
    _sortMode = widget.sortMode;
    _initCategoryIcons().then((_) {
      _buildMarkers();
      setState(() {});
    });
  }

  Future<void> _initCategoryIcons() async {
    const colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.yellow,
    ];
    for (var i = 0; i < widget.categories.length; i++) {
      final cat = widget.categories[i];
      BitmapDescriptor descriptor = BitmapDescriptor.defaultMarker;
      final iconName = cat.faIcon;
      if (iconName != null) {
        final iconData = faIconNameMapping[iconName];
        if (iconData != null) {
          try {
            descriptor = await _bitmapDescriptorFromIconData(
              iconData,
              color: colors[i % colors.length],
            );
          } catch (_) {
            descriptor = BitmapDescriptor.defaultMarker;
          }
        }
      }
      _categoryIcons[cat.id] = descriptor;
      _categoryColors[cat.id] = colors[i % colors.length];
    }
  }

  Future<BitmapDescriptor> _bitmapDescriptorFromIconData(
    IconData iconData, {
    Color color = Colors.red,
    double size = 80,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final textSpan = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: color,
      ),
    );
    textPainter.text = textSpan;
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);
    final image = await pictureRecorder
        .endRecording()
        .toImage(textPainter.width.ceil(), textPainter.height.ceil());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  void _buildMarkers() {
    _markers.clear();
    final offers = <Offer>[];
    for (final raw in widget.offers) {
      Offer? offer;
      if (raw is Offer) {
        offer = raw;
      } else if (raw is Map<String, dynamic>) {
        offer = Offer.fromJson(raw);
      }
      if (offer == null) continue;
      if (_selectedCategoryId != null &&
          !offer.categoryIds.contains(_selectedCategoryId)) {
        continue;
      }
      offers.add(offer);
    }

    if (_sortMode == 'alphabet') {
      offers.sort((a, b) =>
          a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (_sortMode == 'distance' &&
        widget.curLat != null &&
        widget.curLng != null) {
      offers.sort((a, b) {
        final da = _nearestBranchDistanceMeters(a);
        final db = _nearestBranchDistanceMeters(b);
        return da.compareTo(db);
      });
    }

    for (final offer in offers) {
      for (var i = 0; i < offer.branches.length; i++) {
        final br = offer.branches[i];
        final lat = br.lat;
        final lng = br.lng;
        final code = br.code;
        if (lat == null || lng == null) continue;
        final rawBenefit = offer.benefitText.trim();
        const maxLen = 30;
        final snippet = rawBenefit.length > maxLen
            ? '${rawBenefit.substring(0, maxLen - 3)}...'
            : rawBenefit;
        final catId = offer.categoryIds.isNotEmpty
            ? offer.categoryIds.first
            : null;
        final icon = catId != null && _categoryIcons.containsKey(catId)
            ? _categoryIcons[catId]!
            : BitmapDescriptor.defaultMarker;
        _markers.add(
          Marker(
            markerId: MarkerId('${offer.id}_${code ?? i}'),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: offer.title,
              snippet: snippet.isEmpty ? null : snippet,
            ),
            onTap: () => _onMarkerTap(offer),
            icon: icon,
          ),
        );
      }
    }
  }

  double _nearestBranchDistanceMeters(Offer offer) {
    if (widget.curLat == null || widget.curLng == null) {
      return double.infinity;
    }
    double best = double.infinity;
    for (final br in offer.branches) {
      final lat = br.lat;
      final lng = br.lng;
      if (lat == null || lng == null) continue;
      final d = Geolocator.distanceBetween(
          widget.curLat!, widget.curLng!, lat, lng);
      if (d < best) best = d;
    }
    return best;
  }

  void _onMarkerTap(Offer offer) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: offer.photoUrl != null && offer.photoUrl!.isNotEmpty
                    ? Image.network(
                        offer.photoUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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

  void _onCategoryChanged(String? id) {
    setState(() {
      _selectedCategoryId = id;
      _buildMarkers();
    });
    if (_controller != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    }
  }

  void _openSortModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('По алфавиту'),
                onTap: () {
                  setState(() {
                    _sortMode = 'alphabet';
                    _buildMarkers();
                  });
                  Navigator.pop(context);
                  if (_controller != null) {
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _fitBounds());
                  }
                },
              ),
              ListTile(
                title: const Text('По расстоянию'),
                onTap: () {
                  setState(() {
                    _sortMode = 'distance';
                    _buildMarkers();
                  });
                  Navigator.pop(context);
                  if (_controller != null) {
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _fitBounds());
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLegend() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.categories.map((c) {
            final color = _categoryColors[c.id] ?? Colors.grey;
            return ListTile(
              leading: Icon(Icons.location_pin, color: color),
              title: Text(c.name),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, {
          'sortMode': _sortMode,
          'selectedCategoryId': _selectedCategoryId,
        });
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Предложения на карте'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Легенда',
              onPressed: _showLegend,
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Сортировка',
              onPressed: _openSortModal,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: DropdownButton<String?>(
                isExpanded: true,
                value: _selectedCategoryId,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Все категории'),
                  ),
                  ...widget.categories.map(
                    (c) => DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  ),
                ],
                onChanged: _onCategoryChanged,
              ),
            ),
            Expanded(
              child: GoogleMap(
                initialCameraPosition: _initialCamera,
                markers: _markers,
                onMapCreated: (c) {
                  _controller = c;
                  _fitBounds();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
