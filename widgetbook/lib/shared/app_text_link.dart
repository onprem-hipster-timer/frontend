import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '글자 링크', type: AppTextLink, path: '[공통]/버튼')
Widget appTextLink(BuildContext context) {
  final label = context.knobs.string(
    label: '글자',
    initialValue: '내 정보는 어떻게 지키나요?',
  );
  // 로그인 화면의 회원가입 줄 아래, 체험하기 끝의 가입하기 아래, 모임을 만들 때 로그인을 묻는 안심 문구 아래에 둔다.
  // 앱에서는 누르면 개인정보 보호 조치 안내를 새 탭으로 연다(카탈로그에서는 열지 않는다)
  return Center(
    child: AppTextLink(label: label, onPressed: () {}),
  );
}
