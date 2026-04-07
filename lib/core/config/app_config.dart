// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 앱 전역 설정
///
/// 모든 설정 값은 assets/.env 파일에서 로드됩니다.
/// 각 getter는 타입 안전성과 기본값 fallback을 제공합니다.
class AppConfig {
  static String? _readEnv(String key) {
    try {
      return dotenv.env[key];
    } catch (_) {
      return null;
    }
  }

  // ==========================================
  // App Information
  // ==========================================

  /// 앱 이름
  static String get appName => _readEnv('APP_NAME') ?? 'MoMeet';

  /// 앱 버전
  static String get appVersion => _readEnv('APP_VERSION') ?? '1.0.0';

  // ==========================================
  // API Configuration
  // ==========================================

  /// API 기본 URL
  static String get apiBaseUrl {
    final url = _readEnv('API_BASE_URL');
    if (url == null || url.isEmpty) {
      throw Exception('API_BASE_URL이 .env 파일에 설정되지 않았습니다.');
    }
    return url;
  }

  /// HTTP 연결 타임아웃
  static Duration get connectTimeout {
    final seconds =
        int.tryParse(_readEnv('CONNECT_TIMEOUT_SECONDS') ?? '10') ?? 10;
    return Duration(seconds: seconds);
  }

  /// HTTP 응답 수신 타임아웃
  static Duration get receiveTimeout {
    final seconds =
        int.tryParse(_readEnv('RECEIVE_TIMEOUT_SECONDS') ?? '10') ?? 10;
    return Duration(seconds: seconds);
  }

  // ==========================================
  // Feature Flags
  // ==========================================

  /// 디버그 로깅 활성화 여부
  static bool get enableDebugLogging {
    final value = _readEnv('ENABLE_DEBUG_LOGGING')?.toLowerCase();
    return value == 'true' || value == '1';
  }

  // ==========================================
  // Supabase Configuration
  // ==========================================

  /// Supabase 프로젝트 URL
  static String get supabaseUrl {
    final url = _readEnv('SUPABASE_URL');
    if (url == null || url.isEmpty) {
      throw Exception('SUPABASE_URL이 .env 파일에 설정되지 않았습니다.');
    }
    return url;
  }

  /// Supabase Anon Key
  static String get supabaseAnonKey {
    final key = _readEnv('SUPABASE_ANON_KEY');
    if (key == null || key.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY가 .env 파일에 설정되지 않았습니다.');
    }
    return key;
  }

  // ==========================================
  // Development Utilities
  // ==========================================

  /// 개발 환경인지 확인
  static bool get isDevelopment {
    final value = _readEnv('IS_DEVELOPMENT')?.toLowerCase();
    return value == 'true' || value == '1';
  }

  /// 프로덕션 환경인지 확인
  static bool get isProduction => !isDevelopment;
}
