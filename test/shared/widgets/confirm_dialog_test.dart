import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/shared/widgets/confirm_dialog.dart';

void main() {
  Widget buildTestApp({required Widget child}) {
    return MaterialApp(home: child);
  }

  // ============================================================
  // ConfirmDialog 위젯
  // ============================================================
  group('ConfirmDialog 위젯', () {
    testWidgets('제목, 내용, 기본 버튼 텍스트가 표시된다', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const ConfirmDialog(
          title: '확인 제목',
          content: '확인 내용',
        ),
      ));

      expect(find.text('확인 제목'), findsOneWidget);
      expect(find.text('확인 내용'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
      expect(find.text('확인'), findsOneWidget);
    });

    testWidgets('커스텀 버튼 텍스트가 반영된다', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const ConfirmDialog(
          title: '항목 삭제',
          content: '삭제하시겠습니까?',
          cancelText: '아니요',
          confirmText: '삭제',
        ),
      ));

      expect(find.text('아니요'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '삭제'), findsOneWidget);
    });

    testWidgets('줄바꿈이 포함된 내용이 올바르게 표시된다', (tester) async {
      const msg = '이 작업은 되돌릴 수 없습니다.\n계속하시겠습니까?';

      await tester.pumpWidget(buildTestApp(
        child: const ConfirmDialog(
          title: '경고',
          content: msg,
        ),
      ));

      expect(find.text(msg), findsOneWidget);
    });

    testWidgets('취소 버튼을 누르면 false를 반환한다', (tester) async {
      bool? result;

      await tester.pumpWidget(buildTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showConfirmDialog(
                context,
                title: '제목',
                content: '내용',
              );
            },
            child: const Text('열기'),
          ),
        ),
      ));

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('확인 버튼을 누르면 true를 반환한다', (tester) async {
      bool? result;

      await tester.pumpWidget(buildTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showConfirmDialog(
                context,
                title: '제목',
                content: '내용',
              );
            },
            child: const Text('열기'),
          ),
        ),
      ));

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('바깥 영역을 탭하여 dismiss하면 false를 반환한다', (tester) async {
      bool? result;

      await tester.pumpWidget(buildTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showConfirmDialog(
                context,
                title: '제목',
                content: '내용',
              );
            },
            child: const Text('열기'),
          ),
        ),
      ));

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('cancelText와 confirmText를 동시에 커스텀할 수 있다', (tester) async {
      bool? result;

      await tester.pumpWidget(buildTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showConfirmDialog(
                context,
                title: '로그아웃',
                content: '정말 로그아웃하시겠습니까?',
                cancelText: '돌아가기',
                confirmText: '로그아웃',
              );
            },
            child: const Text('열기'),
          ),
        ),
      ));

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      expect(find.text('돌아가기'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '로그아웃'), findsOneWidget);

      await tester.tap(find.text('돌아가기'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('destructive 확인 버튼을 눌러도 true를 반환한다', (tester) async {
      bool? result;

      await tester.pumpWidget(buildTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showConfirmDialog(
                context,
                title: '항목 삭제',
                content: '삭제하시겠습니까?',
                confirmText: '삭제',
                destructive: true,
              );
            },
            child: const Text('열기'),
          ),
        ),
      ));

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '삭제'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });

  // ============================================================
  // destructive 모드
  // ============================================================
  group('destructive 모드', () {
    testWidgets('destructive가 false이면 기본 스타일이 적용된다', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const ConfirmDialog(
          title: '제목',
          content: '내용',
        ),
      ));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.style?.backgroundColor, isNull);
    });

    testWidgets('destructive가 true이면 error 색상 스타일이 적용된다', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const ConfirmDialog(
          title: '삭제',
          content: '삭제하시겠습니까?',
          destructive: true,
        ),
      ));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.style?.backgroundColor, isNotNull);
    });
  });

  // ============================================================
  // showConfirmDialog 헬퍼 함수
  // ============================================================
  group('showConfirmDialog 헬퍼', () {
    testWidgets('기본 파라미터로 호출하면 취소/확인 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showConfirmDialog(
              context,
              title: '기본 제목',
              content: '기본 내용',
            ),
            child: const Text('열기'),
          ),
        ),
      ));

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      expect(find.text('기본 제목'), findsOneWidget);
      expect(find.text('기본 내용'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '취소'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '확인'), findsOneWidget);
    });

    testWidgets('destructive 파라미터가 위젯에 전달된다', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showConfirmDialog(
              context,
              title: '삭제 확인',
              content: '삭제합니다',
              destructive: true,
            ),
            child: const Text('열기'),
          ),
        ),
      ));

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.style?.backgroundColor, isNotNull);
    });
  });
}
