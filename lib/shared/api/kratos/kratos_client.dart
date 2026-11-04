// Kratos 공개 API 클라이언트 (backend의 /auth 프록시 경유)
//
// API(native) 플로우만 쓴다. 세션은 쿠키가 아니라 X-Session-Token 헤더로 보낸다.
// Kratos는 Cookie 헤더가 붙은 API 플로우 요청을 브라우저 요청으로 보고 거부한다(4000001).
// 웹 앱은 다른 origin의 API를 withCredentials 없이 부르므로 브라우저가 쿠키를 붙이지 않는다.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/kratos/kratos_models.dart';
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
  ///
  /// [returnTo]를 주면 소셜 로그인용이다. Kratos는 로그인을 마친 브라우저를 [returnTo]에
  /// `code`를 붙여 돌려보내고, 플로우의 교환 코드와 그 `code`로 세션 토큰을 받는다.
  /// [returnTo]는 Kratos의 allowed_return_urls 안이어야 한다(밖이면 400).
  Future<KratosFlow> createFlow(
    KratosFlowType type, {
    String? sessionToken,
    bool refresh = false,
    String? returnTo,
  }) async {
    final response = await _dio.get<Object?>(
      '/self-service/${type.name}/api',
      queryParameters: {
        if (refresh) 'refresh': 'true',
        if (returnTo != null) ...{
          'return_session_token_exchange_code': 'true',
          'return_to': returnTo,
        },
      },
      options: _withSession(sessionToken),
    );
    return KratosFlow.fromJson(_parse(response));
  }

  /// 소셜 로그인 제공자로 제출하고 브라우저를 보낼 제공자 주소를 받는다.
  ///
  /// Kratos는 422 browser_location_change_required의 redirect_browser_to로 이 주소를 준다.
  Future<Uri> submitOidc(
    KratosFlowType type,
    String flowId,
    String provider,
  ) async {
    final response = await _dio.post<Object?>(
      '/self-service/${type.name}',
      queryParameters: {'flow': flowId},
      data: {'method': 'oidc', 'provider': provider},
    );
    final data = response.data;
    if (response.statusCode == 422 &&
        data is Map &&
        data['redirect_browser_to'] is String) {
      return Uri.parse(data['redirect_browser_to'] as String);
    }
    _parse(response);
    throw KratosException(statusCode: response.statusCode ?? 0);
  }

  /// 소셜 로그인에서 돌아온 뒤 두 교환 코드로 세션 토큰을 받는다.
  ///
  /// [initCode]는 플로우를 만들 때 받은 코드, [returnToCode]는 돌아온 주소의 `code`다.
  Future<String> exchangeSessionToken({
    required String initCode,
    required String returnToCode,
  }) async {
    final response = await _dio.get<Object?>(
      '/sessions/token-exchange',
      queryParameters: {'init_code': initCode, 'return_to_code': returnToCode},
    );
    return _parse(response)['session_token'] as String;
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
    final details = error is Map ? error['details'] : null;
    throw KratosException(
      statusCode: status,
      errorId: error is Map ? error['id'] as String? : null,
      messages: errors,
      useFlowId: json['use_flow_id'] as String?,
      // 인증 전 로그인 거절은 새 인증 플로우를 오류 상세의 continue_with로 준다
      verificationFlowId: details is Map
          ? KratosSubmitResult.fromJson({
              'continue_with': details['continue_with'],
            }).verificationFlowId
          : null,
    );
  }
}
