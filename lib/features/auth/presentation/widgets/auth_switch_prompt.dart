import 'package:material_ui/material_ui.dart';

/// 다른 인증 화면으로 가는 줄. 예: '계정이 없으신가요? [회원가입]'
///
/// 한 줄에 들어가지 않으면 버튼을 다음 줄로 꺾는다.
class AuthSwitchPrompt extends StatelessWidget {
  const AuthSwitchPrompt({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onPressed,
  });

  final String question;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(question, textAlign: TextAlign.center),
        TextButton(onPressed: onPressed, child: Text(actionLabel)),
      ],
    );
  }
}
