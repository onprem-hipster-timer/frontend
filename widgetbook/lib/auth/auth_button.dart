import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_button.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_account.dart';

@widgetbook.UseCase(name: '로그인 버튼', type: AuthButton, path: '[로그인·회원가입]')
Widget authButton(BuildContext context) {
  final knobs = context.knobs;
  final text = knobs.object.dropdown(
    label: '문구',
    description: '로그인·회원가입·이메일 인증·비밀번호 재설정·약관 동의·탈퇴 대기 화면이 같은 버튼을 쓴다',
    options: const [
      '로그인',
      '로그인하고 Google 연결',
      '회원가입',
      '코드 받기',
      '인증하기',
      '동의하고 시작하기',
      '탈퇴 취소하고 계속 이용',
    ],
  );
  final loading = knobs.boolean(
    label: '보내는 중',
    description: '누른 뒤 서버 답을 기다리는 동안. 글자 대신 진행 표시가 돌고 누를 수 없다',
  );
  final enabled = knobs.boolean(
    label: '누를 수 있음',
    description: '약관 동의 화면에서는 필수 항목을 모두 체크해야 누를 수 있다',
    initialValue: true,
  );
  return authScreenFrame(
    AuthButton(
      text: text,
      onPressed: enabled ? () {} : null,
      isLoading: loading,
    ),
  );
}
