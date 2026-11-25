import 'package:flutter/material.dart' as flutter show DialogRoute;
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

  _CatalogRootState? _root;

  /// 앱이 rootNavigator로 띄우는 시트·다이얼로그는 앱처럼 go_router의 맨 아래 Navigator에 놓는다
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _root = context.findAncestorStateOfType<_CatalogRootState>()
      ?.._preview = _router.routerDelegate.navigatorKey;
  }

  @override
  void dispose() {
    if (_root?._preview == _router.routerDelegate.navigatorKey) {
      _root?._preview = null;
    }
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
/// 띄운다. Widgetbook이 use case를 새로 그릴 때(use case·노브·애드온을 바꿀 때) 라우터도 새로 만들어, 띄워 둔
/// 시트·다이얼로그와 안내 화면도 함께 닫는다.
Widget catalogRouter(BuildContext context, Widget child) {
  return PreviewRouter(
    key: ValueKey(WidgetbookState.of(context).uri),
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
  AppRoute.trial => '체험하기',
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

/// 카탈로그의 맨 바깥 Navigator. Widgetbook을 감싼다.
///
/// 앱은 시트·다이얼로그를 rootNavigator로 띄우는데, 그대로 두면 Widgetbook의 Navigator에 놓여 카탈로그의
/// 테마·언어·뷰포트 밖에서 그려진다. 이 Navigator가 맨 바깥이 되어 그런 route를 지금 보이는 use case의
/// go_router Navigator로 넘긴다. Widgetbook 자신의 창(flutter/material의 날짜·색 고르기)은 Widgetbook의 Navigator로 넘긴다.
class CatalogRoot extends StatelessWidget {
  const CatalogRoot({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: _CatalogRoot(pages: [_OnlyPage(child)], onDidRemovePage: (_) {}),
    );
  }
}

class _OnlyPage extends Page<void> {
  const _OnlyPage(this.child);

  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) => PageRouteBuilder<void>(
    settings: this,
    pageBuilder: (context, animation, secondaryAnimation) => child,
  );
}

class _CatalogRoot extends Navigator {
  const _CatalogRoot({super.pages, super.onDidRemovePage});

  @override
  NavigatorState createState() => _CatalogRootState();
}

class _CatalogRootState extends NavigatorState {
  GlobalKey<NavigatorState>? _preview;

  @override
  Future<T?> push<T extends Object?>(Route<T> route) {
    final target = route is flutter.DialogRoute
        ? _widgetbook
        : _preview?.currentState ?? _widgetbook;
    return target?.push(route) ?? super.push(route);
  }

  /// 이 Navigator 아래 첫 Navigator(Widgetbook의 것)
  NavigatorState? get _widgetbook {
    NavigatorState? found;
    void visit(Element element) {
      if (found != null) return;
      if (element is StatefulElement && element.state is NavigatorState) {
        found = element.state as NavigatorState;
        return;
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    return found;
  }
}
