import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_heading.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_account.dart';

const _screens = {
  '로그인': (title: 'momeet', subtitle: '일상을 계획하고 기록하세요', brand: true),
  '회원가입': (title: '회원가입', subtitle: 'momeet과 함께 하루를 시작하세요', brand: false),
  '약관 동의': (
    title: '약관 동의',
    subtitle: 'momeet을 이용하려면 아래 항목에 동의해 주세요',
    brand: false,
  ),
  '탈퇴 대기': (
    title: '탈퇴를 신청한 계정입니다',
    subtitle: '탈퇴를 취소하면 지금까지처럼 이용할 수 있습니다',
    brand: false,
  ),
};

@widgetbook.UseCase(name: '인증 화면 제목', type: AuthHeading, path: '[로그인·회원가입]')
Widget authHeading(BuildContext context) {
  final screen = context.knobs.object.dropdown(
    label: '화면',
    description: '로그인 화면만 제목을 앱 이름처럼 크게 주색으로 쓴다',
    options: _screens.keys.toList(),
  );
  final heading = _screens[screen]!;
  return authScreenFrame(
    AuthHeading(
      title: heading.title,
      subtitle: heading.subtitle,
      brand: heading.brand,
    ),
  );
}
