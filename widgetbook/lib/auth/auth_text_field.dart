import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_account.dart';

@widgetbook.UseCase(name: '인증 입력 칸', type: AuthTextField, path: '[로그인·회원가입]')
Widget authTextField(BuildContext context) {
  final knobs = context.knobs;
  final label = knobs.string(
    label: '칸 이름',
    description: '좁은 화면의 큰 글자에서는 칸 이름과 안내를 두 줄까지 보인다',
    initialValue: '이메일',
  );
  final hint = knobs.string(label: '안내', initialValue: 'example@email.com');
  final text = knobs.string(label: '입력', initialValue: 'momo@example.com');
  final obscure = knobs.boolean(
    label: '가림',
    description: '비밀번호 칸. 눈 버튼으로 보이게 하면 가림이 풀린다',
  );
  final error = knobs.stringOrNull(
    label: '오류 문구',
    description: '버튼을 누른 뒤 검사에 걸리면 칸 아래에 뜬다',
    initialValue: null,
  );
  return authScreenFrame(
    FormStage(
      texts: [text],
      showErrors: error != null,
      builder: (controllers) => AuthTextField(
        controller: controllers[0],
        label: label,
        hint: hint,
        obscureText: obscure,
        prefixIcon: obscure ? Icons.lock_outlined : Icons.email_outlined,
        suffixIcon: obscure
            ? IconButton(
                icon: const Icon(Icons.visibility_outlined),
                tooltip: '비밀번호 보기',
                onPressed: () {},
              )
            : null,
        validator: (_) => error,
      ),
    ),
  );
}
