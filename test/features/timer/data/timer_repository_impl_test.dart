import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/network/timer_request.dart';
import 'package:momeet/features/timer/data/timer_repository_impl.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../helpers/timer_fixtures.dart';

/// 받은 요청을 기록하고, 목록 GET에는 빈 목록·공유 설정에는 친구 공개 설정·그 외에는 타이머 하나로 응답하는 백엔드
class _FakeBackend implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  /// 공유 설정 요청에 답할 상태 코드
  int visibilityStatus = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final visibility = options.path.startsWith('/v1/visibility/');
    final body = visibility
        ? makeVisibility(timerId: 't1', level: VisibilityLevel.friends).toJson()
        : options.method == 'GET' && options.path == '/v1/timers'
        ? <Object>[]
        : makeTimer(id: 't1', status: TimerStatus.running).toJson();
    return ResponseBody.fromString(
      jsonEncode(body),
      visibility ? visibilityStatus : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

TimerRepositoryImpl _repository(_FakeBackend backend) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
    ..httpClientAdapter = backend;
  return TimerRepositoryImpl(TimersClient(dio), VisibilityClient(dio));
}

void main() {
  test('모든 요청이 타이머 요청 표시를 달고 나간다', () async {
    final backend = _FakeBackend();
    final repository = _repository(backend);

    await repository.getTimerHistory();
    await repository.listTimers();
    await repository.getTimer('t1');
    await repository.createTimer(const TimerCreate(allocatedDuration: 60));
    await repository.pauseTimer('t1');
    await repository.resumeTimer('t1');
    await repository.stopTimer('t1');
    await repository.updateTimer('t1', const TimerUpdate(title: '제목'));
    await repository.deleteTimer('t1');
    await repository.listSharedTimers();

    expect(backend.requests, hasLength(10));
    expect(
      backend.requests
          .where((r) => !isTimerRequest(r))
          .map((r) => '${r.method} ${r.path}'),
      isEmpty,
    );
  });

  test('타이머를 돌려주는 요청은 모두 일정·Todo를 포함해 받는다', () async {
    final backend = _FakeBackend();
    final repository = _repository(backend);

    await repository.getTimerHistory();
    await repository.listTimers();
    await repository.getTimer('t1');
    await repository.createTimer(const TimerCreate(allocatedDuration: 60));
    await repository.pauseTimer('t1');
    await repository.resumeTimer('t1');
    await repository.stopTimer('t1');
    await repository.updateTimer('t1', const TimerUpdate(title: '제목'));
    await repository.listSharedTimers();

    expect(backend.requests, hasLength(9));
    expect(
      backend.requests
          .where(
            (r) =>
                r.queryParameters['include_schedule'] != true ||
                r.queryParameters['include_todo'] != true,
          )
          .map((r) => '${r.method} ${r.path}'),
      isEmpty,
    );
  });

  group('공유', () {
    late _FakeBackend backend;
    late TimerRepositoryImpl repository;

    setUp(() {
      backend = _FakeBackend();
      repository = _repository(backend);
    });

    test('공유받은 타이머는 scope=shared로 읽는다', () async {
      await repository.listSharedTimers();

      final request = backend.requests.single;
      expect('${request.method} ${request.path}', 'GET /v1/timers');
      expect(request.uri.queryParameters['scope'], 'shared');
      expect(request.uri.queryParameters, isNot(contains('status')));
    });

    test('공유 설정은 그 타이머의 설정을 읽는다', () async {
      final visibility = await repository.getVisibility('t1');

      final request = backend.requests.single;
      expect(
        '${request.method} ${request.path}',
        'GET /v1/visibility/timer/t1',
      );
      expect(visibility?.level, VisibilityLevel.friends);
    });

    test('공유 설정이 없으면(404) null이다', () async {
      backend.visibilityStatus = 404;

      expect(await repository.getVisibility('t1'), isNull);
    });

    test('404가 아닌 오류는 그대로 던진다', () async {
      backend.visibilityStatus = 500;

      await expectLater(
        repository.getVisibility('t1'),
        throwsA(isA<DioException>()),
      );
    });

    for (final (update, body) in [
      (
        const VisibilityUpdate(level: VisibilityLevel.friends),
        {'level': 'friends'},
      ),
      (
        const VisibilityUpdate(level: VisibilityLevel.public),
        {'level': 'public'},
      ),
      (
        const VisibilityUpdate(
          level: VisibilityLevel.selected,
          allowedUserIds: ['u1', 'u2'],
        ),
        {
          'level': 'selected',
          'allowed_user_ids': ['u1', 'u2'],
        },
      ),
      (
        const VisibilityUpdate(
          level: VisibilityLevel.allowedEmails,
          allowedEmails: ['a@example.com'],
          allowedDomains: ['example.org'],
        ),
        {
          'level': 'allowed_emails',
          'allowed_emails': ['a@example.com'],
          'allowed_domains': ['example.org'],
        },
      ),
    ]) {
      test('${update.level.json} 공유 설정은 받은 목록만 PUT으로 보낸다', () async {
        final saved = await repository.setVisibility('t1', update);

        final request = backend.requests.single;
        expect(
          '${request.method} ${request.path}',
          'PUT /v1/visibility/timer/t1',
        );
        // 보내는 JSON 본문
        expect(jsonDecode(jsonEncode(request.data)), body);
        expect(saved.resourceId, 't1');
      });
    }

    test('공유 설정을 지우면 DELETE로 보낸다', () async {
      await repository.clearVisibility('t1');

      final request = backend.requests.single;
      expect(
        '${request.method} ${request.path}',
        'DELETE /v1/visibility/timer/t1',
      );
    });
  });
}
