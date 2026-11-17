import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 회원으로 옮기려고 따로 둔 게스트 세션 토큰의 보안 저장소 키 앞부분. 뒤에 모임 id를 붙인다
/// (예: `momeet.guest_import.<모임 id>`). 인증 상태의 세션 토큰 칸([sessionTokenKey])과는 따로다
const keptGuestSessionKeyPrefix = 'momeet.guest_import.';

/// 게스트가 '안전한 정규 유저로 바꾸기'를 고른 동안 그 게스트 세션 토큰을 모임마다 따로 둔다. 회원으로 로그인한 뒤
/// 그 모임에서 게스트 시간을 옮기거나, 로그인을 그만두고 게스트로 계속할 때 꺼낸다.
///
/// 읽거나 지우지 못하면(보안 저장소 오류) 없는 것으로 본다.
class KeptGuestSessionStore {
  const KeptGuestSessionStore(this._storage);

  final FlutterSecureStorage _storage;

  String _key(String meetingId) => '$keptGuestSessionKeyPrefix$meetingId';

  Future<void> keep(String meetingId, String sessionToken) =>
      _storage.write(key: _key(meetingId), value: sessionToken);

  Future<String?> read(String meetingId) async {
    try {
      return await _storage.read(key: _key(meetingId));
    } catch (_) {
      return null;
    }
  }

  Future<void> drop(String meetingId) async {
    try {
      await _storage.delete(key: _key(meetingId));
    } catch (_) {}
  }
}

final keptGuestSessionStoreProvider = Provider<KeptGuestSessionStore>(
  (ref) => const KeptGuestSessionStore(FlutterSecureStorage()),
);
