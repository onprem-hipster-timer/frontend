import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/core/network/dio_provider.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/my_profile_provider.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../helpers/fake_rest_clients.dart';
import '../../helpers/kratos_mocks.dart';

/// 백엔드 역할: 요청을 기록하고 [statuses] 순서대로 [body]로 응답한다 (마지막 값은 반복)
class _FakeBackend implements HttpClientAdapter {
  _FakeBackend(this.statuses, {this.body = '{}'});

  final List<int> statuses;
  final String body;
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
      body,
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

  Future<(ProviderContainer, Dio)> boot(
    _FakeBackend backend, {
    FakeUsersClient? users,
  }) async {
    final container = ProviderContainer(
      overrides: [
        ...harness.overrides,
        if (users != null) usersApiProvider.overrideWithValue(users),
      ],
    );
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

  group('탈퇴 대기 중이라 거절되면', () {
    const pendingBody = '{"detail": "account_deletion_pending"}';
    late FakeUsersClient users;

    /// 탈퇴 전 프로필을 받아 둔 뒤, 다른 곳에서 탈퇴를 신청한 상태로 만든다.
    Future<(ProviderContainer, Dio)> bootSignedIn(_FakeBackend backend) async {
      harness = await KratosTestHarness.create();
      users = FakeUsersClient(consentRequired: false);
      final (container, dio) = await boot(backend, users: users);
      await container.read(myProfileProvider.future);
      users.profile = FakeUsersClient(
        consentRequired: false,
        deletionPending: true,
      ).profile;
      return (container, dio);
    }

    test('오류는 그대로 내고 프로필을 다시 받아 탈퇴 대기가 된다', () async {
      final backend = _FakeBackend([403], body: pendingBody);
      final (container, dio) = await bootSignedIn(backend);
      expect(container.read(deletionPendingProvider), isFalse);

      await expectLater(
        dio.get<dynamic>('/v1/todos'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            403,
          ),
        ),
      );
      await pumpEventQueue();

      expect(backend.requests, hasLength(1));
      expect(users.reads, 2);
      expect(container.read(deletionPendingProvider), isTrue);
    });

    test('여러 요청이 한꺼번에 거절돼도 프로필은 한 번만 다시 받는다', () async {
      final backend = _FakeBackend([403], body: pendingBody);
      final (container, dio) = await bootSignedIn(backend);
      final gate = Completer<void>();
      users.readGate = gate.future;

      await Future.wait([
        for (var i = 0; i < 3; i++)
          dio.get<dynamic>('/v1/todos').then((_) {}, onError: (_) {}),
      ]);
      await pumpEventQueue();
      // 다시 받는 동안에는 지금 프로필을 그대로 둔다 (불러오는 중으로 바뀌어 화면이 흔들리지 않게)
      expect(container.read(deletionPendingProvider), isFalse);
      gate.complete();
      await pumpEventQueue();

      expect(users.reads, 2);
      expect(container.read(deletionPendingProvider), isTrue);
    });

    test('다른 403은 프로필을 다시 받지 않는다', () async {
      final backend = _FakeBackend([403], body: '{"detail": "forbidden"}');
      final (container, dio) = await bootSignedIn(backend);

      await expectLater(
        dio.get<dynamic>('/v1/todos'),
        throwsA(isA<DioException>()),
      );
      await pumpEventQueue();

      expect(users.reads, 1);
      expect(container.read(deletionPendingProvider), isFalse);
    });

    test('프로필을 다시 받지 못하면 모르는 상태가 되어 보호된 페이지를 닫는다', () async {
      final backend = _FakeBackend([403], body: pendingBody);
      final (container, dio) = await bootSignedIn(backend);
      users.readError = httpError('/v1/users/me', 500);

      await expectLater(
        dio.get<dynamic>('/v1/todos'),
        throwsA(isA<DioException>()),
      );
      await pumpEventQueue();

      expect(container.read(deletionPendingProvider), isNull);
      expect(container.read(consentRequiredProvider), isNull);
    });
  });
}
