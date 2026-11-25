import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_guest_errors.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_password_field.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _helpers = {
  '처음 쓰는 닉네임':
      '게스트는 비밀번호를 바꾸거나 찾을 수 없습니다. 잊으면 이 닉네임으로 다시 들어올 수 없습니다. '
      '분실이 우려되면 로그인을 이용해 주세요!',
  '없음': null,
};

const _errors = {
  '없음': null,
  '틀린 비밀번호': '비밀번호가 맞지 않습니다',
  '너무 짧음': guestPasswordTooShortText,
  '공백뿐': guestPasswordBlankText,
};

@widgetbook.UseCase(
  name: '게스트 비밀번호 칸',
  type: MeetingGuestPasswordField,
  path: '[모임]/들어오기·계정',
)
Widget meetingGuestPasswordField(BuildContext context) {
  final knobs = context.knobs;
  final helper = knobs.object.dropdown(
    label: '안내',
    description: '처음 쓰는 닉네임으로 들어올 때 칸 아래에 뜬다',
    options: _helpers.keys.toList(),
  );
  final error = knobs.object.dropdown(
    label: '오류',
    options: _errors.keys.toList(),
  );
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: _PasswordField(helper: _helpers[helper], errorText: _errors[error]),
  );
}

/// 입력한 글자와 커서를 지키려고 칸의 controller·focusNode를 여기서 가진다
class _PasswordField extends StatefulWidget {
  const _PasswordField({required this.helper, required this.errorText});

  final String? helper;
  final String? errorText;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MeetingGuestPasswordField(
      controller: _controller,
      focusNode: _focusNode,
      helper: widget.helper,
      errorText: widget.errorText,
      onSubmitted: () {},
    );
  }
}
