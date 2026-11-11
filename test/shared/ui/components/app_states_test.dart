import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget body) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: body),
    ),
  );

  group('AppEmptyState', () {
    testWidgets('제목·설명을 보이고 버튼은 둘 다 주었을 때만 둔다', (tester) async {
      var taps = 0;
      await pump(
        tester,
        AppEmptyState(
          icon: Icons.label_outline,
          title: '아직 태그가 없습니다',
          message: '태그를 만들어 보세요',
          actionLabel: '첫 태그 만들기',
          onAction: () => taps++,
        ),
      );

      expect(find.text('아직 태그가 없습니다'), findsOneWidget);
      expect(find.text('태그를 만들어 보세요'), findsOneWidget);
      await tester.tap(find.text('첫 태그 만들기'));
      expect(taps, 1);

      await pump(
        tester,
        const AppEmptyState(
          icon: Icons.label_outline,
          title: '비었음',
          actionLabel: '누를 곳 없음',
        ),
      );
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('낮은 칸에서는 넘치지 않고 굴려 볼 수 있다', (tester) async {
      await pump(
        tester,
        const SizedBox(
          height: 120,
          child: AppEmptyState(
            icon: Icons.history,
            title: '타이머가 없습니다',
            message: '새 작업을 시작해보세요',
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      await tester.dragUntilVisible(
        find.text('새 작업을 시작해보세요'),
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      );
      expect(find.text('새 작업을 시작해보세요'), findsOneWidget);
    });

    testWidgets('높이가 열린 곳(목록 안)에서는 내용 높이로 그린다', (tester) async {
      await pump(
        tester,
        ListView(
          children: const [
            AppEmptyState(icon: Icons.history, title: '비었음'),
            Text('아래'),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('아래'), findsOneWidget);
    });
  });

  group('AppErrorState', () {
    testWidgets('제목과 오류를 보이고 다시 시도와 다른 길을 부른다', (tester) async {
      var retries = 0;
      var backs = 0;
      await pump(
        tester,
        AppErrorState(
          title: '불러오지 못했습니다',
          error: Exception('끊김'),
          onRetry: () => retries++,
          secondaryLabel: '돌아가기',
          onSecondary: () => backs++,
        ),
      );

      expect(find.text('불러오지 못했습니다'), findsOneWidget);
      expect(find.textContaining('끊김'), findsOneWidget);
      await tester.tap(find.text('다시 시도'));
      await tester.tap(find.text('돌아가기'));
      expect((retries, backs), (1, 1));
    });

    testWidgets('콜백이 없으면 버튼을 두지 않는다', (tester) async {
      await pump(tester, const AppErrorState(title: '불러오지 못했습니다'));

      expect(find.text('다시 시도'), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });

  testWidgets('AppLoading은 진행 표시와 문구를 보인다', (tester) async {
    await pump(tester, const AppLoading(message: '불러오는 중...'));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('불러오는 중...'), findsOneWidget);
  });
}
