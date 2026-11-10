import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_password_field.dart';

/// 새 비밀번호 칸과 확인 칸. 비밀번호는 8자 이상이어야 하고 확인 칸은 같아야 한다
class AuthNewPasswordFields extends StatelessWidget {
  const AuthNewPasswordFields({
    super.key,
    required this.password,
    required this.confirm,
    required this.label,
    required this.onSubmitted,
  });

  final TextEditingController password;
  final TextEditingController confirm;

  /// 첫 칸 이름. 확인 칸은 '[label] 확인'
  final String label;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AuthPasswordField(
          controller: password,
          label: label,
          validator: (value) {
            if (value == null || value.isEmpty) return '$label를 입력해주세요';
            if (value.length < 8) return '비밀번호는 8자 이상이어야 합니다';
            return null;
          },
        ),
        const SizedBox(height: 16),
        AuthPasswordField(
          controller: confirm,
          label: '$label 확인',
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmitted(),
          validator: (value) {
            if (value == null || value.isEmpty) return '비밀번호를 다시 입력해주세요';
            if (value != password.text) return '비밀번호가 일치하지 않습니다';
            return null;
          },
        ),
      ],
    );
  }
}
