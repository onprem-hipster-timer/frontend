import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:momeet/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:momeet/features/auth/presentation/pages/login_page.dart';
import 'package:momeet/features/auth/presentation/pages/signup_page.dart';
import 'package:momeet/features/auth/presentation/pages/verification_page.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/pages/security_warning_page.dart';

/// 인증 화면 사이 이동(로그인↔회원가입의 `extra` 이메일 전달, 가입 → 이메일 인증 → 홈)을
/// end-to-end로 검증하기 위한 최소 라우터 + MaterialApp.router.
///
/// `lib/router.dart`의 인증 화면 빌더 와이어링(`state.extra`, `?flow=` 주입)과
/// 라우트 이름을 그대로 미러링한다. 인증 리다이렉트는 적용하지 않는다.
/// 홈(`/`)은 `home` 텍스트만 있는 자리표시자다.
Widget pumpAuthFlow({
  required String initialLocation,
  Object? initialExtra,
  List<Override> overrides = const [],
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    initialExtra: initialExtra,
    routes: [
      GoRoute(
        path: AppRoute.calendar.path,
        name: AppRoute.calendar.name,
        builder: (context, state) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: AppRoute.login.path,
        name: AppRoute.login.name,
        builder: (context, state) => LoginPage(
          initialEmail: state.extra is String ? state.extra as String : null,
          googleCode: state.uri.queryParameters['code'],
          accountLinkFlowId: state.uri.queryParameters['flow'],
        ),
      ),
      GoRoute(
        path: AppRoute.forgotPassword.path,
        name: AppRoute.forgotPassword.name,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoute.securityWarning.path,
        name: AppRoute.securityWarning.name,
        builder: (context, state) => SecurityWarningPage(
          attemptedUrl: state.uri.queryParameters['blocked'],
        ),
      ),
      GoRoute(
        path: AppRoute.signup.path,
        name: AppRoute.signup.name,
        builder: (context, state) => SignupPage(
          initialEmail: state.extra is String ? state.extra as String : null,
        ),
      ),
      GoRoute(
        path: AppRoute.verification.path,
        name: AppRoute.verification.name,
        builder: (context, state) => VerificationPage(
          flowId: state.uri.queryParameters['flow'],
          email: state.extra is String ? state.extra as String : null,
        ),
      ),
    ],
  );

  return ProviderScope(
    retry: appRetry,
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router),
  );
}
