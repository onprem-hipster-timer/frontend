import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_created_page.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_qr_code.dart';
import 'package:qr/qr.dart';

import '../../meeting_fixtures.dart';

void main() {
  late FakeMeetingsClient meetings;
  late GoRouter router;
  late List<String> copied;

  setUp(() {
    meetings = FakeMeetingsClient(meeting: makeMeeting());
    copied = [];
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(360, 800),
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    router = GoRouter(
      initialLocation: '/meetings/meeting-1/created',
      routes: [
        GoRoute(
          path: AppRoute.meetingCreated.path,
          name: AppRoute.meetingCreated.name,
          builder: (context, state) =>
              MeetingCreatedPage(meetingId: state.pathParameters['meetingId']!),
        ),
        GoRoute(
          path: AppRoute.meeting.path,
          name: AppRoute.meeting.name,
          builder: (context, state) =>
              Text('모임 화면 ${state.pathParameters['meetingId']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        retry: appRetry,
        overrides: meetingOverrides(meetings: meetings),
        child: MaterialApp.router(routerConfig: router, theme: theme),
      ),
    );
    await tester.pumpAndSettle();
  }

  const link = 'https://app.example.com/meetings/meeting-1';
  Finder qr() => find.bySemanticsLabel('모임 링크 QR 코드');
  Finder toggle(String text) => find.widgetWithText(InkWell, text);

  Future<void> showQr(WidgetTester tester) async {
    await tester.ensureVisible(toggle('또는 QR로 공유하기'));
    await tester.tap(toggle('또는 QR로 공유하기'));
    await tester.pumpAndSettle();
  }

  testWidgets('완료를 알리고 모임 첫날을 달력 그림으로 보인다', (tester) async {
    await pumpPage(tester);

    expect(find.text('모임 생성이 완료되었어요 :)'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('March'), findsOneWidget);
    expect(find.bySemanticsLabel('첫날 3월 1일 (월)'), findsOneWidget);
  });

  group('링크를 누가 열 수 있는지', () {
    for (final (level, line) in [
      (VisibilityLevel.allowedEmails, '정한 이메일로 로그인한 사람만 열 수 있어요'),
      (VisibilityLevel.private, '나만 볼 수 있어요'),
    ]) {
      testWidgets('${level.name} 모임은 "$line"을 한 줄로 알리고 QR은 그대로다', (
        tester,
      ) async {
        meetings.meeting = makeMeeting().copyWith(visibilityLevel: level);
        await pumpPage(tester);

        expect(find.text(line), findsOneWidget);
        await showQr(tester);
        expect(qr(), findsOneWidget);
        expect(find.text(line), findsOneWidget);
      });
    }

    testWidgets('공개 모임은 알리지 않는다', (tester) async {
      meetings.meeting = makeMeeting().copyWith(
        visibilityLevel: VisibilityLevel.public,
      );
      await pumpPage(tester);

      expect(find.textContaining('열 수 있어요'), findsNothing);
      expect(find.textContaining('볼 수 있어요'), findsNothing);
    });
  });

  testWidgets('링크 공유를 누르면 모임 화면 주소를 복사하고 알린다', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('링크 공유'));
    await tester.pumpAndSettle();

    expect(copied, ['https://app.example.com/meetings/meeting-1']);
    expect(find.text('링크를 복사했습니다'), findsOneWidget);
  });

  testWidgets('나의 일정 입력을 누르면 주소가 그 모임의 공유 링크인 모임 화면으로 간다', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('나의 일정 입력'));
    await tester.pumpAndSettle();

    expect(find.text('모임 화면 meeting-1'), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/meetings/meeting-1',
    );
  });

  testWidgets('모임을 불러오지 못해도 달력 그림만 비우고 두 버튼은 쓸 수 있다', (tester) async {
    meetings.readError = StateError('없음');
    await pumpPage(tester);

    expect(find.text('March'), findsNothing);
    await tester.tap(find.text('링크 공유'));
    await tester.pumpAndSettle();
    expect(copied, ['https://app.example.com/meetings/meeting-1']);

    await tester.tap(find.text('나의 일정 입력'));
    await tester.pumpAndSettle();
    expect(find.text('모임 화면 meeting-1'), findsOneWidget);
  });

  group('QR', () {
    testWidgets('두 단추 아래에 또는 QR로 공유하기가 버튼으로 있고 처음에는 달력 그림이다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpPage(tester);

      final control = toggle('또는 QR로 공유하기');
      expect(control, findsOneWidget);
      expect(
        tester.getTopLeft(control).dy,
        greaterThan(tester.getBottomLeft(find.text('나의 일정 입력')).dy),
      );
      expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
      expect(
        tester.getSemantics(control),
        isSemantics(isButton: true, hasTapAction: true, label: '또는 QR로 공유하기'),
      );
      expect(qr(), findsNothing);
      expect(find.bySemanticsLabel('첫날 3월 1일 (월)'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('누르면 달력 그림 자리가 QR이 되고 그 아래 링크와 복사가 있으며, 글이 QR 가리기로 바뀐다', (
      tester,
    ) async {
      await pumpPage(tester);
      final badge = tester.getCenter(find.bySemanticsLabel('첫날 3월 1일 (월)'));

      await showQr(tester);

      expect(qr(), findsOneWidget);
      expect(find.bySemanticsLabel('첫날 3월 1일 (월)'), findsNothing);
      expect((tester.getCenter(qr()).dx - badge.dx).abs(), lessThan(1));
      expect(find.text(link), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(link)).dy,
        greaterThan(tester.getBottomLeft(qr()).dy),
      );
      expect(
        tester.getBottomLeft(qr()).dy,
        lessThan(tester.getTopLeft(find.text('링크 공유')).dy),
        reason: '두 단추는 그대로 QR 아래에 있다',
      );
      expect(toggle('QR 가리기'), findsOneWidget);
      expect(toggle('또는 QR로 공유하기'), findsNothing);

      await tester.tap(find.byTooltip('링크 복사'));
      await tester.pumpAndSettle();
      expect(copied, [link]);
      expect(find.text('링크를 복사했습니다'), findsOneWidget);
    });

    testWidgets('글은 가운데이고 양옆 선의 길이가 같다', (tester) async {
      await pumpPage(tester);

      for (final text in ['또는 QR로 공유하기', 'QR 가리기']) {
        final lines = tester
            .widgetList<Divider>(
              find.descendant(of: toggle(text), matching: find.byType(Divider)),
            )
            .toList();
        expect(lines, hasLength(2));
        final rects = [
          for (final line
              in find
                  .descendant(of: toggle(text), matching: find.byType(Divider))
                  .evaluate())
            tester.getRect(find.byWidget(line.widget)),
        ];
        expect(rects[0].width, closeTo(rects[1].width, 1), reason: text);
        final row = tester.getRect(toggle(text));
        expect(
          tester.getCenter(find.text(text)).dx,
          closeTo(row.center.dx, 1),
          reason: text,
        );
        if (text == '또는 QR로 공유하기') await showQr(tester);
      }
    });

    testWidgets('QR 가리기를 누르면 달력 그림으로 돌아온다', (tester) async {
      await pumpPage(tester);
      await showQr(tester);

      await tester.ensureVisible(toggle('QR 가리기'));
      await tester.tap(toggle('QR 가리기'));
      await tester.pumpAndSettle();

      expect(qr(), findsNothing);
      expect(find.text(link), findsNothing);
      expect(find.bySemanticsLabel('첫날 3월 1일 (월)'), findsOneWidget);
      expect(toggle('또는 QR로 공유하기'), findsOneWidget);
    });

    testWidgets(
      'QR은 링크를 오류 정정 M으로 담고, 테마와 상관없이 흰 바탕(가장자리 4칸)에 검은 칸이며 200 크기다',
      (tester) async {
        await pumpPage(tester, theme: ThemeData.dark());
        await showQr(tester);

        final painter =
            tester
                    .widget<CustomPaint>(
                      find.descendant(
                        of: qr(),
                        matching: find.byType(CustomPaint),
                      ),
                    )
                    .painter!
                as MeetingQrPainter;
        final expected = QrImage(
          QrCode(
            payload: QrPayload.fromString(link),
            errorCorrectLevel: QrErrorCorrectLevel.medium,
          ),
        );
        expect(painter.image.moduleCount, expected.moduleCount);
        for (final (row, col) in [
          (0, 0),
          (6, 6),
          (7, 7),
          (3, 3),
          (8, 8),
          (expected.moduleCount - 1, 0),
          (0, expected.moduleCount - 1),
          (expected.moduleCount ~/ 2, expected.moduleCount ~/ 2),
        ]) {
          expect(
            painter.image.isDark(row, col),
            expected.isDark(row, col),
            reason: '($row, $col)',
          );
        }

        final size = tester.getSize(qr());
        expect(size, const Size(200, 200));
        final module = size.width / (expected.moduleCount + 8);
        expect(
          find.descendant(of: qr(), matching: find.byType(CustomPaint)),
          paints
            ..rect(rect: Offset.zero & size, color: Colors.white)
            ..rect(
              rect: Rect.fromLTWH(4 * module, 4 * module, module, module),
              color: Colors.black,
            ),
        );
      },
    );

    testWidgets('좁은 화면에서는 QR을 화면 폭에 맞춰 줄이고 넘치지 않는다', (tester) async {
      await pumpPage(tester, size: const Size(200, 800));
      await showQr(tester);

      final size = tester.getSize(qr());
      expect(size.width, lessThan(200));
      expect(size.width, size.height);
      expect(tester.takeException(), isNull);
    });

    testWidgets('바뀌는 동안 같은 자리에서 달력 그림이 QR로 넘어간다', (tester) async {
      await pumpPage(tester);
      await tester.tap(toggle('또는 QR로 공유하기'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.bySemanticsLabel('첫날 3월 1일 (월)'), findsOneWidget);
      expect(qr(), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('첫날 3월 1일 (월)'), findsNothing);
    });

    testWidgets('애니메이션을 줄였으면 움직임 없이 바로 바뀐다', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpPage(tester);

      await tester.tap(toggle('또는 QR로 공유하기'));
      await tester.pump();

      expect(find.bySemanticsLabel('첫날 3월 1일 (월)'), findsNothing);
      expect(qr(), findsOneWidget);
      expect(tester.getSize(qr()), const Size(200, 200));
      final turned = tester
          .widgetList<Transform>(
            find.ancestor(of: qr(), matching: find.byType(Transform)),
          )
          .map((transform) => transform.transform.getRotation().entry(0, 0));
      expect(turned, everyElement(closeTo(1, 1e-9)), reason: '돌아가 있지 않다');
    });
  });
}
