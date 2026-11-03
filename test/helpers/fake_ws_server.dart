import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// TimerWsClient가 실제로 붙는 로컬 WebSocket 서버.
///
/// 연결마다 클라이언트가 보낸 서브프로토콜(인증 토큰)을 기록한다.
/// 시작하면 API_BASE_URL을 이 서버 주소로 맞춘다.
class FakeWsServer {
  FakeWsServer._(this._server);

  final HttpServer _server;

  /// 연결 순서대로 받은 Sec-WebSocket-Protocol 값
  final protocols = <String>[];
  final sockets = <WebSocket>[];

  static Future<FakeWsServer> start() async {
    final server = FakeWsServer._(
      await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
    );
    server._server.listen((request) async {
      final protocol = request.headers.value('sec-websocket-protocol') ?? '';
      final socket = await WebSocketTransformer.upgrade(
        request,
        protocolSelector: (requested) => requested.first,
      );
      server.protocols.add(protocol);
      server.sockets.add(socket);
      socket.listen((_) {});
    });
    dotenv.testLoad(
      fileInput: 'API_BASE_URL=http://127.0.0.1:${server._server.port}',
    );
    return server;
  }

  /// 연결이 [count]개가 될 때까지 기다린다.
  Future<void> waitForConnections(
    int count, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (protocols.length < count) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException(
          'WebSocket 연결 $count개를 기다리다 시간 초과 (${protocols.length}개)',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<void> close() async {
    for (final socket in sockets) {
      await socket.close();
    }
    await _server.close(force: true);
  }
}
