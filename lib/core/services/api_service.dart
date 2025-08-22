import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.mclub.ae/v4',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json', 'Accept-Language': _resolveLang(),},
    ));

    // Добавляем interceptor для токена
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  late Dio _dio;
  final _storage = const FlutterSecureStorage();

  @visibleForTesting
  Dio get dio => _dio;

  /// Запрос кода по email
  Future<void> requestCode(String email) async {
    final formData = FormData.fromMap({'email': email});
    await _dio.post('/user/request-code', data: formData);
  }

  /// Проверка кода и получение токена
  Future<bool> verifyCode(String email, String code) async {
    final formData = FormData.fromMap({'email': email, 'code': code});
    final res = await _dio.post('/user/verify-code', data: formData);

    if (res.data != null && res.data['token'] != null) {
      await _storage.write(key: 'auth_token', value: res.data['token']);
      return true;
    }
    return false;
  }

  /// Получить список категорий
  Future<List<dynamic>> fetchCategories() async {
    final res = await _dio.get('/benefits/categories');
    return res.data ?? [];
  }

  /// Получить список предложений
  Future<List<dynamic>> fetchBenefits() async {
    final res = await _dio.get('/benefits');
    return res.data ?? [];
  }

  /// Отправить голос за предложение
  /// [id] - идентификатор предложения
  /// [vote] - значение голоса: 1 (лайк) или -1 (дизлайк)
  /// Возвращает карту с актуальными значениями рейтинга и голосом пользователя
  Future<Map<String, dynamic>> voteBenefit(int id, int vote) async {
    final formData = FormData.fromMap({'id': id, 'vote': vote});
    final res = await _dio.post('/benefits/vote', data: formData);
    final data =
        res.data is Map && res.data['data'] is Map ? res.data['data'] : res.data;
    return {
      'rating': data['rating'],
      'vote': data['vote'],
    };
  }

  /// Очистить токен (логаут)
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }

  /// Проверка, есть ли сохранённый токен
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }
  String _resolveLang() {
    final code = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return code == 'ru' ? 'ru' : 'en';
  }
}
