import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/core/network/dio_provider.dart';
import 'package:momeet/core/providers/auth_provider.dart';

import '../../helpers/kratos_mocks.dart';

/// 백엔드 역할: 요청을 기록하고 [statuses] 순서대로 응답한다 (마지막 값은 반복)
class _FakeBackend implements HttpClientAdapter {
  _FakeBackend(this.statuses);

  final List<int> statuses;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final status = statuses.length > 1 ? statuses.removeAt(0) : statuses.first;
    return ResponseBody.fromString(
      '{}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final _testDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  dio.interceptors.add(AuthInterceptor(ref, dio));
  return dio;
});

void main() {
  late KratosTestHarness harness;

  setUpAll(registerKratosFallbacks);

  Future<(ProviderContainer, Dio)> boot(_FakeBackend backend) async {
    final container = ProviderContainer(overrides: harness.overrides);
    addTearDown(container.dispose);
    container.read(authProvider);
    await pumpEventQueue();
    final dio = container.read(_testDioProvider)..httpClientAdapter = backend;
    return (container, dio);
  }

  String? authorization(RequestOptions options) =>
      options.headers['Authorization'] as String?;

  test('요청에 지금 JWT를 붙인다', () async {
    harness = await KratosTestHarness.create();
    final backend = _FakeBackend([200]);
    final (_, dio) = await boot(backend);

    await dio.get<dynamic>('/v1/users/me');

    expect(
      authorization(backend.requests.single),
      'Bearer ${harness.accessToken}',
    );
  });

  test('만료가 가까운 JWT는 요청 전에 새로 받는다', () async {
    harness = await KratosTestHarness.create(
      accessTokenExpiresIn: const Duration(seconds: 30),
    );
    final backend = _FakeBackend([200]);
    final (_, dio) = await boot(backend);
    final renewed = testJwt();
    harness.accessToken = renewed;

    await dio.get<dynamic>('/v1/users/me');

    expect(authorization(backend.requests.single), 'Bearer $renewed');
  });

  test('미인증이면 Authorization 없이 보낸다', () async {
    harness = await KratosTestHarness.create(authenticated: false);
    final backend = _FakeBackend([200]);
    final (_, dio) = await boot(backend);

    await dio.get<dynamic>('/v1/holidays');

    expect(authorization(backend.requests.single), isNull);
  });

  test('401이면 JWT를 한 번 새로 받아 재시도한다', () async {
    harness = await KratosTestHarness.create();
    final backend = _FakeBackend([401, 200]);
    final (_, dio) = await boot(backend);
    final renewed = testJwt();
    harness.accessToken = renewed;

    final response = await dio.get<dynamic>('/v1/users/me');

    expect(response.statusCode, 200);
    expect(backend.requests, hasLength(2));
    expect(authorization(backend.requests.last), 'Bearer $renewed');
  });

  test('재시도도 401이면 더 시도하지 않고 오류를 낸다', () async {
    harness = await KratosTestHarness.create();
    final backend = _FakeBackend([401, 401]);
    final (container, dio) = await boot(backend);

    await expectLater(
      dio.get<dynamic>('/v1/users/me'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
    expect(backend.requests, hasLength(2));
    expect(container.read(isAuthenticatedProvider), isTrue);
  });

  test('세션이 끝났으면 재시도하지 않고 미인증이 된다', () async {
    harness = await KratosTestHarness.create();
    final backend = _FakeBackend([401]);
    final (container, dio) = await boot(backend);
    when(() => harness.kratos.whoami(any())).thenAnswer((_) async => null);

    await expectLater(
      dio.get<dynamic>('/v1/users/me'),
      throwsA(isA<DioException>()),
    );
    expect(backend.requests, hasLength(1));
    expect(container.read(isAuthenticatedProvider), isFalse);
  });

  test('JWT를 받지 못하면 요청을 보내지 않는다', () async {
    harness = await KratosTestHarness.create(
      accessTokenExpiresIn: const Duration(seconds: 30),
    );
    final backend = _FakeBackend([200]);
    final (_, dio) = await boot(backend);
    when(() => harness.kratos.whoami(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/sessions/whoami'),
        type: DioExceptionType.connectionError,
      ),
    );

    await expectLater(
      dio.get<dynamic>('/v1/users/me'),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.connectionError,
        ),
      ),
    );
    expect(backend.requests, isEmpty);
  });
}
