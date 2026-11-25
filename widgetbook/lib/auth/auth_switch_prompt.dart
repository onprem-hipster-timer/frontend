import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_switch_prompt.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '로그인·회원가입 전환 줄',
  type: AuthSwitchPrompt,
  path: '[로그인·회원가입]',
)
Widget authSwitchPrompt(BuildContext context) {
  final knobs = context.knobs;
  final signUp = knobs.object.dropdown(
    label: '화면',
    options: const ['로그인', '회원가입'],
  );
  final width = knobs.double.slider(
    label: '폭',
    description: '한 줄에 들어가지 않으면 버튼이 다음 줄로 내려간다',
    initialValue: 312,
    min: 160,
    max: 480,
    divisions: 32,
    precision: 0,
  );
  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: SizedBox(
        width: width,
        child: signUp == '로그인'
            ? AuthSwitchPrompt(
                question: '계정이 없으신가요?',
                actionLabel: '회원가입',
                onPressed: () {},
              )
            : AuthSwitchPrompt(
                question: '이미 계정이 있으신가요?',
                actionLabel: '로그인',
                onPressed: () {},
              ),
      ),
    ),
  );
}
