// 서버 시각 추정 (타이머 경과 시간 표시에 쓴다)

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:momeet/core/network/timer_request.dart';

/// 서버 기준 현재 시각
///
/// 기기 시계는 틀릴 수 있으므로 타이머 REST 응답의 `Date` 헤더로 `서버 시각 - 기기 시각`을 추정해
/// [now]에 더한다. 최근 응답 5개에서 구한 값의 중앙값을 쓴다.
///
/// 테스트: test/core/network/server_clock_test.dart
class ServerClock {
  ServerClock({DateTime Function()? deviceNow})
    : _deviceNow = deviceNow ?? DateTime.now;

  final DateTime Function() _deviceNow;
  final _samples = <Duration>[];
  Duration _offset = Duration.zero;

  static const _maxSamples = 5;

  /// 서버 시각 - 기기 시각
  Duration get offset => _offset;

  /// 서버 기준 현재 시각 (UTC)
  DateTime now() => _deviceNow().toUtc().add(_offset);

  /// 요청을 [sentAt]에 보내고 [receivedAt]에 받은 응답의 `Date`([serverDate])를 반영한다.
  ///
  /// `Date`는 초 단위로 잘려 있으므로 0.5초를 더해 요청·응답의 가운데 시각과 비교한다.
  void addSample({
    required DateTime serverDate,
    required DateTime sentAt,
    required DateTime receivedAt,
  }) {
    final midpoint = sentAt.add(receivedAt.difference(sentAt) ~/ 2);
    _samples.add(
      serverDate.add(const Duration(milliseconds: 500)).difference(midpoint),
    );
    if (_samples.length > _maxSamples) _samples.removeAt(0);
    final sorted = [..._samples]..sort();
    _offset = sorted[sorted.length ~/ 2];
  }
}

/// [timerRequest]로 표시한 요청의 응답 `Date` 헤더를 [ServerClock]에 넘기는 Interceptor.
///
/// 헤더가 없거나 형식이 맞지 않는 응답은 건너뛰고, 요청은 그대로 진행한다.
/// 보낸 시각을 요청 직전에 재므로 Interceptor 중 마지막에 붙인다.
class ServerClockInterceptor extends Interceptor {
  ServerClockInterceptor(this._clock);

  final ServerClock _clock;

  static const _sentAtKey = 'serverClockSentAt';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (isTimerRequest(options)) {
      options.extra[_sentAtKey] = DateTime.now();
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final sentAt = response.requestOptions.extra[_sentAtKey];
    final serverDate = _parseDate(response.headers.value('date'));
    if (sentAt is DateTime && serverDate != null) {
      _clock.addSample(
        serverDate: serverDate,
        sentAt: sentAt,
        receivedAt: DateTime.now(),
      );
    }
    handler.next(response);
  }

  /// RFC 1123 형식이 아니면 null
  static DateTime? _parseDate(String? value) {
    if (value == null) return null;
    try {
      return parseHttpDate(value);
    } on FormatException {
      return null;
    }
  }
}

/// 앱 전체가 함께 쓰는 [ServerClock]
final serverClockProvider = Provider<ServerClock>((ref) => ServerClock());
