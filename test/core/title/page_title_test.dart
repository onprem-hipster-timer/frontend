import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/landing/static_landing_page.dart';
import 'package:momeet/core/title/page_title.dart';

const _app = '앱 이름';

/// 브라우저 탭 제목으로 알린 글을 차례로 모은다
List<String> _recordTitles(WidgetTester tester) {
  final titles = <String>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'SystemChrome.setApplicationSwitcherDescription') {
      titles.add((call.arguments as Map)['label'] as String);
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return titles;
}

/// /a(제목 '가'), /b(제목 '나'), /plain(제목 없음)
GoRouter _router() => GoRouter(
  initialLocation: '/a',
  routes: [
    GoRoute(
      path: '/a',
      builder: (_, _) => const PageTitle(title: '가', child: Text('가 화면')),
    ),
    GoRoute(
      path: '/b',
      builder: (_, _) => const PageTitle(title: '나', child: Text('나 화면')),
    ),
    GoRoute(path: '/plain', builder: (_, _) => const Text('제목 없는 화면')),
  ],
);

Future<GoRouter> _open(WidgetTester tester) async {
  final router = _router();
  await tester.pumpWidget(
    MaterialApp.router(title: _app, routerConfig: router),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('제목을 둔 화면을 열면 탭 제목이 그 제목이다', (tester) async {
    final titles = _recordTitles(tester);
    await _open(tester);

    expect(titles.last, '가');
  });

  testWidgets('제목 없는 화면으로 가면 탭 제목이 앱 이름으로 돌아온다', (tester) async {
    final titles = _recordTitles(tester);
    final router = await _open(tester);

    router.go('/plain');
    await tester.pumpAndSettle();

    expect(titles.last, _app);
  });

  testWidgets('제목을 둔 다른 화면으로 가면 떠난 화면이 앱 이름으로 덮지 않는다', (tester) async {
    final titles = _recordTitles(tester);
    final router = await _open(tester);

    router.go('/b');
    await tester.pumpAndSettle();

    expect(titles.last, '나');
  });

  testWidgets('위에 제목 없는 화면을 열면 앱 이름이고, 닫으면 다시 그 화면의 제목이다', (tester) async {
    final titles = _recordTitles(tester);
    final router = await _open(tester);

    router.push('/plain');
    await tester.pumpAndSettle();
    expect(titles.last, _app);

    router.pop();
    await tester.pumpAndSettle();
    expect(titles.last, '가');
  });

  testWidgets('위에 제목을 둔 화면을 열고 닫으면 각 화면의 제목이 차례로 보인다', (tester) async {
    final titles = _recordTitles(tester);
    final router = await _open(tester);

    router.push('/b');
    await tester.pumpAndSettle();
    expect(titles.last, '나');

    router.pop();
    await tester.pumpAndSettle();
    expect(titles.last, '가');
  });

  testWidgets('랜딩 화면을 열면 탭 제목이 index.html의 제목이다', (tester) async {
    final titles = _recordTitles(tester);
    await tester.pumpWidget(
      const MaterialApp(title: _app, home: StaticLandingPage()),
    );

    expect(titles.last, landingDocumentTitle);
  });
}
