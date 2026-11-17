import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';

/// 탭 셸 밖 모임 화면(만들기·만든 뒤·모임) 머리띠의 서비스 배지. 누르면 앞 화면과 상관없이 처음 화면(달력)으로 간다.
/// 배지는 밝은·어두운 머리띠 어디서나 제 색 그대로 그린다
class MeetingHomeButton extends StatelessWidget {
  const MeetingHomeButton({super.key});

  /// 128px 한 장을 32 논리 픽셀로 줄여 그린다(기기 배율 4까지 선명하다)
  static const _badge = 'assets/momo_badge.webp';
  static const _size = 32.0;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: '홈으로',
    iconSize: _size,
    onPressed: () => context.goNamed(AppRoute.calendar.name),
    icon: Image.asset(
      _badge,
      width: _size,
      height: _size,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    ),
  );
}
