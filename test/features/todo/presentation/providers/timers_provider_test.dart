import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/network/timer_request.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

void main() {
  test('타이머 목록 조회는 타이머 요청 표시를 달고 나간다', () async {
    final sent = <RequestOptions>[];
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            sent.add(options);
            handler.resolve(
              Response(requestOptions: options, data: <Object>[]),
            );
          },
        ),
      );
    final container = ProviderContainer(
      overrides: [timersApiProvider.overrideWithValue(TimersClient(dio))],
    );
    addTearDown(container.dispose);

    await container.read(timersProvider().future);

    expect(sent.single.path, '/v1/timers');
    expect(isTimerRequest(sent.single), isTrue);
  });
}
