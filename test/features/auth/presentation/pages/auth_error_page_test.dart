import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/features/auth/presentation/pages/auth_error_page.dart';
import 'package:momeet/router.dart';

void main() {
  testWidgets('안내를 보여주고 버튼으로 로그인 화면에 간다', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoute.authError.path,
      routes: [
        GoRoute(
          path: AppRoute.authError.path,
          name: AppRoute.authError.name,
          builder: (context, state) => const AuthErrorPage(),
        ),
        GoRoute(
          path: AppRoute.login.path,
          name: AppRoute.login.name,
          builder: (context, state) => const Scaffold(body: Text('login')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.textContaining('링크가 만료되었거나'), findsOneWidget);

    await tester.tap(find.text('로그인 화면으로'));
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
  });
}
