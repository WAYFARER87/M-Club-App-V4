// lib/features/uae_unlocked/recommendation_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../core/services/api_service.dart';
import 'recommendation_model.dart';

class RecommendationDetailScreen extends StatefulWidget {
  final Recommendation recommendation;
  const RecommendationDetailScreen({super.key, required this.recommendation});

  @override
  State<RecommendationDetailScreen> createState() => _RecommendationDetailScreenState();
}

class _RecommendationDetailScreenState extends State<RecommendationDetailScreen> {
  final _api = ApiService();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.recommendation.isFavorite;
  }

  Future<void> _toggleFavorite() async {
    final id = int.tryParse(widget.recommendation.id);
    if (id == null) return;
    setState(() => _isFavorite = !_isFavorite);
    try {
      await _api.toggleFavorite(id);
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final rec = widget.recommendation;
    final image = rec.photoUrl;
    return Scaffold(
      appBar: AppBar(
        title: Text(rec.title),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: ListView(
        children: [
          if (image != null && image.isNotEmpty)
            Image.network(
              image,
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Html(data: rec.descriptionHtml),
          ),
        ],
      ),
    );
  }
}
