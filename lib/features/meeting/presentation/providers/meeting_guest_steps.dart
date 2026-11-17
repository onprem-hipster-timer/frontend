import 'package:momeet/core/auth/guest_user.dart';
import 'package:momeet/core/network/turnstile_request.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/text/nfc.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_guest_errors.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 게스트 이름의 정규형: NFC로 바꾸고, 이어진 공백을 한 칸으로 줄이고, 앞뒤 공백을 뗀다(backend와 같다)
String guestName(String input) =>
    nfc(input).replaceAll(RegExp(r'\s+'), ' ').trim();

/// 모임 [meetingId]의 게스트 단계: 들어가기(이름 찾기 → 처음이면 생성 → 로그인), 이름 바꾸기, 약관 동의.
///
/// backend는 Turnstile 토큰을 한 번만 받으므로 단계마다 [turnstile]의 새 토큰을 `X-Turnstile-Token`에 담고,
/// 응답이 어떻든 위젯이 다시 확인하게 한다([TurnstileRequests.send]). 자기 삭제는 되돌리기를 기다린 뒤 보내므로
/// 토큰만 받아 두고 [deleteGuestSelf]로 보낸다.
///
/// 테스트: test/features/meeting/presentation/widgets/meeting_guest_form_test.dart
class MeetingGuestSteps {
  MeetingGuestSteps({
    required this.meetingId,
    required this.turnstile,
    required GuestsClient guests,
    required AuthNotifier auth,
  }) : _guests = guests,
       _auth = auth;

  final String meetingId;
  final TurnstileController turnstile;
  final GuestsClient _guests;
  final AuthNotifier _auth;

  /// 이 모임에 [name] 게스트가 있는지 찾는다. 응답의 `consent_version`이 지금 약관 버전이다
  Future<GuestLookupRead> lookup(String name) => turnstile.send(
    (token) => _guests.lookupGuestV1GuestsLookupPost(
      body: GuestLookup(
        resourceType: ResourceType.meeting,
        resourceId: meetingId,
        name: name,
      ),
      options: turnstileRequest(token),
    ),
  );

  /// 새 게스트를 만든다. [consentVersion]은 이름 찾기가 준 약관 버전이고, 세 항목에 동의한 것으로 보낸다.
  ///
  /// 비밀번호가 공백뿐이거나 눈에 보이는 글자로 [guestPasswordMinChars]글자보다 짧으면 토큰도 쓰지 않고
  /// [newGuestPasswordProblem]의 까닭으로 끝난다
  Future<GuestRead> create({
    required String name,
    required String password,
    required String consentVersion,
  }) {
    if (newGuestPasswordProblem(password) case final problem?) {
      return Future.error(problem);
    }
    return _create(name, password, consentVersion);
  }

  Future<GuestRead> _create(
    String name,
    String password,
    String consentVersion,
  ) => turnstile.send(
    (token) => _guests.createGuestV1GuestsPost(
      body: GuestCreate(
        resourceType: ResourceType.meeting,
        resourceId: meetingId,
        name: name,
        password: nfc(password),
        consent: ConsentCreate(
          version: consentVersion,
          ageOver14: true,
          terms: true,
          privacy: true,
        ),
      ),
      options: turnstileRequest(token),
    ),
  );

  /// [handle]과 [password]로 회원과 같은 Kratos 로그인 플로우에 들어간다
  Future<void> signIn({required String handle, required String password}) =>
      turnstile.send(
        (token) => _auth.signInAsGuest(
          meetingId: meetingId,
          handle: handle,
          password: nfc(password),
          turnstileToken: token,
        ),
      );

  /// [guest]의 이름을 [name]으로 바꾼다
  Future<void> rename(GuestUser guest, String name) => turnstile.send(
    (token) => _auth.renameGuest(
      handle: guest.handle,
      name: guestName(name),
      turnstileToken: token,
    ),
  );

  /// 바뀐 약관에 다시 동의한다. 지금 약관 버전은 [guest]의 이름을 찾아 받는다(동의 기록에는 토큰이 없다)
  Future<void> agree(GuestUser guest) async {
    final found = await lookup(guest.name);
    await _guests.putMyConsentV1GuestsMeConsentPut(
      body: ConsentCreate(
        version: found.consentVersion,
        ageOver14: true,
        terms: true,
        privacy: true,
      ),
    );
  }
}

/// 게스트 자기 삭제(`DELETE /v1/guests/me`)를 [token]으로 보낸다
Future<void> deleteGuestSelf(GuestsClient guests, String token) =>
    guests.deleteMeV1GuestsMeDelete(options: turnstileRequest(token));
