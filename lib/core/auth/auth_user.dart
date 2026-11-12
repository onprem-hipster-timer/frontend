/// 로그인한 사용자. Kratos identity에서 앱이 쓰는 값만 담는다.
///
/// 값으로 비교한다. JWT만 새로 받으면 같은 값이 와서 `currentUserProvider`를 보는 provider가 다시 계산되지 않는다.
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

  @override
  bool operator ==(Object other) =>
      other is AuthUser &&
      other.id == id &&
      other.email == email &&
      other.emailVerified == emailVerified &&
      other.name == name &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, email, emailVerified, name, createdAt);
}
