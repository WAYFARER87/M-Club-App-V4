import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:m_club/features/news/models/news_category.dart';

class NewsApiService {
  static final NewsApiService _instance = NewsApiService._internal();
  factory NewsApiService() => _instance;
  NewsApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://russianemirates.com/api/v4',
        headers: {
          'Content-Type': 'application/json',
          'Accept-Language': _resolveLang(),
        },
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

  late Dio _dio;

  /// Получить список новостных лент (feeds)
  Future<List<NewsCategory>> fetchFeeds() async {
    final res = await _dio.get('/news/feeds/');
    final raw = res.data;
    final data = raw is Map && raw['data'] is List ? raw['data'] : raw;

    final categories = <NewsCategory>[];
    if (data is List) {
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          categories.add(NewsCategory.fromJson(item));
        }
      }
    } else if (data is Map) {
      for (final item in data.values) {
        if (item is Map<String, dynamic>) {
          categories.add(NewsCategory.fromJson(item));
        }
      }
    }
    return categories;
  }

  String _resolveLang() {
    final code = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return code == 'ru' ? 'ru' : 'en';
  }
}

