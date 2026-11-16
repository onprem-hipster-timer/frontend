import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_guest_steps.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_guest_errors.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 게스트가 자기를 지우는 중인지(되돌리기를 기다리거나 보내는 중). 그동안 모임 화면은 방문자 화면이다.
/// 게스트 세션이 바뀌면 처음(false)으로 돌아간다
final meetingGuestLeavingProvider = NotifierProvider<MeetingGuestLeaving, bool>(
  MeetingGuestLeaving.new,
);

class MeetingGuestLeaving extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(currentGuestProvider.select((guest) => guest?.id));
    return false;
  }

  void set(bool leaving) => state = leaving;
}

/// 게스트가 자기를 지운다. 모임 화면은 바로 방문자 화면이 되고 되돌리기 알림을 띄운 뒤, 알림이 되돌리기 없이
/// 닫히면 [token]으로 `DELETE /v1/guests/me`를 보내고 이 기기의 게스트 세션을 끝낸다. 지우지 못하면 게스트
/// 화면으로 돌아오고 알린다.
///
/// backend에는 게스트 삭제를 되돌리는 길이 없어 요청을 알림이 닫힐 때까지 미룬다. [token]은 시트의 확인
/// 상자에서 미리 받은 것이다.
Future<void> leaveMeetingAsGuest(
  BuildContext context,
  WidgetRef ref,
  String token,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final leaving = ref.read(meetingGuestLeavingProvider.notifier);
  final guests = ref.read(guestsApiProvider);
  final auth = ref.read(authProvider.notifier);
  leaving.set(true);
  final undone = await messenger.showAppUndoSnackBar('게스트 계정을 지웠습니다');
  if (undone) return leaving.set(false);
  try {
    await deleteGuestSelf(guests, token);
  } catch (error) {
    leaving.set(false);
    if (messenger.mounted) {
      messenger.showAppSnackBar(
        '게스트 계정을 지우지 못했습니다: ${guestRefusalText(error)}',
        kind: AppNoticeKind.error,
      );
    }
    return;
  }
  // 게스트를 지우면 그 세션도 끝난다. 이 기기의 토큰을 지운다(끝내지 못하면 다음 요청이 알아챈다)
  try {
    await auth.signOut();
  } on Exception {
    return;
  }
}
