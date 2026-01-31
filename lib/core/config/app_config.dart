/// 앱 전역 설정
class AppConfig {
  static const String appName = 'MoMeet';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String apiBaseUrl = 'https://api.momeet.com';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // Feature Flags
  static const bool enableDebugLogging = true;
}
