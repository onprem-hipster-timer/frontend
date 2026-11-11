import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_text_field.dart';

/// 인증 화면의 이메일 칸. 비었거나 '@'가 없으면 오류를 보인다
class AuthEmailField extends StatelessWidget {
  const AuthEmailField({
    super.key,
    required this.controller,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: controller,
      label: '이메일',
      hint: 'example@email.com',
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction,
      prefixIcon: Icons.email_outlined,
      onSubmitted: onSubmitted,
      validator: (value) {
        if (value == null || value.isEmpty) return '이메일을 입력해주세요';
        if (!value.contains('@')) return '올바른 이메일 형식이 아닙니다';
        return null;
      },
    );
  }
}
