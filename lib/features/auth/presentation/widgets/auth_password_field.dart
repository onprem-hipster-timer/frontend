import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_text_field.dart';

/// 인증 화면의 비밀번호 칸. 처음에는 가리고, 끝의 버튼으로 보이거나 다시 가린다
class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String> validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: widget.controller,
      label: widget.label,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      prefixIcon: Icons.lock_outlined,
      suffixIcon: IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        tooltip: _obscure ? '비밀번호 보기' : '비밀번호 숨기기',
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
      onSubmitted: widget.onSubmitted,
      validator: widget.validator,
    );
  }
}
