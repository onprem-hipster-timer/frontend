import 'package:dio/dio.dart' show DioException, DioExceptionType;
import 'package:momeet/core/network/turnstile_request.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/shared/api/kratos/kratos_models.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 게스트 단계(이름 찾기·생성·로그인·이름 바꾸기·자기 삭제)가 거절된 까닭
enum GuestRefusal {
  /// 비밀번호가 틀렸다 (Kratos 4000006)
  wrongPassword,

  /// 이 모임에 같은 이름의 게스트가 있다
  nameTaken,

  /// 모임이 지금 게스트를 받지 않는다 (게스트 허용·공개를 껐거나 게스트 기간이 끝났다)
  closed,

  /// 모임의 게스트가 100명이다
  full,

  /// 약관 버전이 그 사이 바뀌었다
  consentChanged,

  /// 사람인지 확인을 통과하지 못했다 (토큰 거절)
  verificationFailed,

  /// 확인 상자를 불러오지 못했거나 서버가 확인할 수 없다
  verificationUnavailable,

  /// 요청 한도를 넘었다
  tooManyRequests,

  /// 이름에 쓸 수 없는 글자가 있다
  invalidName,

  network,
  unknown;

  /// [error]가 어느 거절인지 가린다. `/v1/guests/*`(DioException), `/auth`(KratosException), 확인 위젯
  static GuestRefusal of(Object error) => switch (error) {
    TurnstileException(status: TurnstileStatus.failed) => verificationFailed,
    TurnstileException() => verificationUnavailable,
    KratosException() => _ofKratos(error),
    DioException() => _ofApi(error),
    _ => unknown,
  };

  static GuestRefusal _ofKratos(KratosException error) {
    if (error.statusCode == 429) return tooManyRequests;
    return switch (error.errorId) {
      'guest_verification_failed' => verificationFailed,
      'guest_verification_unavailable' => verificationUnavailable,
      'guest_name_taken' => nameTaken,
      _ when error.statusCode >= 500 => verificationUnavailable,
      _ => switch (error.messageId) {
        4000006 => wrongPassword,
        // 로그인·설정 훅의 거절: 게스트가 없거나 모임이 게스트를 받지 않는다
        4000001 => closed,
        _ => unknown,
      },
    };
  }

  static GuestRefusal _ofApi(DioException error) {
    final response = error.response;
    if (response == null) {
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError => network,
        _ => unknown,
      };
    }
    final data = response.data;
    final type = data is Map ? data['error_type'] : null;
    return switch ((response.statusCode, type)) {
      (429, _) => tooManyRequests,
      (_, 'GuestEntryRefusedError') => closed,
      (_, 'GuestVerificationFailedError') => verificationFailed,
      (_, 'GuestNameTakenError') => nameTaken,
      (_, 'GuestLimitReachedError') => full,
      (_, 'ConsentVersionMismatchError') => consentChanged,
      (503, _) => verificationUnavailable,
      (422, _) => invalidName,
      _ => unknown,
    };
  }
}

/// [error]를 게스트에게 보일 한 문장으로 바꾼다. 429면 다시 보낼 수 있을 때까지의 초를 함께 쓴다
String guestRefusalText(Object error) => switch (GuestRefusal.of(error)) {
  GuestRefusal.wrongPassword => '비밀번호가 맞지 않습니다',
  GuestRefusal.nameTaken => '이 ${Terms.meeting}에 같은 이름이 있습니다. 다른 이름을 입력해 주세요',
  GuestRefusal.closed => '지금은 이 ${Terms.meeting}에 게스트로 들어갈 수 없습니다',
  GuestRefusal.full =>
    '이 ${Terms.meeting.withJosa('은', '는')} 게스트가 100명이라 더 들어올 수 없습니다',
  GuestRefusal.consentChanged => '약관이 바뀌었습니다. 바뀐 내용을 확인하고 다시 동의해 주세요',
  GuestRefusal.verificationFailed => '사람인지 확인하지 못했습니다. 다시 시도해 주세요',
  GuestRefusal.verificationUnavailable => '지금은 확인할 수 없습니다. 잠시 뒤 다시 시도해 주세요',
  GuestRefusal.tooManyRequests => switch (_retryAfter(error)) {
    final wait? => '요청이 너무 많습니다. ${wait.inSeconds}초 뒤 다시 시도해 주세요',
    null => '요청이 너무 많습니다. 잠시 뒤 다시 시도해 주세요',
  },
  GuestRefusal.invalidName => '이름에 쓸 수 없는 글자가 있습니다',
  GuestRefusal.network => '네트워크 연결을 확인해 주세요',
  GuestRefusal.unknown => '처리하지 못했습니다. 잠시 뒤 다시 시도해 주세요',
};

Duration? _retryAfter(Object error) => switch (error) {
  KratosException(:final retryAfter) => retryAfter,
  DioException(:final response) => retryAfterOf(response),
  _ => null,
};
