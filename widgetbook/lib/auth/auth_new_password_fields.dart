import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_new_password_fields.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_account.dart';

const _inputs = {
  '빈 칸': ['', ''],
  '8자 미만': ['momo12', 'momo12'],
  '확인이 다름': ['momo1234!', 'momo4321!'],
  '알맞게 입력': ['momo1234!', 'momo1234!'],
};

@widgetbook.UseCase(
  name: '새 비밀번호와 확인 칸',
  type: AuthNewPasswordFields,
  path: '[로그인·회원가입]',
)
Widget authNewPasswordFields(BuildContext context) {
  final knobs = context.knobs;
  final label = knobs.object.dropdown(
    label: '칸 이름',
    description: '회원가입 화면은 비밀번호, 비밀번호 재설정 화면은 새 비밀번호',
    options: const ['비밀번호', '새 비밀번호'],
  );
  final input = knobs.object.dropdown(
    label: '입력',
    options: _inputs.keys.toList(),
  );
  final showErrors = knobs.boolean(
    label: '오류 표시',
    description: '회원가입·비밀번호 변경을 누른 뒤. 8자 미만이거나 확인 칸이 다르면 칸 아래에 문구가 뜬다',
  );
  return authScreenFrame(
    FormStage(
      texts: _inputs[input]!,
      showErrors: showErrors,
      builder: (controllers) => AuthNewPasswordFields(
        password: controllers[0],
        confirm: controllers[1],
        label: label,
        onSubmitted: () {},
      ),
    ),
  );
}
