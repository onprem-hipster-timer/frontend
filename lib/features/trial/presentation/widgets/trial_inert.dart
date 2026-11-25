import 'package:material_ui/material_ui.dart';

/// 체험하기에서 앱의 위젯을 보이기만 하는 자리. [child] 안의 컨트롤은 포인터로도, 키보드로도(포커스가 들어가지
/// 않아 Tab으로 닿지 않고 Enter·Space·단축키도 받지 않는다), 보조 기술의 누르기 동작으로도 반응하지 않는다.
/// 모양과 스크린 리더가 읽는 글은 그대로다.
///
/// 길 밖의 컨트롤이 앱의 데이터를 읽는 시트나 메뉴를 열지 않게 감싼다.
///
/// 테스트: test/features/trial/presentation/widgets/trial_inert_test.dart
class TrialInert extends StatelessWidget {
  const TrialInert({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // IgnorePointer는 포인터와 보조 기술의 동작만 막으므로 포커스는 따로 뺀다
    return IgnorePointer(child: ExcludeFocus(child: child));
  }
}
