import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_glass_scaffold.dart';
import 'package:momeet/shared/ui/ui.dart';

void main() {
  Future<void> pumpGlass(
    WidgetTester tester, {
    bool reduceMotion = false,
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MediaQuery(
            data: MediaQueryData(
              size: const Size(400, 800),
              padding: const EdgeInsets.only(top: 24),
              disableAnimations: reduceMotion,
            ),
            child: MeetingGlassScaffold(
              title: const Text('팀 회의'),
              body: Builder(
                builder: (context) => SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top,
                  ),
                  child: Column(
                    children: [
                      const Text('맨 위 내용'),
                      for (var i = 0; i < 40; i++)
                        SizedBox(height: 60, child: Text('줄 $i')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: theme ?? AppTheme.light(),
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 머리띠 바탕의 진하기(0이면 비어 있다)
  double tint(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(AppBar),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    return (box.decoration as BoxDecoration).color!.a;
  }

  testWidgets('처음에는 머리띠가 비어 있고 내용은 머리띠 아래에서 시작한다', (tester) async {
    await pumpGlass(tester);

    expect(tint(tester), 0);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(
      tester.getTopLeft(find.text('맨 위 내용')).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.byType(AppBar)).dy),
    );
  });

  testWidgets('내용이 머리띠 아래로 굴러가면 흐리게 비추고 바탕을 옅게 깔며, 맨 위로 오면 다시 비운다', (
    tester,
  ) async {
    await pumpGlass(tester);

    await tester.drag(find.text('줄 3'), const Offset(0, -300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tint(tester), inExclusiveRange(0, 0.75), reason: '바뀌는 중');
    await tester.pumpAndSettle();
    expect(tint(tester), closeTo(0.75, 0.001));
    expect(find.byType(BackdropFilter), findsOneWidget);

    await tester.drag(find.text('줄 10'), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(tint(tester), 0);
  });

  testWidgets('애니메이션을 줄였으면 바로 바뀐다', (tester) async {
    await pumpGlass(tester, reduceMotion: true);

    await tester.drag(find.text('줄 3'), const Offset(0, -300));
    await tester.pump();
    await tester.pump();
    expect(tint(tester), closeTo(0.75, 0.001));
  });

  testWidgets('제목은 스크린 리더에 머리글로 읽히고 앞 화면이 없으면 처음 화면 단추가 있다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpGlass(tester);

    expect(tester.getSemantics(find.text('팀 회의')), isSemantics(isHeader: true));
    expect(find.byTooltip('처음 화면으로'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('어두운 테마에서도 같은 역할 색으로 깐다', (tester) async {
    await pumpGlass(tester, theme: AppTheme.dark());
    await tester.drag(find.text('줄 3'), const Offset(0, -300));
    await tester.pumpAndSettle();

    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(AppBar),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final color = (box.decoration as BoxDecoration).color!;
    expect(color.withValues(alpha: 1), AppTheme.dark().colorScheme.surface);
  });
}
