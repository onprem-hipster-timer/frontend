import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';

/// 탭 셸 밖 모임 화면(만들기·만든 뒤·모임)의 앱바 왼쪽 단추. 링크로 바로 열어 앞 화면이 없을 때 처음 화면으로 간다
/// (앞 화면이 있으면 앱바가 뒤로 가기를 두므로 이 단추를 두지 않는다)
class MeetingHomeButton extends StatelessWidget {
  const MeetingHomeButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.home_outlined),
    tooltip: '처음 화면으로',
    onPressed: () => context.goNamed(AppRoute.calendar.name),
  );
}
