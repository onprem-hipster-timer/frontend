// Kratos 공개 API 응답 중 앱이 쓰는 부분만 옮긴 모델 (손으로 파싱, 코드 생성 없음)

import 'package:momeet/core/auth/auth_user.dart';

/// Kratos UI 메시지. [id]는 Kratos text ID다 (예: 4000006 자격 증명 오류).
class KratosMessage {
  const KratosMessage({
    required this.id,
    required this.type,
    required this.text,
  });

  final int id;

  /// info, error, success
  final String type;
  final String text;

  bool get isError => type == 'error';

  /// 플로우 전체 메시지(ui.messages)와 입력 칸별 메시지(ui.nodes[].messages)를 모은다.
  static List<KratosMessage> allFrom(Map<String, Object?> json) {
    final ui = json['ui'];
    if (ui is! Map) return const [];
    final nodes = ui['nodes'];
    return [
      ..._parse(ui['messages']),
      if (nodes is List)
        for (final node in nodes)
          if (node is Map) ..._parse(node['messages']),
    ];
  }

  static List<KratosMessage> _parse(Object? raw) => [
    if (raw is List)
      for (final message in raw)
        if (message is Map)
          KratosMessage(
            id: (message['id'] as num?)?.toInt() ?? 0,
            type: message['type'] as String? ?? '',
            text: message['text'] as String? ?? '',
          ),
  ];
}

/// self-service 플로우의 ID와 진행 상태
class KratosFlow {
  const KratosFlow({
    required this.id,
    this.state,
    this.messages = const [],
    this.oidcProviders = const [],
    this.sessionTokenExchangeCode,
  });

  factory KratosFlow.fromJson(Map<String, Object?> json) => KratosFlow(
    id: json['id'] as String,
    state: json['state'] as String?,
    messages: KratosMessage.allFrom(json),
    oidcProviders: _oidcProviders(json),
    sessionTokenExchangeCode: json['session_token_exchange_code'] as String?,
  );

  final String id;

  /// 예: choose_method, sent_email, passed_challenge, show_form, success
  final String? state;
  final List<KratosMessage> messages;

  /// 서버가 켠 소셜 로그인 제공자 (예: google). 폼의 oidc 버튼에서 읽는다.
  final List<String> oidcProviders;

  /// Google 로그인에서 돌아온 뒤 세션 토큰과 바꿀 코드 (return_to를 준 플로우만)
  final String? sessionTokenExchangeCode;

  static List<String> _oidcProviders(Map<String, Object?> json) {
    final ui = json['ui'];
    final nodes = ui is Map ? ui['nodes'] : null;
    return [
      if (nodes is List)
        for (final node in nodes)
          if (node is Map && node['group'] == 'oidc')
            if (node['attributes'] case {
              'name': 'provider',
              'value': final String provider,
            })
              provider,
    ];
  }
}

/// 플로우 제출 결과
class KratosSubmitResult {
  const KratosSubmitResult({
    this.flow,
    this.sessionToken,
    this.continueWith = const [],
  });

  factory KratosSubmitResult.fromJson(Map<String, Object?> json) {
    final continueWith = json['continue_with'];
    return KratosSubmitResult(
      flow: json.containsKey('ui') ? KratosFlow.fromJson(json) : null,
      sessionToken: json['session_token'] as String?,
      continueWith: [
        if (continueWith is List)
          for (final item in continueWith)
            if (item is Map) item.cast<String, Object?>(),
      ],
    );
  }

  /// 제출 뒤의 플로우 (인증·복구·설정을 제출했을 때)
  final KratosFlow? flow;

  /// 로그인·가입이 성공하면 받는 세션 토큰
  final String? sessionToken;

  /// 다음 단계 안내 (continue_with). 로그인 성공 응답에서는 비어 있다.
  final List<Map<String, Object?>> continueWith;

  /// 가입 뒤 이메일 인증 플로우 ID
  String? get verificationFlowId => _flowId('show_verification_ui');

  /// 복구 뒤 새 비밀번호를 설정할 settings 플로우 ID
  String? get settingsFlowId => _flowId('show_settings_ui');

  /// 복구 코드가 맞았을 때 Kratos가 만든 세션 토큰
  String? get recoverySessionToken =>
      _action('set_ory_session_token')?['ory_session_token'] as String?;

  Map<String, Object?>? _action(String action) {
    for (final item in continueWith) {
      if (item['action'] == action) return item;
    }
    return null;
  }

  String? _flowId(String action) {
    final flow = _action(action)?['flow'];
    return flow is Map ? flow['id'] as String? : null;
  }
}

/// whoami 결과: 사용자와 백엔드용 JWT
class KratosSession {
  const KratosSession({required this.user, required this.accessToken});

  factory KratosSession.fromJson(Map<String, Object?> json) {
    final identity = (json['identity'] as Map).cast<String, Object?>();
    final traits = (identity['traits'] as Map).cast<String, Object?>();
    final email = traits['email'] as String;
    final addresses = identity['verifiable_addresses'];
    final emailVerified =
        addresses is List &&
        addresses.any(
          (address) =>
              address is Map &&
              address['verified'] == true &&
              (address['value'] as String?)?.toLowerCase() ==
                  email.toLowerCase(),
        );
    return KratosSession(
      user: AuthUser(
        id: identity['id'] as String,
        email: email,
        emailVerified: emailVerified,
        name: traits['name'] as String?,
        createdAt: DateTime.parse(identity['created_at'] as String),
      ),
      accessToken: json['tokenized'] as String,
    );
  }

  final AuthUser user;

  /// 백엔드에 보낼 JWT (tokenize_as=api, 유효 10분)
  final String accessToken;
}

/// Kratos가 요청을 거절함 (error 응답, 4xx·5xx, 오류 메시지가 담긴 플로우)
class KratosException implements Exception {
  const KratosException({
    required this.statusCode,
    this.errorId,
    this.messages = const [],
    this.useFlowId,
    this.verificationFlowId,
  });

  final int statusCode;

  /// 예: self_service_flow_expired, session_refresh_required, session_inactive
  final String? errorId;

  /// type이 error인 메시지
  final List<KratosMessage> messages;

  /// 플로우가 만료됐을 때 Kratos가 새로 만든 플로우 ID
  final String? useFlowId;

  /// 이메일 인증 전 로그인(session_verified_address_required)일 때 Kratos가 새로 만든 인증 플로우 ID
  final String? verificationFlowId;

  /// 첫 오류 메시지의 text ID
  int? get messageId => messages.isEmpty ? null : messages.first.id;

  @override
  String toString() => 'KratosException($statusCode, ${errorId ?? messageId})';
}
