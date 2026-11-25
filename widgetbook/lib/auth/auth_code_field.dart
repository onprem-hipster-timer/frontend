import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_code_field.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_account.dart';

@widgetbook.UseCase(name: '메일 코드 칸', type: AuthCodeField, path: '[로그인·회원가입]')
Widget authCodeField(BuildContext context) {
  final knobs = context.knobs;
  final label = knobs.object.dropdown(
    label: '칸 이름',
    description: '이메일 인증 화면은 인증 코드, 비밀번호 재설정 화면은 재설정 코드',
    options: const ['인증 코드', '재설정 코드'],
  );
  final filled = knobs.boolean(label: '입력함');
  final showErrors = knobs.boolean(
    label: '오류 표시',
    description: '인증하기·다음을 누른 뒤. 빈 칸이면 칸 아래에 문구가 뜬다',
  );
  return authScreenFrame(
    FormStage(
      texts: [filled ? '482913' : ''],
      showErrors: showErrors,
      builder: (controllers) => AuthCodeField(
        controller: controllers[0],
        label: label,
        onSubmitted: (_) {},
      ),
    ),
  );
}
