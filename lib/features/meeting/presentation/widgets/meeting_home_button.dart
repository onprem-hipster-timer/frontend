import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';

/// 탭 셸 밖 모임 화면(만들기·만든 뒤·모임)의 앱바 왼쪽. 앞 화면이 있으면 null이라 앱바가 뒤로 가기를 두고,
/// 링크로 바로 열었으면 처음 화면으로 가는 단추다
Widget? meetingAppBarLeading(BuildContext context) => context.canPop()
    ? null
    : IconButton(
        icon: const Icon(Icons.home_outlined),
        tooltip: '처음 화면으로',
        onPressed: () => context.goNamed(AppRoute.calendar.name),
      );
