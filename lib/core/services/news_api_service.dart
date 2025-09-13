import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:m_club/features/news/models/news_category.dart';
import 'package:m_club/features/news/models/news_item.dart';
import 'package:m_club/features/news/models/news_page.dart';

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

  /// Получить список новостей
  Future<NewsPage> fetchNews({
    int page = 1,
    int perPage = 20,
    String? categoryId,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per-page': perPage,
    };
    if (categoryId != null) {
      params['category_id'] = categoryId;
    }

    final res = await _dio.get('/news/', queryParameters: params);
    final raw = res.data;
    final data = raw is Map && raw['data'] is Map ? raw['data'] : raw;

    final rawItems = data is Map && data['items'] is List
        ? data['items']
        : (data is List ? data : []);
    final items = <NewsItem>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          items.add(NewsItem.fromJson(item));
        }
      }
    }

    final pageNum =
        data is Map && data['page'] is num ? (data['page'] as num).toInt() : page;
    final pages = data is Map && data['pages'] is num
        ? (data['pages'] as num).toInt()
        : 1;
    final total = data is Map && data['total'] is num
        ? (data['total'] as num).toInt()
        : items.length;

    return NewsPage(items: items, page: pageNum, pages: pages, total: total);
  }

  String _resolveLang() {
    final code = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return code == 'ru' ? 'ru' : 'en';
  }
}

