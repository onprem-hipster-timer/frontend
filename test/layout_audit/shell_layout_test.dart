@Tags(['layout_audit'])
library;

import 'package:flutter_test/flutter_test.dart' show Tags;
import 'package:go_router/go_router.dart';
import 'package:layout_audit/layout_audit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/widgets/scaffold_with_nav.dart';

/// 탭 셸(하단 바·왼쪽 세로 내비)을 화면 크기 × 글자 배율로 점검한다.
void main() {
  testLayoutAudit(
    'scaffold_with_nav',
    subject: '탭 이름',
    texts: const [StressTexts.koreanLong],
    build: (text) => MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/0',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) =>
                ScaffoldWithNavBar(navigationShell: shell),
            branches: [
              for (var i = 0; i < 5; i++)
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/$i',
                      builder: (context, state) => Text(text.value),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
