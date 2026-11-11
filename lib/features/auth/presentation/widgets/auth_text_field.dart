import 'package:material_ui/material_ui.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool autofocus;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint = '',
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      autofocus: autofocus,
      decoration: InputDecoration(
        // 좁은 화면의 큰 글자에서는 칸 이름·안내를 자르지 않고 두 줄까지 보인다
        label: Text(label, maxLines: 2),
        hintText: hint,
        hintMaxLines: 2,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
    );
  }
}
