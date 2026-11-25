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
  // 인증 불필요 (공개 페이지). 게스트도 머무는 곳은 회원으로 로그인하는 길이다
  login(path: '/login', requiresAuth: false, allowsGuest: true),
  signup(path: '/signup', requiresAuth: false, allowsGuest: true),
  // 로그인한 사용자도 머문다: 비밀번호 변경도 메일 코드로 이 화면에서 한다
  forgotPassword(
    path: '/forgot-password',
    requiresAuth: false,
    authNeutral: true,
    allowsGuest: true,
  ),
  landing(path: '/landing', requiresAuth: false),
  loading(path: '/loading', requiresAuth: false),
  securityWarning(
    path: '/security-warning',
    requiresAuth: false,
    allowsGuest: true,
  ),
  // 게스트가 자기 모임 밖으로 가면 보는 안내. 게스트만 머문다
  guestSession(path: '/guest-session', requiresAuth: false, allowsGuest: true),

  // 로그인 여부와 상관없이 머무는 페이지 (Kratos 메일 링크·오류로 들어옴)
  verification(
    path: '/verification',
    requiresAuth: false,
    authNeutral: true,
    allowsGuest: true,
  ),
  authError(
    path: '/auth-error',
    requiresAuth: false,
    authNeutral: true,
    allowsGuest: true,
  ),

  // 체험하기 (탭 셸 밖). 서버에 보내지 않아 로그인 여부와 상관없이, 게스트도 머문다
  trial(
    path: '/demo',
    requiresAuth: false,
    authNeutral: true,
    allowsGuest: true,
  ),

  // 인증 필요 (보호된 페이지)
  // 약관 동의가 필요한 사용자는 다른 보호 페이지 대신 여기로 온다
  consent(path: '/consent'),
  // 탈퇴를 신청한 사용자는 다른 보호 페이지(약관 동의 포함) 대신 여기로 온다
  accountDeletion(path: '/account-deletion'),
  calendar(path: '/'),
  scheduleDetail(path: '/schedule/:scheduleId'),
  todo(path: '/todo'),
  todoGroupDetail(path: '/todo/:groupId'),
  timer(path: '/timer'),
  timerDetail(path: '/timer/detail'),
  // 모임 만들기 화면과 만든 뒤 화면 (탭 셸 밖). 만들기 화면은 로그인하지 않아도 머물고, 만들 때 로그인을 묻는다
  // 게스트도 머문다(만들 때 회원으로 로그인하라고 묻는다)
  meetings(path: '/meetings', allowsSignedOut: true, allowsGuest: true),
  meetingCreated(path: '/meetings/:meetingId/created'),
  // 모임 설정 화면 (탭 셸 밖). 주인만 고치고, 다른 사람에게는 찾을 수 없는 모임이다
  meetingEdit(path: '/meetings/:meetingId/edit'),
  tags(path: '/tags'),
  mypage(path: '/mypage'),
  // 마이페이지의 내 모임 전체 목록
  myMeetings(path: '/mypage/meetings'),
  // 공유 링크로 여는 모임 화면 (탭 셸 밖). 로그인하지 않아도 머문다(공개 모임만 보인다).
  // 게스트는 자기 모임의 화면에만 머문다
  meeting(path: '/meetings/:meetingId', allowsSignedOut: true);

  const AppRoute({
    required this.path,
    this.requiresAuth = true,
    this.authNeutral = false,
    this.allowsSignedOut = false,
    this.allowsGuest = false,
  });

  /// 라우트 경로
  final String path;

  /// 인증 필요 여부 (기본값: true)
  final bool requiresAuth;

  /// 인증된 사용자도 머무르는 공개 페이지인지 (기본값: false)
  final bool authNeutral;

  /// 로그인하지 않은 사용자도 머무는 보호된 페이지인지 (기본값: false).
  /// 로그인한 사용자에게는 다른 보호된 페이지와 같다(약관 동의·탈퇴 대기를 먼저 본다).
  final bool allowsSignedOut;

  /// 게스트 세션도 머무는 페이지인지 (기본값: false). 게스트의 모임 화면은 리다이렉트가 따로 본다
  final bool allowsGuest;

  /// 공개 라우트(인증 불필요) 경로 집합
  static final publicPaths = {
    for (final route in values)
      if (!route.requiresAuth) route.path,
  };

  /// 게스트 세션도 머무는 경로 집합
  static final guestPaths = {
    for (final route in values)
      if (route.allowsGuest) route.path,
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
      if (route.requiresAuth) route._pattern,
  ];

  /// 로그인하지 않아도 머무는 보호 라우트의 경로 패턴 목록
  static final _signedOutPatterns = [
    for (final route in values)
      if (route.allowsSignedOut) route._pattern,
  ];

  RegExp get _pattern =>
      RegExp('^${path.replaceAllMapped(RegExp(r':(\w+)'), (_) => r'[^/]+')}\$');

  /// [path]가 이 라우트의 경로인지 (`:param` 자리는 어떤 값이든)
  bool matches(String path) => _pattern.hasMatch(path);

  /// 주어진 경로가 등록된 보호 라우트와 매칭되는지 확인
  static bool isKnownProtectedPath(String path) {
    return _protectedPatterns.any((pattern) => pattern.hasMatch(path));
  }

  /// 주어진 경로가 로그인하지 않아도 머무는 보호 라우트인지 확인 (`/meetings`, `/meetings/abc-123` 등)
  static bool allowsSignedOutPath(String path) {
    return _signedOutPatterns.any((pattern) => pattern.hasMatch(path));
  }
}
