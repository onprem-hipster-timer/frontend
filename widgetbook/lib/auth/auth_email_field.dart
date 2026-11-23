import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_email_field.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_account.dart';

const _inputs = {
  '빈 칸': '',
  '입력함': 'momo@example.com',
  '형식 틀림': 'momo.example.com',
};

@widgetbook.UseCase(name: '이메일 칸', type: AuthEmailField, path: '[로그인·회원가입]')
Widget authEmailField(BuildContext context) {
  final knobs = context.knobs;
  final input = knobs.object.dropdown(
    label: '입력',
    options: _inputs.keys.toList(),
  );
  final showErrors = knobs.boolean(
    label: '오류 표시',
    description: '로그인·회원가입 버튼을 누른 뒤. 빈 칸이거나 @가 없으면 칸 아래에 문구가 뜬다',
  );
  return authScreenFrame(
    FormStage(
      texts: [_inputs[input]!],
      showErrors: showErrors,
      builder: (controllers) => AuthEmailField(controller: controllers[0]),
    ),
  );
}
