import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:widgetbook/widgetbook.dart';

/// go_router로 화면을 옮기되 위치를 브라우저 주소창에 알리지 않는다(주소창은 Widgetbook이 쓴다).
/// 라우터는 처음 그릴 때 한 번 만들고, [routes]가 바뀌어도 다시 만들지 않는다.
class PreviewRouter extends StatefulWidget {
  const PreviewRouter({
    super.key,
    required this.initialLocation,
    required this.routes,
  });

  final String initialLocation;
  final List<RouteBase> routes;

  @override
  State<PreviewRouter> createState() => _PreviewRouterState();
}

class _PreviewRouterState extends State<PreviewRouter> {
  late final _router = GoRouter(
    initialLocation: widget.initialLocation,
    routes: widget.routes,
  );
  late final _information = _UnreportedRouteInformation(
    _router.routeInformationProvider,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Router(
      routerDelegate: _router.routerDelegate,
      routeInformationParser: _router.routeInformationParser,
      routeInformationProvider: _information,
    );
  }
}

/// go_router의 위치를 그대로 읽되, 라우터가 알리는 새 위치는 엔진(브라우저 주소창)에 넘기지 않는다
class _UnreportedRouteInformation extends RouteInformationProvider {
  _UnreportedRouteInformation(this._inner);

  final GoRouteInformationProvider _inner;

  @override
  RouteInformation get value => _inner.value;

  @override
  void addListener(VoidCallback listener) => _inner.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _inner.removeListener(listener);
}

const _useCaseLocation = '/use-case';

/// 카탈로그의 화면 이동: use case 한 화면 위로, 앱 라우트([AppRoute])마다 앱이 열 화면 이름을 알리는 안내 화면을
/// 띄운다. use case를 바꿔 열면 라우터를 새로 만든다.
Widget catalogRouter(BuildContext context, Widget child) {
  return PreviewRouter(
    key: ValueKey(WidgetbookState.of(context).path),
    initialLocation: _useCaseLocation,
    routes: [
      GoRoute(
        path: _useCaseLocation,
        builder: (context, state) => _ReshownOnPop(child: child),
      ),
      for (final route in AppRoute.values)
        GoRoute(
          path: route.path,
          name: route.name,
          builder: (context, state) => _AppScreenStub(_screenName(route)),
        ),
    ],
  );
}

/// 앱에서 [route]가 여는 화면의 이름
String _screenName(AppRoute route) => switch (route) {
  AppRoute.login => '로그인',
  AppRoute.signup => '회원가입',
  AppRoute.forgotPassword => '비밀번호 찾기',
  AppRoute.landing => '서비스 소개',
  AppRoute.loading => '불러오는 중',
  AppRoute.securityWarning => '보안 경고',
  AppRoute.guestSession => '게스트 안내',
  AppRoute.verification => '이메일 인증',
  AppRoute.authError => '인증 오류',
  AppRoute.consent => '약관 동의',
  AppRoute.accountDeletion => '탈퇴 대기',
  AppRoute.calendar => '캘린더',
  AppRoute.scheduleDetail => '일정 상세',
  AppRoute.todo => Terms.todo,
  AppRoute.todoGroupDetail => Terms.todoGroup,
  AppRoute.timer => Terms.timer,
  AppRoute.timerDetail => '${Terms.timer} 상세',
  AppRoute.meetings => '${Terms.meeting} 만들기',
  AppRoute.meetingCreated => '${Terms.meeting}을 만든 뒤',
  AppRoute.meetingEdit => '${Terms.meeting} 설정',
  AppRoute.tags => '태그',
  AppRoute.mypage => '마이페이지',
  AppRoute.myMeetings => '내 ${Terms.meeting}',
  AppRoute.meeting => Terms.meeting,
};

/// 앱이라면 다른 화면이 열릴 자리에 띄우는 안내. 뒤로 가면 보던 use case로 돌아간다
class _AppScreenStub extends StatelessWidget {
  const _AppScreenStub(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(_useCaseLocation),
        ),
        title: Text(name),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '앱에서는 여기서 \'$name\' 화면이 열립니다.\n카탈로그에는 그 화면이 없어 이 안내로 대신합니다.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// 시트·다이얼로그가 제 닫기 단추로 Navigator.pop을 해도 다시 그려 미리보기가 비지 않게 한다
class _ReshownOnPop extends StatefulWidget {
  const _ReshownOnPop({required this.child});

  final Widget child;

  @override
  State<_ReshownOnPop> createState() => _ReshownOnPopState();
}

class _ReshownOnPopState extends State<_ReshownOnPop> {
  var _shown = 0;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: ValueKey(_shown),
      pages: [MaterialPage<void>(child: widget.child)],
      onDidRemovePage: (_) => setState(() => _shown++),
    );
  }
}
