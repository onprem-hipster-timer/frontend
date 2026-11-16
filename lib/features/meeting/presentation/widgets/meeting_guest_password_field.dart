import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/text/nfc.dart';

/// 게스트 비밀번호의 최대 길이. backend처럼 NFC의 UTF-8 바이트로 센다
const _maxPasswordBytes = 72;

/// 게스트 비밀번호 칸. 처음에는 가리고 끝의 단추로 보인다. 비어 있거나 72바이트를 넘으면 받지 않는다
class MeetingGuestPasswordField extends StatefulWidget {
  const MeetingGuestPasswordField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.helper,
    required this.errorText,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? helper;
  final String? errorText;
  final VoidCallback onSubmitted;

  @override
  State<MeetingGuestPasswordField> createState() =>
      _MeetingGuestPasswordFieldState();
}

class _MeetingGuestPasswordFieldState extends State<MeetingGuestPasswordField> {
  var _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscure,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: '비밀번호',
        prefixIcon: const Icon(Icons.lock_outlined),
        helperText: widget.helper,
        helperMaxLines: 6,
        errorText: widget.errorText,
        suffixIcon: IconButton(
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          tooltip: _obscure ? '비밀번호 보기' : '비밀번호 숨기기',
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return '비밀번호를 입력해 주세요';
        if (utf8.encode(nfc(value)).length > _maxPasswordBytes) {
          return '비밀번호가 너무 깁니다';
        }
        return null;
      },
      onFieldSubmitted: (_) => widget.onSubmitted(),
    );
  }
}
