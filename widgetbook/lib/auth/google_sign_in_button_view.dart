import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/auth/presentation/widgets/google_sign_in_button_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_account.dart';

enum _State { ready, waiting, starting }

@widgetbook.UseCase(
  name: 'Google 계정으로 계속하기',
  type: GoogleSignInButtonView,
  path: '[로그인·회원가입]',
)
Widget googleSignInButtonView(BuildContext context) {
  final state = context.knobs.object.dropdown(
    label: '상태',
    options: _State.values,
    labelBuilder: (state) => switch (state) {
      _State.ready => '누를 수 있음',
      _State.waiting => '잠시만 기다려 주세요',
      _State.starting => 'Google로 가는 중',
    },
    description:
        '화면을 열면 Google 로그인이 켜졌는지 묻는 동안 같은 자리에 막힌 버튼을 둔다. '
        '꺼져 있으면 구분선과 함께 사라진다. 모양·색은 Google 브랜딩 가이드라인을 따른다',
  );
  // 앱에서는 로그인·회원가입 화면의 로그인 버튼 아래에 놓인다. 카탈로그에서는 눌러도 아무 데도 가지 않는다
  return authScreenFrame(
    GoogleSignInButtonView(
      waiting: state == _State.waiting,
      starting: state == _State.starting,
      onPressed: () {},
    ),
  );
}
