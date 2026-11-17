import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_login_choice.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_shake.dart';

/// '로그인' 상자(넓은 화면의 오른쪽 칸 맨 위). 로그인하지 않은 방문자가 이 모임에 참여하는 길이다:
/// 까닭과 '로그인', (게스트를 받으면) 'Guest'.
///
/// [guestForm]을 주면 고르기 대신 그 폼을 보이고 제목은 '게스트로 참여'다. [shakes]가 바뀔 때마다 떨어
/// 칠하려던 사람의 눈길을 이리로 끈다(애니메이션을 줄였으면 떨지 않는다).
class MeetingLoginPanel extends StatelessWidget {
  const MeetingLoginPanel({
    super.key,
    required this.shakes,
    required this.onLogin,
    this.onGuest,
    this.guestForm,
    this.onCloseGuest,
  });

  final int shakes;
  final VoidCallback onLogin;

  /// 게스트로 들어가는 폼을 연다. 없으면(게스트를 받지 않는 모임, 확인 위젯이 없는 환경) 'Guest'가 없다
  final VoidCallback? onGuest;

  /// 펼친 게스트 폼
  final Widget? guestForm;

  /// 게스트 폼을 닫고 고르기로 돌아간다
  final VoidCallback? onCloseGuest;

  @override
  Widget build(BuildContext context) {
    final guestForm = this.guestForm;
    final onCloseGuest = this.onCloseGuest;
    return MeetingShake(
      count: shakes,
      child: MeetingPanel(
        title: guestForm == null ? '로그인' : '게스트로 참여',
        trailing: guestForm == null || onCloseGuest == null
            ? null
            : IconButton(
                onPressed: onCloseGuest,
                tooltip: '닫기',
                icon: const Icon(Icons.close),
              ),
        child:
            guestForm ?? MeetingLoginChoice(onLogin: onLogin, onGuest: onGuest),
      ),
    );
  }
}
