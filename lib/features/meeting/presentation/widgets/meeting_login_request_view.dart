import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_login_choice.dart';

/// 요청 시트의 내용: '내 시간 입력하기', 까닭, 로그인·Guest. [guestForm]을 주면 고르기 대신 그 폼을 보이고
/// 제목은 '게스트로 참여'이며, 앞의 '뒤로'([onBack])로 고르기로 돌아간다.
class MeetingLoginRequestView extends StatelessWidget {
  const MeetingLoginRequestView({
    super.key,
    required this.guestForm,
    required this.onBack,
    required this.onLogin,
    required this.onGuest,
  });

  /// 펼친 게스트 폼
  final Widget? guestForm;
  final VoidCallback onBack;
  final VoidCallback onLogin;

  /// 게스트 폼을 연다. 없으면 'Guest'가 없다
  final VoidCallback? onGuest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final guestForm = this.guestForm;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (guestForm != null)
                  IconButton(
                    onPressed: onBack,
                    tooltip: '뒤로',
                    icon: const Icon(Icons.arrow_back),
                  ),
                Expanded(
                  child: Text(
                    guestForm != null ? '게스트로 참여' : '내 시간 입력하기',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            guestForm ?? MeetingLoginChoice(onLogin: onLogin, onGuest: onGuest),
          ],
        ),
      ),
    );
  }
}
