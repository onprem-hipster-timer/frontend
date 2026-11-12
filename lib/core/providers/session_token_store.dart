import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 세션 토큰의 보안 저장소 키. 이전 버전이 SharedPreferences에 둔 키와 같다.
///
/// 웹에서는 암호화된 값이 localStorage의 `FlutterSecureStorage.momeet.session_token`에 들어간다
/// (flutter_secure_storage_web의 기본 `publicKey` 접두사). web/landing/state.js가 Flutter 부팅 전에
/// 이 키가 있는지로 첫 화면(랜딩 여부)을 정하므로, 키나 [WebOptions.publicKey]를 바꾸면 함께 바꾼다.
const sessionTokenKey = 'momeet.session_token';

/// Kratos 세션 토큰 저장소.
///
/// 토큰은 [FlutterSecureStorage](Android Keystore, iOS Keychain, 웹 WebCrypto)에 둔다.
/// 보안 저장소는 비동기라서 앱 시작 때 [load]로 한 번 읽어 두고, 그 뒤로는 [token]으로 읽는다.
class SessionTokenStore {
  SessionTokenStore(this._storage, this._prefs);

  final FlutterSecureStorage _storage;
  final SharedPreferences _prefs;
  String? _token;

  /// 저장된 세션 토큰. 없으면 null.
  String? get token => _token;

  /// 저장소에서 토큰을 읽는다. 읽지 못하면 토큰 없음으로 시작한다.
  ///
  /// SharedPreferences에 이전 버전의 토큰이 있으면 보안 저장소로 옮기고 지운다.
  /// 옮기지 못하면 이전 키를 남겨 다음 시작에 다시 옮긴다.
  Future<void> load() async {
    final legacy = _prefs.getString(sessionTokenKey);
    if (legacy != null && legacy.isEmpty) await _prefs.remove(sessionTokenKey);
    if (legacy != null && legacy.isNotEmpty) {
      _token = legacy;
      try {
        await _storage.write(key: sessionTokenKey, value: legacy);
        await _prefs.remove(sessionTokenKey);
      } catch (_) {}
    } else {
      try {
        _token = await _storage.read(key: sessionTokenKey);
      } catch (_) {
        _token = null;
      }
    }
  }

  /// 토큰을 저장한다.
  Future<void> save(String token) async {
    await _storage.write(key: sessionTokenKey, value: token);
    _token = token;
  }

  /// 토큰을 지운다. 보안 저장소에서 지우지 못해도 이 앱 실행에서는 토큰 없음이 된다.
  ///
  /// 남은 토큰은 끝난 세션이라 다음 시작의 세션 확인에서 지워진다.
  Future<void> clear() async {
    _token = null;
    try {
      await _storage.delete(key: sessionTokenKey);
    } catch (_) {}
  }
}

/// 세션 토큰 저장소 제공자.
///
/// main()에서 [SessionTokenStore.load]를 await한 뒤 [ProviderScope.overrides]로 주입해야 합니다.
final sessionTokenStoreProvider = Provider<SessionTokenStore>(
  (ref) => throw UnimplementedError(
    'sessionTokenStoreProvider must be overridden in ProviderScope',
  ),
);
