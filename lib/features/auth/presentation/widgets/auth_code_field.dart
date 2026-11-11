import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_text_field.dart';

/// 메일로 받은 6자리 코드 칸. 비었으면 '[label]를 입력해주세요'를 보인다
class AuthCodeField extends StatelessWidget {
  const AuthCodeField({
    super.key,
    required this.controller,
    required this.label,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: controller,
      label: label,
      hint: '6자리 숫자',
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      prefixIcon: Icons.pin_outlined,
      onSubmitted: onSubmitted,
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? '$label를 입력해주세요' : null,
    );
  }
}
