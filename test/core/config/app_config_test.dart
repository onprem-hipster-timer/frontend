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

  group('AppConfig.turnstileSiteKey', () {
    tearDown(dotenv.clean);

    test('TURNSTILE_SITE_KEY를 앞뒤 공백 없이 읽는다', () {
      dotenv.testLoad(
        fileInput: 'TURNSTILE_SITE_KEY= 1x00000000000000000000AA ',
      );
      expect(AppConfig.turnstileSiteKey, '1x00000000000000000000AA');
    });

    test('없거나 비어 있으면 null이다', () {
      dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
      expect(AppConfig.turnstileSiteKey, isNull);
      dotenv.testLoad(fileInput: 'TURNSTILE_SITE_KEY=');
      expect(AppConfig.turnstileSiteKey, isNull);
    });
  });
}
