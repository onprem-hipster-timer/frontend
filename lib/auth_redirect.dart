// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// 인증 상태에 따른 리다이렉트와 이동 경로 검사
import 'package:flutter/foundation.dart';
import 'package:momeet/app_route.dart';

/// redirect 경로가 안전한 내부 경로인지 검증 (Open Redirect 방지)
///
/// 허용 조건:
/// - `/`로 시작하는 상대 경로
/// - `//`로 시작하지 않음 (프로토콜 상대 URL 차단)
/// - `://` 포함하지 않음 (절대 URL 차단)
/// - AppRoute enum에 등록된 보호 경로와 매칭 (화이트리스트)
@visibleForTesting
bool isValidRedirectPath(String path) {
  if (path.isEmpty) return false;
  if (!path.startsWith('/')) return false;
  if (path.startsWith('//')) return false;
  if (path.contains('://')) return false;
  if (!AppRoute.isKnownProtectedPath(path)) return false;
  return true;
}

/// Kratos 플로우 ID 모양 (UUID)
final _kratosFlowId = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Google 로그인에서 돌아올 때 Kratos가 붙이는 code 모양
final _kratosReturnCode = RegExp(r'^[A-Za-z0-9_-]{16,256}$');

/// 메일로 보내는 인증 코드 모양 (6자리 숫자)
final _emailCode = RegExp(r'^[0-9]{6}$');

/// Kratos가 보내는 링크(메일 인증, Google 로그인 복귀)의 값이 올바른 모양인지 (위조 링크 차단)
///
/// - 메일 인증 링크는 `/verification?flow=<플로우 ID>&code=<6자리 코드>`로 들어온다.
/// - Google 로그인은 `/login?code=<코드>`로 돌아온다.
/// - Google 이메일로 이미 가입된 계정이 있으면 `/login?flow=<플로우 ID>`로 돌아온다(계정 연결).
///
/// 누구나 이 주소를 만들어 보낼 수 있으므로 값의 모양을 확인한다.
@visibleForTesting
bool isValidAuthLink(String path, Map<String, String> queryParameters) {
  if (path == AppRoute.verification.path) {
    final flow = queryParameters['flow'];
    final code = queryParameters['code'];
    if (flow == null) return code == null;
    return _kratosFlowId.hasMatch(flow) &&
        (code == null || _emailCode.hasMatch(code));
  }
  if (path == AppRoute.login.path) {
    final code = queryParameters['code'];
    final flow = queryParameters['flow'];
    return (code == null || _kratosReturnCode.hasMatch(code)) &&
        (flow == null || _kratosFlowId.hasMatch(flow));
  }
  return true;
}

/// 인증 상태에 따른 리다이렉트 로직 (순수 함수 — 테스트 가능)
///
/// 반환값이 null이면 리다이렉트 없음.
/// [consentRequired]는 로그인한 사용자가 약관에 동의해야 하는지. null이면 아직 모른다
/// (프로필을 불러오는 중이거나 실패). 모르면 동의가 필요한 것으로 본다.
/// [deletionPending]은 로그인한 사용자가 탈퇴를 신청해 파기를 기다리는지. null이면 아직 모른다.
/// 모르면 탈퇴 대기 화면에 머물고, 다른 보호된 페이지는 약관 동의 확인이 막는다.
String? authRedirect({
  required bool isAuthenticated,
  required bool isAuthLoading,
  required String matchedLocation,
  String? redirectAfterLogin,
  Map<String, String> queryParameters = const {},
  bool? consentRequired = false,
  bool? deletionPending = false,
}) {
  final isPublicRoute = AppRoute.publicPaths.contains(matchedLocation);

  // 1. 인증 초기화 중이면 로딩 페이지로
  if (isAuthLoading) {
    return matchedLocation == AppRoute.loading.path
        ? null
        : AppRoute.loading.path;
  }

  // 1-1. 로딩이 끝났는데 로딩 페이지에 남아 있으면 탈출
  if (matchedLocation == AppRoute.loading.path) {
    return isAuthenticated ? AppRoute.calendar.path : AppRoute.landing.path;
  }

  // 1-2. 위조된 인증 링크면 보안 경고로 (로그인 여부와 상관없이)
  if (!isValidAuthLink(matchedLocation, queryParameters)) {
    final attempted = Uri(
      path: matchedLocation,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    ).toString();
    return '${AppRoute.securityWarning.path}?blocked=${Uri.encodeComponent(attempted)}';
  }

  // 2. 미인증 사용자가 보호된 페이지에 접근하려 하면 리다이렉트
  if (!isAuthenticated && !isPublicRoute) {
    // 2-1. 루트 경로는 랜딩 페이지로 (서비스 소개)
    if (matchedLocation == AppRoute.calendar.path) {
      return AppRoute.landing.path;
    }
    // 2-2. 그 외 보호 경로는 로그인 후 원래 경로로 돌아가도록
    return '${AppRoute.login.path}?redirect=${Uri.encodeComponent(matchedLocation)}';
  }

  // 3. 인증된 사용자가 공개 페이지에 있으면 원래 목적지 또는 메인 앱으로
  //    (인증 화면처럼 로그인 여부와 상관없이 머무는 페이지는 제외)
  if (isAuthenticated &&
      isPublicRoute &&
      !AppRoute.neutralPaths.contains(matchedLocation)) {
    return _destination(redirectAfterLogin);
  }

  // 4. 탈퇴 신청한 계정이면 보호된 페이지 대신 탈퇴 대기 화면으로 (원래 경로를 기억한다).
  //    대기 중에는 약관 동의를 저장할 수 없으므로 동의 화면보다 먼저 본다
  final isConsentRoute = matchedLocation == AppRoute.consent.path;
  final isDeletionRoute = matchedLocation == AppRoute.accountDeletion.path;
  if (isAuthenticated && !isPublicRoute) {
    if (deletionPending == true && !isDeletionRoute) {
      return _gate(
        AppRoute.accountDeletion.path,
        from: isConsentRoute ? redirectAfterLogin : matchedLocation,
      );
    }
    if (isDeletionRoute) {
      if (deletionPending != false) return null;
      // 4-1. 탈퇴를 취소했으면 약관 동의 여부에 따라 동의 화면이나 기억한 경로로
      if (consentRequired != false) {
        return _gate(AppRoute.consent.path, from: redirectAfterLogin);
      }
      return _destination(redirectAfterLogin);
    }
  }

  // 5. 약관 동의 전이면 보호된 페이지 대신 동의 화면으로 (동의 후 원래 경로로 돌아가도록)
  if (isAuthenticated && !isPublicRoute) {
    if (consentRequired != false && !isConsentRoute) {
      if (matchedLocation == AppRoute.calendar.path) {
        return AppRoute.consent.path;
      }
      return '${AppRoute.consent.path}?redirect=${Uri.encodeComponent(matchedLocation)}';
    }
    // 5-1. 동의가 필요 없으면 동의 화면에 머물지 않는다
    if (consentRequired == false && isConsentRoute) {
      return _destination(redirectAfterLogin);
    }
  }

  // 리다이렉트 없음
  return null;
}

/// [page]로 보내며 [from]을 돌아갈 곳으로 기억한다. 돌아갈 곳이 없거나 루트(/)면 붙이지 않는다.
String _gate(String page, {required String? from}) {
  if (from == null || from.isEmpty || from == AppRoute.calendar.path) {
    return page;
  }
  return '$page?redirect=${Uri.encodeComponent(from)}';
}

/// 로그인·약관 동의를 마친 뒤 갈 곳. [redirect]가 안전한 내부 경로가 아니면 메인 앱으로,
/// 등록되지 않은 경로면 보안 경고로 보낸다.
String _destination(String? redirect) {
  if (redirect != null && redirect.isNotEmpty) {
    if (isValidRedirectPath(redirect)) {
      return redirect;
    }
    if (!AppRoute.publicPaths.contains(redirect)) {
      return '${AppRoute.securityWarning.path}?blocked=${Uri.encodeComponent(redirect)}';
    }
  }
  return AppRoute.calendar.path;
}
