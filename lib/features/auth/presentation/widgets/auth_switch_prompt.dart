import 'package:material_ui/material_ui.dart';

/// 다른 인증 화면으로 가는 줄. 예: '계정이 없으신가요? [회원가입]'
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(question),
        TextButton(onPressed: onPressed, child: Text(actionLabel)),
      ],
    );
  }
}
