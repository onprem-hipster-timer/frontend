import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_shake.dart';

/// '로그인' 상자. 로그인하지 않은 방문자가 이 모임에 참여하는 길이다.
///
/// [shakes]가 바뀔 때마다 떨어 칠하려던 사람의 눈길을 이리로 끈다(애니메이션을 줄였으면 떨지 않는다).
class MeetingLoginPanel extends StatelessWidget {
  const MeetingLoginPanel({
    super.key,
    required this.shakes,
    required this.onLogin,
  });

  final int shakes;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return MeetingShake(
      count: shakes,
      child: MeetingPanel(
        title: '로그인',
        child: FilledButton.tonal(
          onPressed: onLogin,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('로그인'),
        ),
      ),
    );
  }
}
