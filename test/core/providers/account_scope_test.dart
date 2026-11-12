import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app.dart' show appScaffoldMessengerKey;
import 'package:momeet/core/auth/auth_user.dart';
import 'package:momeet/core/providers/account_scope.dart';
import 'package:momeet/core/providers/auth_provider.dart';

/// 인증 상태를 테스트에서 직접 바꾸는 [AuthNotifier]. 새 컨테이너에서는 미인증으로 시작한다.
class _Auth extends AuthNotifier {
  var _jwts = 0;

  @override
  AuthStatus build() => const AuthStatus.unauthenticated();

  void signIn(String id) => state = AuthStatus.authenticated(
    user: AuthUser(
      id: id,
      email: '$id@example.com',
      emailVerified: true,
      createdAt: DateTime.utc(2024, 1, 1),
    ),
    accessToken: 'jwt-${++_jwts}',
  );

  void leave() => state = const AuthStatus.unauthenticated();
}

/// 계정과 상관없이 컨테이너에 남는 값
class _Counter extends Notifier<int> {
  @override
  int build() => 0;

  void set(int value) => state = value;
}

final _counterProvider = NotifierProvider<_Counter, int>(_Counter.new);

/// 인증 상태를 보지 않고 서버에서 받는 값. 응답은 [_server]가 정한다.
final _dataProvider = FutureProvider<String>((ref) => _server.fetch());

late _Server _server;

class _Server {
  String value = 'a의 데이터';
  Completer<void>? gate;
  var fetches = 0;

  Future<String> fetch() async {
    fetches++;
    final snapshot = value;
    final g = gate;
    gate = null;
    if (g != null) await g.future;
    return snapshot;
  }
}

class _Probe extends ConsumerWidget {
  const _Probe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_dataProvider);
    return Text(
      '${ref.watch(_counterProvider)} ${data.value ?? '받는 중'}',
      textDirection: TextDirection.ltr,
    );
  }
}

void main() {
  late List<ProviderContainer> containers;

  setUp(() {
    _server = _Server();
    containers = [];
  });

  ProviderContainer current() => containers.last;
  _Auth auth() => current().read(authProvider.notifier) as _Auth;

  Future<void> pumpScope(WidgetTester tester, {Widget child = const _Probe()}) {
    return tester.pumpWidget(
      AccountScope(
        createContainer: () {
          final c = ProviderContainer(
            overrides: [authProvider.overrideWith(_Auth.new)],
          );
          containers.add(c);
          return c;
        },
        child: child,
      ),
    );
  }

  testWidgets('로그아웃하면 화면이 보던 값을 버리고 처음 상태로 다시 받는다', (tester) async {
    await pumpScope(tester);
    auth().signIn('a');
    current().read(_counterProvider.notifier).set(5);
    await tester.pumpAndSettle();
    expect(find.text('5 a의 데이터'), findsOneWidget);

    _server.value = 'b의 데이터';
    auth().leave();
    await tester.pumpAndSettle();

    expect(containers, hasLength(2));
    expect(find.text('0 b의 데이터'), findsOneWidget);
  });

  testWidgets('로그인과 JWT 갱신에는 컨테이너를 그대로 둔다', (tester) async {
    await pumpScope(tester);
    current().read(_counterProvider.notifier).set(5);
    await tester.pumpAndSettle();

    auth().signIn('a');
    await tester.pumpAndSettle();
    auth().signIn('a');
    await tester.pumpAndSettle();

    expect(containers, hasLength(1));
    expect(_server.fetches, 1);
    expect(find.text('5 a의 데이터'), findsOneWidget);
  });

  testWidgets('로그인 전의 실패·로딩에서 미인증이 되어도 컨테이너를 그대로 둔다', (tester) async {
    await pumpScope(tester);
    current().read(authProvider.notifier).state = const AuthStatus.loading();
    await tester.pumpAndSettle();
    auth().leave();
    await tester.pumpAndSettle();

    expect(containers, hasLength(1));
  });

  testWidgets('버린 컨테이너는 다음 프레임에 정리하고, 새 컨테이너도 다시 로그아웃하면 바꾼다', (
    tester,
  ) async {
    await pumpScope(tester);
    auth().signIn('a');
    await tester.pumpAndSettle();
    final first = current();
    var disposed = false;
    first.read(Provider<void>((ref) => ref.onDispose(() => disposed = true)));

    auth().leave();
    await tester.pumpAndSettle();
    expect(disposed, isTrue);

    auth().signIn('b');
    await tester.pumpAndSettle();
    auth().leave();
    await tester.pumpAndSettle();

    expect(containers, hasLength(3));
  });

  testWidgets('로그아웃 전에 보낸 요청이 나중에 끝나도 새 화면에 앞 계정 값이 나오지 않는다', (tester) async {
    _server.gate = Completer<void>();
    await pumpScope(tester);
    auth().signIn('a');
    await tester.pump();
    expect(find.text('0 받는 중'), findsOneWidget);
    final pending = _server.gate == null;
    expect(pending, isTrue, reason: 'a의 요청이 대기 중이어야 한다');

    _server.value = 'b의 데이터';
    auth().leave();
    await tester.pumpAndSettle();
    expect(find.text('0 b의 데이터'), findsOneWidget);

    // 대기 중이던 a의 요청은 버린 컨테이너에서 끝나 화면에 닿지 않는다
    await tester.pumpAndSettle();
    expect(find.textContaining('a의 데이터'), findsNothing);
  });

  testWidgets('로그아웃 직전에 잡아 둔 앱 ScaffoldMessenger로 띄운 스낵바가 보인다', (tester) async {
    late ScaffoldMessengerState messenger;
    await pumpScope(
      tester,
      child: MaterialApp(
        scaffoldMessengerKey: appScaffoldMessengerKey,
        home: Builder(
          builder: (context) {
            messenger = ScaffoldMessenger.of(context);
            return const Scaffold(body: _Probe());
          },
        ),
      ),
    );
    auth().signIn('a');
    await tester.pumpAndSettle();
    final before = messenger;

    auth().leave();
    await tester.pump();
    before.showSnackBar(const SnackBar(content: Text('탈퇴를 신청했습니다')));
    await tester.pumpAndSettle();

    expect(before.mounted, isTrue);
    expect(find.text('탈퇴를 신청했습니다'), findsOneWidget);
  });
}
