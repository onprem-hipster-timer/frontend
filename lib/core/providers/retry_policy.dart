import 'package:dio/dio.dart';

/// 네트워크가 잠깐 끊겨 실패한 불러오기는 0.5초·1초·1.5초 뒤 세 번(합 3초) 다시 받는다.
///
/// 연결 실패·시간 초과와 서버가 깨어나는 동안의 502·503·504만 다시 받고, 그 밖의 실패는
/// 바로 오류를 보인다(다시 시도는 사용자가 한다). 앱의 `ProviderScope(retry:)`에 쓰며,
/// 테스트의 앱 껍데기도 같은 값을 써야 화면과 같게 동작한다.
///
/// 테스트: test/core/providers/retry_policy_test.dart
Duration? appRetry(int retryCount, Object error) {
  if (retryCount >= _maxRetries || !_isTransient(error)) return null;
  return Duration(milliseconds: 500 * (retryCount + 1));
}

/// [appRetry]가 다시 받기를 모두 마치는 데 걸리는 시간
const appRetryWindow = Duration(seconds: 3);

const _maxRetries = 3;

bool _isTransient(Object error) {
  if (error is! DioException) return false;
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError => true,
    DioExceptionType.badResponse => const {
      502,
      503,
      504,
    }.contains(error.response?.statusCode),
    _ => false,
  };
}
