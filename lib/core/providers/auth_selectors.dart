// 인증 상태에서 화면이 자주 쓰는 값만 골라 내는 provider

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/core/auth/auth_user.dart';
import 'package:momeet/core/providers/auth_provider.dart';

part 'auth_selectors.g.dart';

/// 현재 로그인 중인 사용자
@riverpod
AuthUser? currentUser(Ref ref) {
  return ref
      .watch(authProvider)
      .whenOrNull(authenticated: (user, accessToken) => user);
}

/// 현재 백엔드용 JWT
@riverpod
String? accessToken(Ref ref) {
  return ref
      .watch(authProvider)
      .whenOrNull(authenticated: (user, accessToken) => accessToken);
}

/// 인증 여부 확인
@riverpod
bool isAuthenticated(Ref ref) {
  return ref
      .watch(authProvider)
      .maybeWhen(
        authenticated: (user, accessToken) => true,
        orElse: () => false,
      );
}

/// 인증 로딩 여부 확인
@riverpod
bool isAuthLoading(Ref ref) {
  return ref
      .watch(authProvider)
      .maybeWhen(loading: () => true, orElse: () => false);
}
