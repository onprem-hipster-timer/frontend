// Kratos 공개 API 클라이언트 (backend의 /auth 프록시 경유)
//
// API(native) 플로우만 쓴다. 세션은 쿠키가 아니라 X-Session-Token 헤더로 보낸다.
// Kratos는 Cookie 헤더가 붙은 API 플로우 요청을 브라우저 요청으로 보고 거부한다(4000001).
// 웹 앱은 다른 origin의 API를 withCredentials 없이 부르므로 브라우저가 쿠키를 붙이지 않는다.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/auth/kratos_models.dart';
import 'package:momeet/core/config/app_config.dart';

enum KratosFlowType { login, registration, verification, recovery, settings }

/// [apiBaseUrl]의 /auth 아래로 요청하는 Dio.
///
/// AuthInterceptor는 붙이지 않는다. 백엔드용 JWT가 whoami로 가면 Kratos가
/// 세션 토큰으로 읽고 401을 낸다.
Dio createKratosDio(String apiBaseUrl) => Dio(
  BaseOptions(
    baseUrl: '${apiBaseUrl.replaceFirst(RegExp(r'/+$'), '')}/auth',
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
    headers: {'Accept': 'application/json'},
    // Kratos는 실패도 본문(flow, error)으로 설명하므로 상태 코드로 예외를 만들지 않는다
    validateStatus: (_) => true,
  ),
);

final kratosClientProvider = Provider<KratosClient>(
  (ref) => KratosClient(createKratosDio(AppConfig.apiBaseUrl)),
);

class KratosClient {
  KratosClient(this._dio);

  final Dio _dio;

  /// 새 플로우를 만든다. [refresh]는 로그인 플로우로 현재 세션을 재인증할 때 쓴다.
  Future<KratosFlow> createFlow(
    KratosFlowType type, {
    String? sessionToken,
    bool refresh = false,
  }) async {
    final response = await _dio.get<Object?>(
      '/self-service/${type.name}/api',
      queryParameters: {if (refresh) 'refresh': 'true'},
      options: _withSession(sessionToken),
    );
    return KratosFlow.fromJson(_parse(response));
  }

  /// 플로우를 제출한다. 코드 오입력처럼 200으로 오는 오류도 [KratosException]으로 던진다.
  Future<KratosSubmitResult> submit(
    KratosFlowType type,
    String flowId,
    Map<String, Object?> body, {
    String? sessionToken,
  }) async {
    final response = await _dio.post<Object?>(
      '/self-service/${type.name}',
      queryParameters: {'flow': flowId},
      data: body,
      options: _withSession(sessionToken),
    );
    return KratosSubmitResult.fromJson(_parse(response));
  }

  /// 세션을 확인하고 백엔드용 JWT를 받는다. 세션이 없거나 끝났으면 null.
  Future<KratosSession?> whoami(String sessionToken) async {
    final response = await _dio.get<Object?>(
      '/sessions/whoami',
      queryParameters: {'tokenize_as': 'api'},
      options: _withSession(sessionToken),
    );
    if (response.statusCode == 401) return null;
    return KratosSession.fromJson(_parse(response));
  }

  /// 세션을 끝낸다. 이미 끝난 세션이어도 성공한다.
  Future<void> logout(String sessionToken) async {
    final response = await _dio.delete<Object?>(
      '/self-service/logout/api',
      data: {'session_token': sessionToken},
    );
    _parse(response);
  }

  Options? _withSession(String? sessionToken) => sessionToken == null
      ? null
      : Options(headers: {'X-Session-Token': sessionToken});

  /// 응답 본문을 돌려준다. 오류 응답과 오류 메시지가 담긴 플로우는 [KratosException]으로 던진다.
  Map<String, Object?> _parse(Response<Object?> response) {
    final status = response.statusCode ?? 0;
    final data = response.data;
    final json = data is Map
        ? data.cast<String, Object?>()
        : <String, Object?>{};
    final errors = KratosMessage.allFrom(
      json,
    ).where((message) => message.isError).toList();
    if (status < 400 && errors.isEmpty) return json;

    final error = json['error'];
    throw KratosException(
      statusCode: status,
      errorId: error is Map ? error['id'] as String? : null,
      messages: errors,
      useFlowId: json['use_flow_id'] as String?,
    );
  }
}
