// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// 앱 라우트 이름·경로

// ============================================================
// 라우트 정의
// ============================================================

/// 앱의 모든 라우트를 정의하는 enum
///
/// 각 라우트는 경로(path)와 인증 필요 여부(requiresAuth)를 포함합니다.
/// 새로운 페이지를 추가할 때 이 enum에만 등록하면 리다이렉트 로직이 자동 적용됩니다.
///
/// 사용 예:
/// ```dart
/// context.go(AppRoute.todo.path);
/// ```
enum AppRoute {
  // 인증 불필요 (공개 페이지)
  login(path: '/login', requiresAuth: false),
  signup(path: '/signup', requiresAuth: false),
  // 로그인한 사용자도 머문다: 비밀번호 변경도 메일 코드로 이 화면에서 한다
  forgotPassword(
    path: '/forgot-password',
    requiresAuth: false,
    authNeutral: true,
  ),
  landing(path: '/landing', requiresAuth: false),
  loading(path: '/loading', requiresAuth: false),
  securityWarning(path: '/security-warning', requiresAuth: false),

  // 로그인 여부와 상관없이 머무는 페이지 (Kratos 메일 링크·오류로 들어옴)
  verification(path: '/verification', requiresAuth: false, authNeutral: true),
  authError(path: '/auth-error', requiresAuth: false, authNeutral: true),

  // 인증 필요 (보호된 페이지)
  // 약관 동의가 필요한 사용자는 다른 보호 페이지 대신 여기로 온다
  consent(path: '/consent'),
  // 탈퇴를 신청한 사용자는 다른 보호 페이지(약관 동의 포함) 대신 여기로 온다
  accountDeletion(path: '/account-deletion'),
  calendar(path: '/'),
  scheduleDetail(path: '/schedule/detail'),
  todo(path: '/todo'),
  todoGroupDetail(path: '/todo/:groupId'),
  timer(path: '/timer'),
  timerDetail(path: '/timer/detail'),
  tags(path: '/tags'),
  mypage(path: '/mypage');

  const AppRoute({
    required this.path,
    this.requiresAuth = true,
    this.authNeutral = false,
  });

  /// 라우트 경로
  final String path;

  /// 인증 필요 여부 (기본값: true)
  final bool requiresAuth;

  /// 인증된 사용자도 머무르는 공개 페이지인지 (기본값: false)
  final bool authNeutral;

  /// 공개 라우트(인증 불필요) 경로 집합
  static final publicPaths = {
    for (final route in values)
      if (!route.requiresAuth) route.path,
  };

  /// 로그인 여부와 상관없이 리다이렉트하지 않는 경로 집합
  static final neutralPaths = {
    for (final route in values)
      if (route.authNeutral) route.path,
  };

  /// 보호된 라우트의 경로 패턴 (RegExp) 목록
  ///
  /// `:param` 세그먼트를 `[^/]+` 정규식으로 변환하여
  /// `/todo/abc-123` 같은 동적 경로도 매칭합니다.
  static final _protectedPatterns = [
    for (final route in values)
      if (route.requiresAuth)
        RegExp(
          '^${route.path.replaceAllMapped(RegExp(r':(\w+)'), (_) => r'[^/]+')}\$',
        ),
  ];

  /// 주어진 경로가 등록된 보호 라우트와 매칭되는지 확인
  static bool isKnownProtectedPath(String path) {
    return _protectedPatterns.any((pattern) => pattern.hasMatch(path));
  }
}
