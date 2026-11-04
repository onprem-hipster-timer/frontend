/// 로그인한 사용자. Kratos identity에서 앱이 쓰는 값만 담는다.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.emailVerified,
    required this.createdAt,
    this.name,
  });

  /// Kratos identity ID (백엔드 JWT의 sub)
  final String id;
  final String email;
  final bool emailVerified;
  final String? name;
  final DateTime createdAt;
}
