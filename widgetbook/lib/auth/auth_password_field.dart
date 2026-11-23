import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_password_field.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_account.dart';

@widgetbook.UseCase(name: '비밀번호 칸', type: AuthPasswordField, path: '[로그인·회원가입]')
Widget authPasswordField(BuildContext context) {
  final knobs = context.knobs;
  final filled = knobs.boolean(
    label: '입력함',
    description: '처음에는 가려 두고, 칸 끝의 눈 버튼을 누르면 보이거나 다시 가린다',
    initialValue: true,
  );
  final showErrors = knobs.boolean(
    label: '오류 표시',
    description: '로그인을 누른 뒤. 빈 칸이면 칸 아래에 문구가 뜬다',
  );
  return authScreenFrame(
    FormStage(
      texts: [filled ? 'momo1234!' : ''],
      showErrors: showErrors,
      builder: (controllers) => AuthPasswordField(
        controller: controllers[0],
        label: '비밀번호',
        textInputAction: TextInputAction.done,
        validator: (value) =>
            (value == null || value.isEmpty) ? '비밀번호를 입력해주세요' : null,
      ),
    ),
  );
}
