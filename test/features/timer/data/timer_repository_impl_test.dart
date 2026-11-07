import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/network/timer_request.dart';
import 'package:momeet/features/timer/data/timer_repository_impl.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../helpers/timer_fixtures.dart';

/// 받은 요청을 기록하고, GET에는 빈 목록·그 외에는 타이머 하나로 응답하는 백엔드
class _FakeBackend implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = options.method == 'GET'
        ? <Object>[]
        : makeTimer(id: 't1', status: TimerStatus.running).toJson();
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('모든 요청이 타이머 요청 표시를 달고 나간다', () async {
    final backend = _FakeBackend();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
      ..httpClientAdapter = backend;
    final repository = TimerRepositoryImpl(TimersClient(dio));

    await repository.getTimerHistory();
    await repository.listTimers();
    await repository.createTimer(const TimerCreate(allocatedDuration: 60));
    await repository.pauseTimer('t1');
    await repository.resumeTimer('t1');
    await repository.stopTimer('t1');
    await repository.updateTimer('t1', const TimerUpdate(title: '제목'));
    await repository.deleteTimer('t1');

    expect(backend.requests, hasLength(8));
    expect(
      backend.requests
          .where((r) => !isTimerRequest(r))
          .map((r) => '${r.method} ${r.path}'),
      isEmpty,
    );
  });
}
