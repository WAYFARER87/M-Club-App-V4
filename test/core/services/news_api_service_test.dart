import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_club/core/services/news_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = NewsApiService();

  setUp(() {
    service.dio.interceptors.clear();
  });

  tearDown(() {
    service.dio.interceptors.clear();
  });

  test('fetchNews parses items and pagination', () async {
    service.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': [
                  {'id': 1, 'title': 'First'},
                  {'id': 2, 'title': 'Second'},
                ],
                'pagination': {
                  'page': 2,
                  'perPage': 10,
                  'total': 20,
                  'pages': 2,
                },
              },
            ),
          );
        },
      ),
    );

    final page = await service.fetchNews(page: 2, perPage: 10);
    expect(page.items, hasLength(2));
    expect(page.page, 2);
    expect(page.total, 20);
    expect(page.pages, 2);
  });

  test('fetchNews computes pages when missing', () async {
    service.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': [
                  {'id': 1, 'title': 'Only'},
                ],
                'pagination': {
                  'page': 1,
                  'perPage': 8,
                  'total': 15,
                },
              },
            ),
          );
        },
      ),
    );

    final page = await service.fetchNews(page: 1, perPage: 8);
    expect(page.items, hasLength(1));
    expect(page.page, 1);
    expect(page.total, 15);
    expect(page.pages, 2);
  });
}
