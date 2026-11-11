// Kratos 클라이언트 테스트. 응답 모양은 로컬 Kratos v26.2.0 실측값을 따른다.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/shared/api/kratos/kratos_client.dart';
import 'package:momeet/shared/api/kratos/kratos_models.dart';

class _FakeKratos implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  ResponseBody Function(RequestOptions options) respond = (_) => _json(200, {});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Map<String, Object?> body) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Map<String, Object?> _flow(
  String id, {
  String state = 'choose_method',
  List<Map<String, Object?>> messages = const [],
  List<Map<String, Object?>> nodes = const [],
}) => {
  'id': id,
  'state': state,
  'ui': {'messages': messages, 'nodes': nodes},
};

Map<String, Object?> _message(int id, String type) => {
  'id': id,
  'type': type,
  'text': 'text $id',
};

void main() {
  late _FakeKratos fake;
  late KratosClient client;

  setUp(() {
    fake = _FakeKratos();
    final dio = createKratosDio('https://api.example.com/')
      ..httpClientAdapter = fake;
    client = KratosClient(dio);
  });

  group('플로우 생성', () {
    test('/auth 아래 API 플로우를 만들고 세션 헤더는 붙이지 않는다', () async {
      fake.respond = (_) => _json(200, _flow('f1'));

      final flow = await client.createFlow(KratosFlowType.login);

      final request = fake.requests.single;
      expect(request.method, 'GET');
      expect(
        request.uri.toString(),
        'https://api.example.com/auth/self-service/login/api',
      );
      expect(request.headers.containsKey('X-Session-Token'), isFalse);
      expect(flow.id, 'f1');
      expect(flow.state, 'choose_method');
    });
  });

  group('플로우 제출', () {
    test('flow 쿼리와 JSON 본문을 보내고 로그인 세션 토큰을 돌려준다', () async {
      fake.respond = (_) => _json(200, {
        'session_token': 'ory_st_abc',
        'session': {'id': 's1'},
        'continue_with': null,
      });

      final result = await client.submit(KratosFlowType.login, 'f1', {
        'method': 'password',
        'identifier': 'a@example.com',
        'password': 'pw',
      });

      final request = fake.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, '/auth/self-service/login');
      expect(request.uri.queryParameters, {'flow': 'f1'});
      expect(request.data, {
        'method': 'password',
        'identifier': 'a@example.com',
        'password': 'pw',
      });
      expect(result.sessionToken, 'ory_st_abc');
      expect(result.continueWith, isEmpty);
    });

    test('가입 결과에서 세션 토큰과 이메일 인증 플로우 ID를 꺼낸다', () async {
      fake.respond = (_) => _json(200, {
        'session_token': 'ory_st_new',
        'continue_with': [
          {
            'action': 'show_verification_ui',
            'flow': {'id': 'v1', 'verifiable_address': 'a@example.com'},
          },
          {
            'action': 'set_ory_session_token',
            'ory_session_token': 'ory_st_new',
          },
        ],
      });

      final result = await client.submit(KratosFlowType.registration, 'r1', {});

      expect(result.sessionToken, 'ory_st_new');
      expect(result.verificationFlowId, 'v1');
    });

    test('복구 코드가 맞으면 세션 토큰과 설정 플로우 ID를 꺼낸다', () async {
      fake.respond = (_) => _json(200, {
        ..._flow('r1', state: 'passed_challenge'),
        'continue_with': [
          {
            'action': 'set_ory_session_token',
            'ory_session_token': 'ory_st_rec',
          },
          {
            'action': 'show_settings_ui',
            'flow': {
              'id': 's1',
              'url': 'https://app.example.com/mypage?flow=s1',
            },
          },
        ],
      });

      final result = await client.submit(KratosFlowType.recovery, 'r1', {
        'method': 'code',
        'code': '123456',
      });

      expect(result.recoverySessionToken, 'ory_st_rec');
      expect(result.settingsFlowId, 's1');
      expect(result.flow?.state, 'passed_challenge');
    });

    test('400 플로우의 오류 메시지를 KratosException으로 던진다', () async {
      fake.respond = (_) =>
          _json(400, _flow('f1', messages: [_message(4000006, 'error')]));

      await expectLater(
        client.submit(KratosFlowType.login, 'f1', {}),
        throwsA(
          isA<KratosException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.messageId, 'messageId', 4000006),
        ),
      );
    });

    test('입력 칸의 오류 메시지도 모은다', () async {
      fake.respond = (_) => _json(
        400,
        _flow(
          'r1',
          nodes: [
            {
              'attributes': {'name': 'password'},
              'messages': [_message(4000032, 'error')],
            },
          ],
        ),
      );

      await expectLater(
        client.submit(KratosFlowType.registration, 'r1', {}),
        throwsA(
          isA<KratosException>().having(
            (e) => e.messageId,
            'messageId',
            4000032,
          ),
        ),
      );
    });

    test('200이어도 오류 메시지가 있으면 던진다 (코드 오입력)', () async {
      fake.respond = (_) => _json(
        200,
        _flow(
          'v1',
          state: 'sent_email',
          messages: [_message(4070006, 'error')],
        ),
      );

      await expectLater(
        client.submit(KratosFlowType.verification, 'v1', {
          'method': 'code',
          'code': '000000',
        }),
        throwsA(
          isA<KratosException>().having(
            (e) => e.messageId,
            'messageId',
            4070006,
          ),
        ),
      );
    });

    test('성공 메시지만 있는 플로우는 그대로 돌려준다', () async {
      fake.respond = (_) => _json(
        200,
        _flow(
          'v1',
          state: 'passed_challenge',
          messages: [_message(1080002, 'success')],
        ),
      );

      final result = await client.submit(KratosFlowType.verification, 'v1', {});

      expect(result.flow?.state, 'passed_challenge');
    });

    test('인증 전 로그인 거절은 새 인증 플로우 ID를 담는다', () async {
      fake.respond = (_) => _json(403, {
        'error': {
          'id': 'session_verified_address_required',
          'code': 400,
          'details': {
            'continue_with': [
              {
                'action': 'show_verification_ui',
                'flow': {'id': 'v9', 'verifiable_address': 'a@example.com'},
              },
            ],
          },
        },
      });

      await expectLater(
        client.submit(KratosFlowType.login, 'f1', {}),
        throwsA(
          isA<KratosException>()
              .having(
                (e) => e.errorId,
                'errorId',
                'session_verified_address_required',
              )
              .having((e) => e.verificationFlowId, 'flow', 'v9'),
        ),
      );
    });

    test('만료된 플로우는 errorId와 use_flow_id를 담는다', () async {
      fake.respond = (_) => _json(410, {
        'error': {'id': 'self_service_flow_expired', 'code': 410},
        'use_flow_id': 'f2',
      });

      await expectLater(
        client.submit(KratosFlowType.login, 'f1', {}),
        throwsA(
          isA<KratosException>()
              .having((e) => e.errorId, 'errorId', 'self_service_flow_expired')
              .having((e) => e.useFlowId, 'useFlowId', 'f2'),
        ),
      );
    });
  });

  group('세션', () {
    test('whoami는 사용자와 백엔드용 JWT를 돌려준다', () async {
      fake.respond = (_) => _json(200, {
        'id': 'sess',
        'tokenized': 'header.payload.signature',
        'identity': {
          'id': 'u1',
          'created_at': '2026-11-03T17:45:17.132908Z',
          'traits': {'email': 'A@example.com'},
          'verifiable_addresses': [
            {'value': 'a@example.com', 'verified': true, 'via': 'email'},
          ],
        },
      });

      final session = await client.whoami('ory_st_abc');

      final request = fake.requests.single;
      expect(request.uri.path, '/auth/sessions/whoami');
      expect(request.uri.queryParameters, {'tokenize_as': 'api'});
      expect(request.headers['X-Session-Token'], 'ory_st_abc');
      expect(session!.accessToken, 'header.payload.signature');
      expect(session.user.id, 'u1');
      expect(session.user.email, 'A@example.com');
      expect(session.user.emailVerified, isTrue);
      expect(session.user.name, isNull);
      expect(
        session.user.createdAt,
        DateTime.utc(2026, 11, 3, 17, 45, 17, 132, 908),
      );
    });

    test('whoami 401은 null이다', () async {
      fake.respond = (_) => _json(401, {
        'error': {
          'code': 401,
          'reason': 'No valid session credentials found in the request.',
        },
      });

      expect(await client.whoami('ory_st_gone'), isNull);
    });

    test('logout은 세션 토큰을 본문에 담아 DELETE한다', () async {
      fake.respond = (_) => ResponseBody.fromString('', 204);

      await client.logout('ory_st_abc');

      final request = fake.requests.single;
      expect(request.method, 'DELETE');
      expect(request.uri.path, '/auth/self-service/logout/api');
      expect(request.data, {'session_token': 'ory_st_abc'});
    });

    for (final status in [401, 403]) {
      test('이미 끊긴 세션의 logout($status)도 성공한다', () async {
        fake.respond = (_) => _json(status, {
          'error': {
            'code': status,
            'reason':
                'The provided Ory Session Token could not be found, is invalid, or otherwise malformed.',
          },
        });

        await client.logout('ory_st_revoked');
      });
    }

    test('logout의 다른 오류는 던진다', () async {
      fake.respond = (_) => _json(500, {
        'error': {'code': 500, 'id': 'internal_server_error'},
      });

      expect(
        () => client.logout('ory_st_abc'),
        throwsA(isA<KratosException>()),
      );
    });
  });

  group('Google 로그인 (교환 코드)', () {
    const returnTo = 'https://app.example.com/oauth-callback?redirect=%2Ftodo';
    const googleUrl =
        'https://accounts.google.com/o/oauth2/v2/auth?client_id=c&state=s';

    test('return_to를 주면 교환 코드를 요청하고 플로우에서 꺼낸다', () async {
      fake.respond = (_) => _json(200, {
        ..._flow(
          'f1',
          nodes: [
            {
              'group': 'oidc',
              'attributes': {
                'name': 'provider',
                'value': 'google',
                'type': 'submit',
              },
              'messages': <Object>[],
            },
          ],
        ),
        'session_token_exchange_code': 'init-code',
      });

      final flow = await client.createFlow(
        KratosFlowType.login,
        returnTo: returnTo,
      );

      expect(fake.requests.single.uri.queryParameters, {
        'return_session_token_exchange_code': 'true',
        'return_to': returnTo,
      });
      expect(flow.sessionTokenExchangeCode, 'init-code');
      expect(flow.oidcProviders, ['google']);
    });

    test('Google을 켜지 않은 플로우는 OIDC 제공자가 없다', () async {
      fake.respond = (_) => _json(200, _flow('f1'));

      final flow = await client.createFlow(KratosFlowType.login);

      expect(flow.oidcProviders, isEmpty);
      expect(flow.sessionTokenExchangeCode, isNull);
    });

    test('OIDC 제출의 422 응답에서 Google로 보낼 주소를 꺼낸다', () async {
      fake.respond = (_) => _json(422, {
        'error': {
          'id': 'browser_location_change_required',
          'code': 422,
          'reason':
              'In order to complete this flow please redirect the browser',
        },
        'redirect_browser_to': googleUrl,
      });

      final url = await client.submitOidc(KratosFlowType.login, 'f1', 'google');

      final request = fake.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, '/auth/self-service/login');
      expect(request.uri.queryParameters, {'flow': 'f1'});
      expect(request.data, {'method': 'oidc', 'provider': 'google'});
      expect(url, Uri.parse(googleUrl));
    });

    test('Google 주소 없이 실패하면 KratosException을 던진다', () async {
      fake.respond = (_) => _json(500, {
        'error': {'id': 'invalid_configuration', 'code': 500},
      });

      expect(
        () => client.submitOidc(KratosFlowType.login, 'f1', 'google'),
        throwsA(
          isA<KratosException>().having(
            (e) => e.errorId,
            'errorId',
            'invalid_configuration',
          ),
        ),
      );
    });

    test('교환 코드 두 개로 세션 토큰을 받는다', () async {
      fake.respond = (_) => _json(200, {
        'session_token': 'ory_st_google',
        'session': {'id': 's1'},
      });

      final sessionToken = await client.exchangeSessionToken(
        initCode: 'init-code',
        returnToCode: 'return-code',
      );

      final request = fake.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.path, '/auth/sessions/token-exchange');
      expect(request.uri.queryParameters, {
        'init_code': 'init-code',
        'return_to_code': 'return-code',
      });
      expect(sessionToken, 'ory_st_google');
    });

    test('맞지 않는 교환 코드는 404 KratosException이다', () async {
      fake.respond = (_) => _json(404, {
        'error': {
          'code': 404,
          'status': 'Not Found',
          'reason': 'no session yet for this "code"',
        },
      });

      expect(
        () => client.exchangeSessionToken(
          initCode: 'init-code',
          returnToCode: 'wrong',
        ),
        throwsA(
          isA<KratosException>().having((e) => e.statusCode, 'status', 404),
        ),
      );
    });
  });

  group('기존 계정 연결 (같은 이메일)', () {
    // Google 로그인이 같은 이메일의 비밀번호 계정을 만나면 Kratos가 만드는 로그인 플로우 (v26.2.0 실측)
    Map<String, Object?> linkFlow({bool asksToLink = true}) => _flow(
      'l1',
      messages: [if (asksToLink) _message(1010016, 'info')],
      nodes: [
        {
          'group': 'default',
          'attributes': {
            'name': 'identifier',
            'type': 'hidden',
            'value': 'owner@example.com',
          },
          'messages': <Object>[],
        },
        {
          'group': 'password',
          'attributes': {'name': 'password', 'type': 'password'},
          'messages': <Object>[],
        },
      ],
    );

    test('로그인 플로우를 조회해 연결 요청과 연결할 계정 이메일을 꺼낸다', () async {
      fake.respond = (_) => _json(200, linkFlow());

      final flow = await client.getFlow(KratosFlowType.login, 'l1');

      final request = fake.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.path, '/auth/self-service/login/flows');
      expect(request.uri.queryParameters, {'id': 'l1'});
      expect(flow.asksToLinkAccount, isTrue);
      expect(flow.identifier, 'owner@example.com');
    });

    test('연결 안내가 없는 플로우는 연결 요청이 아니다', () async {
      fake.respond = (_) => _json(200, linkFlow(asksToLink: false));

      final flow = await client.getFlow(KratosFlowType.login, 'l1');

      expect(flow.asksToLinkAccount, isFalse);
    });
  });
}
