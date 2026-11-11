import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/core/providers/session_token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  const secureStorage = FlutterSecureStorage();

  /// 기기 저장소를 [secure]·[prefs] 값으로 시작한다.
  Future<SharedPreferences> setUpDevice({
    Map<String, String> secure = const {},
    Map<String, Object> prefs = const {},
  }) async {
    FlutterSecureStorage.setMockInitialValues({...secure});
    SharedPreferences.setMockInitialValues({...prefs});
    return SharedPreferences.getInstance();
  }

  /// 앱을 새로 시작한 것처럼 저장소를 다시 읽은 store
  Future<SessionTokenStore> start(SharedPreferences prefs) async {
    final store = SessionTokenStore(secureStorage, prefs);
    await store.load();
    return store;
  }

  group('시작', () {
    test('저장된 토큰이 없으면 토큰 없음이다', () async {
      final prefs = await setUpDevice();

      final store = await start(prefs);

      expect(store.token, isNull);
      expect(prefs.getBool(hasSessionKey), isNull);
    });

    test('저장한 토큰은 다시 시작해도 남는다', () async {
      final prefs = await setUpDevice();
      await (await start(prefs)).save('ory_st_a');

      final restarted = await start(prefs);

      expect(restarted.token, 'ory_st_a');
    });

    test('보안 저장소를 읽지 못하면 토큰 없음으로 시작한다', () async {
      final prefs = await setUpDevice(prefs: {hasSessionKey: true});
      final storage = _MockSecureStorage();
      when(
        () => storage.read(key: sessionTokenKey),
      ).thenThrow(PlatformException(code: 'read_failed'));

      final store = SessionTokenStore(storage, prefs);
      await store.load();

      expect(store.token, isNull);
      expect(prefs.getBool(hasSessionKey), isNull);
    });
  });

  group('이전 저장 방식에서 옮기기', () {
    test('SharedPreferences의 토큰을 보안 저장소로 옮기고 이전 키를 지운다', () async {
      final prefs = await setUpDevice(prefs: {sessionTokenKey: 'ory_st_old'});

      final store = await start(prefs);

      expect(store.token, 'ory_st_old');
      expect(await secureStorage.read(key: sessionTokenKey), 'ory_st_old');
      expect(prefs.getString(sessionTokenKey), isNull);
      expect(prefs.getBool(hasSessionKey), isTrue);
    });

    test('옮긴 뒤 다시 시작해도 같은 토큰 하나만 남는다', () async {
      final prefs = await setUpDevice(prefs: {sessionTokenKey: 'ory_st_old'});
      await start(prefs);

      final restarted = await start(prefs);

      expect(restarted.token, 'ory_st_old');
      expect(await secureStorage.readAll(), {sessionTokenKey: 'ory_st_old'});
      expect(prefs.getString(sessionTokenKey), isNull);
      expect(prefs.getBool(hasSessionKey), isTrue);
    });

    test('이전 키의 토큰이 보안 저장소의 토큰보다 앞선다', () async {
      final prefs = await setUpDevice(
        secure: {sessionTokenKey: 'ory_st_stale'},
        prefs: {sessionTokenKey: 'ory_st_old'},
      );

      final store = await start(prefs);

      expect(store.token, 'ory_st_old');
      expect(await secureStorage.read(key: sessionTokenKey), 'ory_st_old');
    });

    test('보안 저장소에 쓰지 못하면 이전 키를 남겨 다음 시작에 다시 옮긴다', () async {
      final prefs = await setUpDevice(prefs: {sessionTokenKey: 'ory_st_old'});
      final storage = _MockSecureStorage();
      when(
        () => storage.write(key: sessionTokenKey, value: 'ory_st_old'),
      ).thenThrow(PlatformException(code: 'write_failed'));

      final store = SessionTokenStore(storage, prefs);
      await store.load();

      expect(store.token, 'ory_st_old');
      expect(prefs.getString(sessionTokenKey), 'ory_st_old');

      final restarted = await start(prefs);
      expect(restarted.token, 'ory_st_old');
      expect(await secureStorage.read(key: sessionTokenKey), 'ory_st_old');
      expect(prefs.getString(sessionTokenKey), isNull);
    });
  });

  group('세션 표시', () {
    test('저장하면 세션 표시를 남기고 지우면 함께 지운다', () async {
      final prefs = await setUpDevice();
      final store = await start(prefs);

      await store.save('ory_st_a');
      expect(prefs.getBool(hasSessionKey), isTrue);

      await store.clear();
      expect(store.token, isNull);
      expect(await secureStorage.read(key: sessionTokenKey), isNull);
      expect(prefs.getBool(hasSessionKey), isNull);
    });

    test('토큰 없이 남은 세션 표시는 시작할 때 지운다', () async {
      final prefs = await setUpDevice(prefs: {hasSessionKey: true});

      await start(prefs);

      expect(prefs.getBool(hasSessionKey), isNull);
    });

    test('토큰이 있는데 세션 표시가 없으면 시작할 때 남긴다', () async {
      final prefs = await setUpDevice(secure: {sessionTokenKey: 'ory_st_a'});

      await start(prefs);

      expect(prefs.getBool(hasSessionKey), isTrue);
    });
  });
}
