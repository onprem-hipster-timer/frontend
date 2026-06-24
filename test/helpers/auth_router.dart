import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:momeet/features/auth/presentation/pages/login_page.dart';
import 'package:momeet/features/auth/presentation/pages/signup_page.dart';

/// 로그인↔회원가입 전환(`extra`로 이메일 전달)을 end-to-end로 검증하기 위한
/// 최소 라우터 + MaterialApp.router.
///
/// `lib/router.dart`의 login/signup 빌더 와이어링(`state.extra` 주입)을
/// 그대로 미러링하므로, 실제 전환 버튼 → extra 전달 → initState 프리필
/// 경로를 통째로 태울 수 있습니다.
Widget pumpAuthFlow({
  required String initialLocation,
  List<Override> overrides = const [],
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(
          initialEmail: state.extra is String ? state.extra as String : null,
        ),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => SignupPage(
          initialEmail: state.extra is String ? state.extra as String : null,
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router),
  );
}
