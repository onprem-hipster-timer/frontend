import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/utils/time_formatters.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_month_cell_view.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view_view.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard_controls_view.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard_view.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dial.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_status_selector_view.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/editable_todo_tree_tile_view.dart';
import 'package:momeet/features/trial/domain/trial_flow.dart';
import 'package:momeet/features/trial/presentation/pages/trial_preview_page.dart';
import 'package:momeet/features/trial/presentation/utils/trial_preview_kind.dart';
import 'package:momeet/features/trial/presentation/utils/trial_texts.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_inert.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 시험은 12월 2일(수), 약속은 사흘 전이 앞 달이라 사흘 뒤 12월 5일(토)
final _now = DateTime(2026, 11, 25, 10);

/// 미리보기 종류마다 랜딩이 고를 수 있는 가장 작은·흔한·가장 큰 크기
const _sizes = {
  TrialPreviewKind.calendar: [
    Size(272, 200),
    Size(272, 260),
    Size(360, 230),
    Size(480, 200),
    Size(480, 260),
  ],
  TrialPreviewKind.todo: [
    Size(272, 88),
    Size(272, 140),
    Size(360, 112),
    Size(480, 88),
    Size(480, 140),
  ],
  TrialPreviewKind.timer: [
    Size(272, 300),
    Size(272, 440),
    Size(360, 380),
    Size(480, 300),
    Size(480, 440),
  ],
};

/// 만든 프로바이더를 모두 적는다
final class _Created extends ProviderObserver {
  final providers = <String>[];

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) =>
      providers.add('${context.provider}');
}

/// [size] 화면에 [kind] 미리보기를 연다. 앱은 밝기에 따라 밝은·어두운 테마를 고른다
Future<void> _open(
  WidgetTester tester,
  TrialPreviewKind kind, {
  Size size = const Size(360, 240),
  DateTime? now,
  Future<void> Function()? fontWeights,
  ValueChanged<String>? onReady,
  List<ProviderObserver> observers = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      observers: observers,
      child: MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ko', 'KR')],
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: TrialPreviewPage(
          kind: kind,
          now: () => now ?? _now,
          fontWeights: fontWeights ?? () async {},
          onReady: onReady ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 화면 안에 다 들어온 [finder]의 것. 달력은 넘기기 위해 앞뒤 기간도 화면 밖에 그려 둔다
List<Rect> _shown(WidgetTester tester, Finder finder) {
  final screen = (Offset.zero & tester.view.physicalSize).inflate(0.5);
  return [
        for (final element in finder.evaluate())
          tester.getRect(find.byElementPredicate((e) => identical(e, element))),
      ]
      .where(
        (rect) =>
            screen.contains(rect.topLeft) && screen.contains(rect.bottomRight),
      )
      .toList();
}

/// 시트·대화상자·메뉴·알림이 하나도 없고 화면도 그대로다
void _expectNothingOpened(WidgetTester tester) {
  expect(find.byType(BottomSheet), findsNothing);
  expect(find.byType(Dialog), findsNothing);
  expect(find.byType(PopupMenuItem<TodoStatus>), findsNothing);
  expect(find.byType(SnackBar), findsNothing);
  expect(find.byType(TrialPreviewPage), findsOneWidget);
  expect(
    tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
    isFalse,
  );
}

/// 지금 키보드 포커스가 미리보기 안에 있다
bool _focusInPreview() {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  return find
      .ancestor(
        of: find.byElementPredicate((element) => identical(element, focused)),
        matching: find.byType(TrialInert),
      )
      .evaluate()
      .isNotEmpty;
}

/// 위아래로 굴려야 보이는 것이 없다
void _expectNothingScrolledAway(WidgetTester tester) {
  for (final element in find.byType(Scrollable).evaluate()) {
    final position = (element as StatefulElement).state as ScrollableState;
    if (position.position.axis == Axis.vertical) {
      expect(position.position.maxScrollExtent, 0);
    }
  }
}

/// [day]의 날짜 칸 가운데 화면 안의 것
CalendarMonthCellView _cellOf(WidgetTester tester, DateTime day) {
  final screen = Offset.zero & tester.view.physicalSize;
  return find
      .byType(CalendarMonthCellView)
      .evaluate()
      .map((element) => element.widget as CalendarMonthCellView)
      .singleWhere(
        (cell) =>
            DateUtils.isSameDay(cell.date, day) &&
            screen.contains(tester.getCenter(find.byWidget(cell))),
      );
}

/// 달력에서 [title] 일정이 [day] 칸 안에 이번 달 날짜로 보인다
void _expectScheduleOnDay(WidgetTester tester, String title, DateTime day) {
  final cell = _cellOf(tester, day);
  expect(cell.isCurrentMonth, isTrue, reason: '$day');
  final cellRect = tester.getRect(find.byWidget(cell));
  final titles = _shown(tester, find.textContaining(title));
  expect(
    titles.where(
      (rect) =>
          rect.center.dx > cellRect.left && rect.center.dx < cellRect.right,
    ),
    isNotEmpty,
    reason: '$title on $day',
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  group('미리보기는 랜딩이 고르는 크기마다 넘치지 않고 보일 것을 화면 안에 담는다', () {
    for (final MapEntry(key: kind, value: sizes) in _sizes.entries) {
      for (final size in sizes) {
        testWidgets(
          '${kind.name} 미리보기를 ${size.width.toInt()}×${size.height.toInt()}로 연다',
          (tester) async {
            await _open(tester, kind, size: size);

            expect(tester.takeException(), isNull);
            _expectNothingScrolledAway(tester);
            switch (kind) {
              case TrialPreviewKind.calendar:
                expect(find.byType(CalendarViewWidgetView), findsOneWidget);
                _expectScheduleOnDay(
                  tester,
                  trialExamTitle,
                  DateTime(2026, 12, 2),
                );
                _expectScheduleOnDay(
                  tester,
                  trialDinnerTitle,
                  DateTime(2026, 12, 5),
                );
              case TrialPreviewKind.todo:
                expect(find.byType(EditableTodoTreeTileView), findsOneWidget);
                expect(find.byType(TodoStatusSelectorView), findsOneWidget);
                for (final text in [
                  trialExamTitle,
                  trialExamTag,
                  formatDuration(const Duration(minutes: 10)),
                ]) {
                  expect(
                    _shown(tester, find.text(text)),
                    hasLength(1),
                    reason: text,
                  );
                }
              case TrialPreviewKind.timer:
                expect(find.byType(TimerDashboardView), findsOneWidget);
                expect(_shown(tester, find.byType(TimerDial)), hasLength(1));
                expect(
                  _shown(tester, find.byType(TimerDashboardControlsView)),
                  hasLength(1),
                );
                for (final text in [
                  trialExamTitle,
                  formatDuration(const Duration(minutes: 15)),
                ]) {
                  expect(
                    _shown(tester, find.text(text)),
                    hasLength(1),
                    reason: text,
                  );
                }
            }
          },
        );
      }
    }
  });

  group('미리보기는 보이기만 하고 무엇에도 반응하지 않는다', () {
    for (final kind in TrialPreviewKind.values) {
      final size = _sizes[kind]![2];

      testWidgets(
        '${kind.name} 미리보기에서 Tab·Shift+Tab을 눌러도 포커스가 들어가지 않고, Enter·Space·방향키로 아무것도 열리지 않는다',
        (tester) async {
          await _open(tester, kind, size: size);

          for (final reverse in [false, true]) {
            for (var i = 0; i < 8; i++) {
              if (reverse) {
                await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
              }
              await tester.sendKeyEvent(LogicalKeyboardKey.tab);
              if (reverse) {
                await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
              }
              await tester.pump();
              expect(_focusInPreview(), isFalse);
              for (final key in [
                LogicalKeyboardKey.enter,
                LogicalKeyboardKey.space,
                LogicalKeyboardKey.arrowUp,
                LogicalKeyboardKey.arrowDown,
                LogicalKeyboardKey.arrowLeft,
                LogicalKeyboardKey.arrowRight,
              ]) {
                await tester.sendKeyEvent(key);
              }
              await tester.pumpAndSettle();
            }
          }
          _expectNothingOpened(tester);
        },
      );

      testWidgets('${kind.name} 미리보기의 글과 컨트롤을 눌러도 아무것도 열리지 않는다', (
        tester,
      ) async {
        await _open(tester, kind, size: size);
        final targets = [
          ..._shown(tester, find.byType(Text)),
          ..._shown(tester, find.byType(Icon)),
          Offset.zero & size,
        ];

        for (final rect in targets) {
          await tester.tapAt(rect.center);
          await tester.longPressAt(rect.center);
          await tester.pumpAndSettle();
        }
        _expectNothingOpened(tester);
      });

      testWidgets('${kind.name} 미리보기는 스크린 리더에 글을 읽히지만 누르기 동작은 하나도 내놓지 않는다', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await _open(tester, kind, size: size);

        expect(
          find.semantics.byPredicate(
            (node) => node.getSemanticsData().label.contains(trialExamTitle),
          ),
          findsAny,
        );
        expect(
          find.semantics.byPredicate((node) {
            final data = node.getSemanticsData();
            return data.hasAction(SemanticsAction.tap) ||
                data.hasAction(SemanticsAction.longPress);
          }),
          findsNothing,
        );
        semantics.dispose();
      });
    }

    testWidgets('세 미리보기를 차례로 열어도 앱의 프로바이더는 하나도 만들어지지 않는다', (tester) async {
      final created = _Created();
      for (final kind in TrialPreviewKind.values) {
        await _open(tester, kind, observers: [created]);
      }

      expect(created.providers, isEmpty);
    });

    testWidgets('미리보기는 다 그린 뒤에 더 그릴 프레임을 남기지 않는다', (tester) async {
      for (final kind in TrialPreviewKind.values) {
        await _open(tester, kind, size: _sizes[kind]!.last);

        expect(tester.binding.hasScheduledFrame, isFalse, reason: kind.name);
      }
    });
  });

  group('달력 미리보기는 견본 일정이 어느 날에 놓여도 두 일정을 이번 달 칸에 보인다', () {
    final cases = {
      '시험이 달의 첫 주 첫날': DateTime(2026, 2, 22, 10),
      '시험이 달의 마지막 주': DateTime(2026, 3, 24, 10),
      '약속이 시험 사흘 전': DateTime(2026, 11, 10, 10),
      '두 일정이 앞 달 끝에서 시작하는 같은 주': DateTime(2026, 3, 25, 10),
      '시험 사흘 전이 앞 달이라 약속이 사흘 뒤': _now,
      '시험이 달의 마지막 날인 토요일': DateTime(2026, 10, 24, 10),
      '12월 말에 열어 시험이 새해 첫 주': DateTime(2026, 12, 26, 10),
      '12월 말에 열어 약속이 새해 첫날': DateTime(2026, 12, 28, 10),
    };
    for (final MapEntry(key: label, value: now) in cases.entries) {
      testWidgets('$label이면 두 일정이 그날 칸에 보인다', (tester) async {
        final days = trialDays(DateTime(now.year, now.month, now.day));

        await _open(
          tester,
          TrialPreviewKind.calendar,
          size: const Size(360, 230),
          now: now,
        );

        _expectScheduleOnDay(tester, trialExamTitle, days.exam);
        _expectScheduleOnDay(tester, trialDinnerTitle, days.dinner);
      });
    }
  });

  testWidgets('기기가 어두운 모드여도 미리보기는 앱의 밝은 테마의 바탕색으로 그린다', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    for (final kind in TrialPreviewKind.values) {
      await _open(tester, kind, size: _sizes[kind]![2]);

      expect(
        Theme.of(tester.element(find.byType(TrialPreviewPage))).brightness,
        Brightness.dark,
        reason: '앱은 어두운 테마다',
      );
      final inside = Theme.of(tester.element(find.text(trialExamTitle).first));
      expect(inside.brightness, Brightness.light, reason: kind.name);
      expect(
        tester
            .widget<Material>(
              find
                  .descendant(
                    of: find.byType(TrialPreviewPage),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .color,
        AppTheme.light().colorScheme.surface,
        reason: kind.name,
      );
    }
  });

  group('미리보기는 글꼴 굵기를 다 받은 뒤에 찍을 준비가 됐다고 한 번 알린다', () {
    for (final kind in TrialPreviewKind.values) {
      testWidgets('${kind.name} 미리보기는 굵기를 받기 전에는 알리지 않고, 받으면 종류 이름으로 한 번 알린다', (
        tester,
      ) async {
        final fonts = Completer<void>();
        final ready = <String>[];
        await _open(
          tester,
          kind,
          size: _sizes[kind]![2],
          fontWeights: () => fonts.future,
          onReady: ready.add,
        );
        expect(ready, isEmpty);

        fonts.complete();
        await tester.pumpAndSettle();
        await tester.pump();

        expect(ready, [kind.name]);
      });
    }

    testWidgets('굵기를 받지 못해도 찍을 준비가 됐다고 한 번 알린다', (tester) async {
      final fonts = Completer<void>();
      final ready = <String>[];
      await _open(
        tester,
        TrialPreviewKind.calendar,
        fontWeights: () => fonts.future,
        onReady: ready.add,
      );
      expect(ready, isEmpty);

      fonts.completeError(Exception('받지 못함'));
      await tester.pumpAndSettle();
      await tester.pump();

      expect(ready, [TrialPreviewKind.calendar.name]);
    });
  });
}
