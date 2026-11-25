import 'package:momeet/core/providers/retry_policy.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

/// '열기' 버튼으로 [open]을 부르는 화면(`/`)을 띄우고 그 라우터를 돌려준다. 시트·다이얼로그를
/// 실제처럼 열고 닫히는지, 닫힌 뒤 SnackBar가 뜨는지 볼 수 있다. [routes]는 `/` 옆에 두는
/// 화면이다(알림에서 옮겨 갈 곳 등). 화면은 세로로 넉넉하게 잡고,
/// 로케일·델리게이트는 `lib/app.dart`와 같게 둔다.
Future<GoRouter> pumpSheetHost(
  WidgetTester tester, {
  required void Function(BuildContext context) open,
  List<Override> overrides = const [],
  Size size = const Size(800, 1600),
  List<RouteBase> routes = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => open(context),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
      ...routes,
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: appRetry,
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
  return router;
}

/// [finder]가 보이게 굴린 뒤 누른다.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
