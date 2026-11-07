import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/config/app_config.dart';

void main() {
  group('AppConfig.realtimeWsPath', () {
    tearDown(dotenv.clean);

    test('REALTIME_BACKEND가 없으면 inprocess 소켓 경로다', () {
      dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
      expect(AppConfig.realtimeWsPath, '/v1/ws/timers');
    });

    test('inprocess면 /v1/ws/timers다', () {
      dotenv.testLoad(fileInput: 'REALTIME_BACKEND=inprocess');
      expect(AppConfig.realtimeWsPath, '/v1/ws/timers');
    });

    test('cloudflare면 /realtime/ws다', () {
      dotenv.testLoad(fileInput: 'REALTIME_BACKEND=cloudflare');
      expect(AppConfig.realtimeWsPath, '/realtime/ws');
    });
  });
}
