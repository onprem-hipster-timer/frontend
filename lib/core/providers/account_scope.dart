// 로그아웃하면 provider 상태를 모두 버리는 앱 루트 스코프

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/providers/auth_provider.dart';

/// 로그인 상태에서 벗어나면(로그아웃, 세션 만료) [createContainer]로 컨테이너를 새로 만든다.
///
/// 모든 provider가 처음 상태로 돌아가므로 앞 계정의 데이터가 남지 않는다. 로그인과 JWT 갱신에는
/// 컨테이너를 그대로 둔다. 아래 트리는 새 컨테이너로 다시 만들어지므로, 로그아웃 뒤에도 남아야 하는
/// 값은 저장소에 두거나 [createContainer]의 override로 같은 인스턴스를 넘긴다.
///
/// 테스트: test/core/providers/account_scope_test.dart
class AccountScope extends StatefulWidget {
  const AccountScope({
    super.key,
    required this.createContainer,
    required this.child,
  });

  final ProviderContainer Function() createContainer;
  final Widget child;

  @override
  State<AccountScope> createState() => _AccountScopeState();
}

class _AccountScopeState extends State<AccountScope> {
  late ProviderContainer _container;
  ProviderSubscription<AuthStatus>? _auth;

  @override
  void initState() {
    super.initState();
    _attach(widget.createContainer());
  }

  void _attach(ProviderContainer container) {
    _container = container;
    _auth = container.listen(authProvider, (previous, next) {
      if (previous is AuthAuthenticated && next is! AuthAuthenticated) {
        _reset();
      }
    });
  }

  void _reset() {
    final old = _container;
    _auth?.close();
    setState(() => _attach(widget.createContainer()));
    // 이번 프레임에서 아래 트리가 새 컨테이너로 옮겨 간 뒤에 버린다
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  void dispose() {
    _auth?.close();
    _container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UncontrolledProviderScope(
    // UncontrolledProviderScope는 같은 자리에서 컨테이너가 바뀌는 것을 따르지 않으므로 새로 만든다
    key: ObjectKey(_container),
    container: _container,
    child: widget.child,
  );
}
