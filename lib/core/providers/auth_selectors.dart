// 인증 상태에서 화면이 자주 쓰는 값만 골라 내는 provider

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/core/auth/auth_user.dart';
import 'package:momeet/core/auth/guest_user.dart';
import 'package:momeet/core/providers/auth_provider.dart';

part 'auth_selectors.g.dart';

/// 현재 로그인 중인 회원. 게스트 세션이면 null이다
@riverpod
AuthUser? currentUser(Ref ref) {
  return ref
      .watch(authProvider)
      .whenOrNull(authenticated: (user, accessToken) => user);
}

/// 현재 게스트 세션의 게스트. 회원이거나 로그인하지 않았으면 null이다
@riverpod
GuestUser? currentGuest(Ref ref) {
  return ref
      .watch(authProvider)
      .whenOrNull(guest: (guest, accessToken) => guest);
}

/// 현재 회원의 백엔드용 JWT
@riverpod
String? accessToken(Ref ref) {
  return ref
      .watch(authProvider)
      .whenOrNull(authenticated: (user, accessToken) => accessToken);
}

/// 회원으로 로그인했는지. 게스트 세션은 false다
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
