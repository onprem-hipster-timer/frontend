import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_sheet_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../shared/samples_shared.dart';
import 'samples_turnstile.dart';

/// 지우기 위에 뜨는 거절 안내
const _messages = <String, String?>{
  '없음': null,
  '확인 실패': '사람인지 확인하지 못했습니다. 다시 시도해 주세요',
  '연결 끊김': '네트워크 연결을 확인해 주세요',
};

@widgetbook.UseCase(
  name: '게스트 닉네임 시트',
  type: MeetingGuestSheetView,
  path: '[모임]/참여자',
)
Widget meetingGuestSheetView(BuildContext context) {
  final knobs = context.knobs;
  final reauth = knobs.boolean(
    label: '비밀번호 다시 확인',
    description: '들어온 지 오래되었으면 닉네임을 바꾸기 전에 비밀번호 칸을 열어 다시 로그인한다',
  );
  final nameTaken = knobs.boolean(
    label: '같은 닉네임이 있음',
    description: '모임에 같은 닉네임이 있으면 닉네임 칸 아래에 알린다',
  );
  final wrongPassword = knobs.boolean(
    label: '비밀번호가 맞지 않음',
    description: '비밀번호 다시 확인에서 틀리면 비밀번호 칸 아래에 알린다',
  );
  final turnstile = turnstileKnob(
    context,
    description: '사람 확인 상자(Cloudflare Turnstile) 상태',
  );
  final message = knobs.object.dropdown(
    label: '안내',
    options: _messages.keys.toList(),
    description: '바꾸거나 지우지 못하면 지우기 위에 까닭을 알린다',
  );
  final busy = knobs.boolean(
    label: '저장 중',
    description: '누른 뒤 끝날 때까지 저장과 지우기를 누를 수 없다',
  );
  // 앱에서는 게스트가 '일정 참여자'의 편집을 누르면 아래에서 올라온다. 지우기를 누르면 시트를 닫고 되돌리기
  // 알림을 띄운다. 노브를 바꾸면 입력한 값을 버린다
  return SheetPreview(
    child: _Sheet(
      key: ValueKey(reauth),
      reauth: reauth,
      nameError: nameTaken ? '이 모임에 같은 닉네임이 있습니다. 다른 닉네임을 입력해 주세요' : null,
      passwordError: wrongPassword ? '비밀번호가 맞지 않습니다' : null,
      message: _messages[message],
      turnstile: turnstile,
      busy: busy,
    ),
  );
}

/// 닉네임·비밀번호 칸이 입력에 반응하도록 값을 들고 있고, 저장하면 칸만 검사한다
class _Sheet extends StatefulWidget {
  const _Sheet({
    super.key,
    required this.reauth,
    required this.nameError,
    required this.passwordError,
    required this.message,
    required this.turnstile,
    required this.busy,
  });

  final bool reauth;
  final String? nameError;
  final String? passwordError;
  final String? message;
  final TurnstileStatus turnstile;
  final bool busy;

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(text: '다람쥐');
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MeetingGuestSheetView(
      formKey: _formKey,
      nameController: _name,
      passwordController: _password,
      passwordFocusNode: _passwordFocus,
      reauth: widget.reauth ? '들어온 지 오래되어 비밀번호를 한 번 더 확인합니다' : null,
      nameError: widget.nameError,
      passwordError: widget.reauth ? widget.passwordError : null,
      message: widget.message,
      busy: widget.busy,
      turnstile: SampleTurnstileField(status: widget.turnstile),
      onNameChanged: () {},
      onSave: () => _formKey.currentState!.validate(),
      onDelete: () => Navigator.of(context).pop(),
    );
  }
}
