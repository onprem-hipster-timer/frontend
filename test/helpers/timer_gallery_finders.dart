import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// 대시보드의 활성 타이머 갤러리 (넘기는 쪽 영역)
Finder timerGallery() => find.byKey(const ValueKey('timer-gallery'));

/// 갤러리에서 [timerId] 타이머의 쪽
Finder timerPage(String timerId) => find.byKey(ValueKey('timer-page-$timerId'));

/// 갤러리에 보이는 쪽의 타이머 id. 갤러리는 보이는 쪽만 그린다
String shownTimerPage(WidgetTester tester) {
  const prefix = 'timer-page-';
  final pages = tester
      .widgetList<KeyedSubtree>(
        find.descendant(
          of: timerGallery(),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is KeyedSubtree &&
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(prefix),
          ),
        ),
      )
      .toList();
  expect(pages, hasLength(1));
  return (pages.single.key! as ValueKey<String>).value.substring(prefix.length);
}

/// 갤러리를 한 쪽 넘긴다. [forward]면 다음(나중에 만든) 타이머 쪽으로
Future<void> swipeTimerGallery(
  WidgetTester tester, {
  required bool forward,
}) async {
  final width = tester.getSize(timerGallery()).width;
  await tester.drag(
    timerGallery(),
    Offset((forward ? -1 : 1) * width * 0.9, 0),
  );
  await tester.pumpAndSettle();
}
