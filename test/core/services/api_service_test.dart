import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_club/core/services/api_service.dart';
import 'package:m_club/features/auth/user_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('voteBenefit returns actual rating and vote', () async {
    final service = ApiService();
    service.dio.interceptors.clear();
    service.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.data, isA<FormData>());
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': {'rating': 10, 'vote': -1}
              },
            ),
          );
        },
      ),
    );

    final result = await service.voteBenefit(123, -1);
    expect(result, {'rating': 10, 'vote': -1});

    service.dio.interceptors.clear();
  });

  test('fetchProfile parses response into UserProfile', () async {
    final service = ApiService();
    service.dio.interceptors.clear();
    service.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'GET');
          expect(options.path, '/user/profile');
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'card_num': '123',
                'expire_date': '01/30',
                'user_id': 1,
                'name': 'John',
                'lastname': 'Doe',
                'phone': '555',
                'email': 'john@example.com',
                'login': 'john',
                'is_verified_phone': 1,
                'is_verified_email': 1,
                'is_uae_resident': 0,
                'lang': 'en',
              },
            ),
          );
        },
      ),
    );

    final profile = await service.fetchProfile();
    expect(profile, isA<UserProfile>());
    expect(profile.name, 'John');
    expect(profile.lastname, 'Doe');
    expect(profile.isVerifiedEmail, true);

    service.dio.interceptors.clear();
  });

  test('updateProfile sends only provided fields and returns profile',
      () async {
    final service = ApiService();
    service.dio.interceptors.clear();
    service.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'PATCH');
          expect(options.path, '/user/profile');
          expect(options.data, {'name': 'Jane'});
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'card_num': '123',
                'expire_date': '01/30',
                'user_id': 1,
                'name': 'Jane',
                'lastname': 'Doe',
                'phone': '555',
                'email': 'john@example.com',
                'login': 'john',
                'is_verified_phone': 1,
                'is_verified_email': 0,
                'is_uae_resident': 0,
                'lang': 'en',
              },
            ),
          );
        },
      ),
    );

    final profile = await service.updateProfile(name: 'Jane');
    expect(profile, isA<UserProfile?>());
    expect(profile?.name, 'Jane');

    service.dio.interceptors.clear();
  });

  test('updateProfile throws DioException on error status', () async {
    final service = ApiService();
    service.dio.interceptors.clear();
    service.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 400,
            ),
          );
        },
      ),
    );

    expect(
      () => service.updateProfile(name: 'Fail'),
      throwsA(isA<DioException>()),
    );

    service.dio.interceptors.clear();
  });
}
