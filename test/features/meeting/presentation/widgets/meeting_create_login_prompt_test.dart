import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_create_layout.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_create_login_prompt.dart';
import 'package:momeet/shared/ui/ui.dart';

const _trust = '내 정보는 어떻게 지키나요?';
const _login = '로그인하고 계속하기';
const _close = '닫기';

/// [size] 화면, 글자 [scale]배에서 로그인을 묻는다. 넓으면 대화상자, 좁으면 시트다
Future<Finder> _ask(WidgetTester tester, Size size, double scale) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final wide = size.width >= MeetingCreateLayout.wideFrom;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [openLinkProvider.overrideWithValue((_) async {})],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => askLoginToCreateMeeting(context, wide: wide),
                child: const Text('만들기'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('만들기'));
  await tester.pumpAndSettle();
  return wide ? find.byType(AlertDialog) : find.byType(BottomSheet);
}

/// 묻기 안에서 굴릴 수 있는 거리. 굴림 영역이 없으면 0
double _scrollExtent(WidgetTester tester, Finder prompt) {
  final scrollables = find.descendant(
    of: prompt,
    matching: find.byType(Scrollable),
  );
  return scrollables.evaluate().fold(
    0.0,
    (extent, element) =>
        extent +
        ((element as StatefulElement).state as ScrollableState)
            .position
            .maxScrollExtent,
  );
}

/// [text]가 누를 수 있고 화면 안에 다 보인다
void _expectReachable(WidgetTester tester, String text, Size size) {
  final finder = find.text(text).hitTestable();
  expect(finder, findsOneWidget, reason: text);
  final rect = tester.getRect(finder);
  expect(rect.top, greaterThanOrEqualTo(0), reason: text);
  expect(rect.bottom, lessThanOrEqualTo(size.height), reason: text);
}

void main() {
  // 링크를 더하기 전에도 굴리지 않던 크기들. 링크가 들어가지 않는 크기에서는 링크를 뺀다
  const sizes = [
    Size(360, 640),
    Size(360, 800),
    Size(390, 844),
    Size(844, 390),
    Size(800, 360),
    Size(1280, 900),
  ];
  final withoutLink = {(const Size(800, 360), 2.0)};

  for (final size in sizes) {
    for (final scale in [1.0, 1.3, 2.0]) {
      final shown = !withoutLink.contains((size, scale));
      testWidgets(
        '${size.width.toInt()}×${size.height.toInt()} 화면, 글자 $scale배에서 묻기는 굴리거나 넘치지 않고 '
        '두 버튼이 다 보이며, 링크는 ${shown ? '안심 문구 아래에 있다' : '자리가 없어 빠진다'}',
        (tester) async {
          final prompt = await _ask(tester, size, scale);

          expect(tester.takeException(), isNull);
          expect(_scrollExtent(tester, prompt), 0);
          _expectReachable(tester, _login, size);
          _expectReachable(tester, _close, size);
          expect(find.text(_trust).hitTestable(), findsNWidgets(shown ? 1 : 0));
          if (shown) {
            expect(
              tester.getTopLeft(find.text(_trust)).dy,
              greaterThan(
                tester.getBottomLeft(find.text('입력한 내용은 그대로 남아요')).dy,
              ),
            );
          }
        },
      );
    }
  }

  testWidgets('글자를 키워 원래도 굴려야 하는 작은 휴대폰(320×568, 2배)에서는 링크를 빼고 원래만큼만 굴린다', (
    tester,
  ) async {
    final prompt = await _ask(tester, const Size(320, 568), 2.0);

    expect(find.text(_trust).hitTestable(), findsNothing);
    expect(_scrollExtent(tester, prompt), 20);
  });
}
