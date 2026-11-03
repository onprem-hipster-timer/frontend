import 'dart:convert';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:momeet/core/auth/auth_user.dart';
import 'package:momeet/core/auth/kratos_client.dart';
import 'package:momeet/core/auth/kratos_models.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/shared_preferences_provider.dart';

// ============================================================
// Mock 클래스와 테스트 값
// ============================================================

class MockKratosClient extends Mock implements KratosClient {}

/// 테스트용 사용자
final testUser = AuthUser(
  id: 'test-uid',
  email: 'user@example.com',
  emailVerified: true,
  createdAt: DateTime.utc(2024, 1, 1),
);

/// 서명 없는 테스트 JWT. 앱은 서명을 보지 않고 exp만 읽는다.
String testJwt({Duration expiresIn = const Duration(minutes: 10)}) {
  String part(Map<String, Object?> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final exp = DateTime.now().add(expiresIn).millisecondsSinceEpoch ~/ 1000;
  return '${part({'alg': 'ES256'})}.${part({'sub': testUser.id, 'exp': exp})}.sig';
}

/// Kratos가 오류 메시지로 거절한 응답
KratosException kratosError(int messageId, {int statusCode = 400}) =>
    KratosException(
      statusCode: statusCode,
      messages: [KratosMessage(id: messageId, type: 'error', text: '')],
    );

/// mocktail의 any()가 쓸 기본값 등록 (setUpAll에서 한 번 호출)
void registerKratosFallbacks() {
  registerFallbackValue(KratosFlowType.login);
  registerFallbackValue(<String, Object?>{});
}

// ============================================================
// Kratos 테스트 Harness
// ============================================================

/// Kratos 클라이언트 mock과 세션 토큰 저장소를 묶은 헬퍼.
///
/// ```dart
/// late KratosTestHarness harness;
///
/// setUpAll(registerKratosFallbacks);
/// setUp(() async => harness = await KratosTestHarness.create());
/// ```
class KratosTestHarness {
  static const sessionToken = 'ory_st_test';

  late MockKratosClient kratos;
  late SharedPreferences prefs;

  /// whoami가 돌려주는 JWT
  late String accessToken;

  /// [authenticated]면 세션 토큰이 저장돼 있고 whoami가 [testUser]로 성공한다.
  static Future<KratosTestHarness> create({
    bool authenticated = true,
    Duration accessTokenExpiresIn = const Duration(minutes: 10),
  }) async {
    SharedPreferences.setMockInitialValues(
      authenticated ? {sessionTokenKey: sessionToken} : {},
    );
    final harness = KratosTestHarness()
      ..prefs = await SharedPreferences.getInstance()
      ..kratos = MockKratosClient()
      ..accessToken = testJwt(expiresIn: accessTokenExpiresIn);
    when(() => harness.kratos.whoami(any())).thenAnswer(
      (_) async =>
          KratosSession(user: testUser, accessToken: harness.accessToken),
    );
    return harness;
  }

  List<Override> get overrides => [
    kratosClientProvider.overrideWithValue(kratos),
    sharedPreferencesProvider.overrideWithValue(prefs),
  ];

  /// [type] 플로우를 만들면 [flowId]를 돌려주게 한다.
  void stubCreateFlow(KratosFlowType type, String flowId) {
    when(
      () => kratos.createFlow(
        type,
        sessionToken: any(named: 'sessionToken'),
        refresh: any(named: 'refresh'),
      ),
    ).thenAnswer((_) async => KratosFlow(id: flowId));
  }

  /// [type] 플로우 제출이 [result]를 돌려주게 한다.
  void stubSubmit(KratosFlowType type, KratosSubmitResult result) {
    when(
      () => kratos.submit(
        type,
        any(),
        any(),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenAnswer((_) async => result);
  }

  /// [type] 플로우 제출이 [error]를 던지게 한다.
  void stubSubmitError(KratosFlowType type, Object error) {
    when(
      () => kratos.submit(
        type,
        any(),
        any(),
        sessionToken: any(named: 'sessionToken'),
      ),
    ).thenThrow(error);
  }
}
