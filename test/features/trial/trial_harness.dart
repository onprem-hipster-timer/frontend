import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_month_cell_view.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_brush_texts.dart';
import 'package:momeet/features/trial/domain/trial_flow.dart';
import 'package:momeet/features/trial/presentation/pages/trial_page.dart';
import 'package:momeet/features/trial/presentation/utils/trial_texts.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 체험을 연 시각. 시험은 12월 2일, 약속은 12월 5일이다
final trialTestNow = DateTime(2026, 11, 25, 10);
final trialTestExamDay = DateTime(2026, 12, 2);
final trialTestDinnerDay = DateTime(2026, 12, 5);

const signupScreen = '회원가입 화면';
const meetingsScreen = '모임 만들기 화면';

/// 앱이 쓰는 휴대폰 크기와 넓은 크기
const trialSizes = {'휴대폰': Size(360, 800), '넓은 화면': Size(800, 1280)};

/// `/try`에서 여는 체험하기. 가입·모임 만들기는 그 화면 이름만 보인다
Widget trialApp({List<ProviderObserver> observers = const []}) => ProviderScope(
  observers: observers,
  child: MaterialApp.router(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('ko', 'KR')],
    locale: const Locale('ko', 'KR'),
    theme: AppTheme.light(),
    routerConfig: GoRouter(
      initialLocation: AppRoute.trial.path,
      routes: [
        GoRoute(
          path: AppRoute.trial.path,
          name: AppRoute.trial.name,
          builder: (context, state) => TrialPage(now: () => trialTestNow),
        ),
        GoRoute(
          path: AppRoute.signup.path,
          name: AppRoute.signup.name,
          builder: (context, state) => const Text(signupScreen),
        ),
        GoRoute(
          path: AppRoute.meetings.path,
          name: AppRoute.meetings.name,
          builder: (context, state) => const Text(meetingsScreen),
        ),
      ],
    ),
  ),
);

/// [step]을 처음 열었을 때의 큰 질문
Finder headlineOf(TrialStep step) => find.text(
  keepWords(switch (step) {
    TrialStep.calendar => trialCalendarHeadline,
    TrialStep.schedule => trialScheduleHeadline,
    TrialStep.todo => trialTodoHeadline,
    TrialStep.timer => trialTimerHeadline,
    TrialStep.end => trialEndHeadline,
  }),
);

/// 할 일로 바꾼 뒤의 큰 질문
final convertedHeadline = find.text(keepWords(trialConvertedHeadline));

/// 타이머를 시작한 뒤의 큰 질문
final startedHeadline = find.text(keepWords(trialStartedHeadline));

/// [size] 화면에 체험하기를 연다
Future<void> openTrial(
  WidgetTester tester, {
  Size size = const Size(360, 800),
  List<ProviderObserver> observers = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(trialApp(observers: observers));
  await tester.pumpAndSettle();
}

/// 달력에서 [day] 칸의 날짜 숫자 자리를 누른다(일정 막대 위가 아니다)
Future<void> tapCalendarDay(WidgetTester tester, DateTime day) async {
  final cell = find.byWidgetPredicate(
    (widget) =>
        widget is CalendarMonthCellView &&
        DateUtils.isSameDay(widget.date, day),
  );
  // 달력은 넘기기 위해 앞뒤 달도 그려 두므로 화면 안의 칸을 고른다
  final screen = Offset.zero & tester.view.physicalSize;
  final rect = cell
      .evaluate()
      .map((element) => tester.getRect(find.byWidget(element.widget)))
      .firstWhere((rect) => screen.contains(rect.center));
  final topLeft = rect.topLeft;
  final width = rect.width;
  await tester.tapAt(topLeft + Offset(width / 2, 8));
  await tester.pumpAndSettle();
}

final convertLabel = '${Terms.todo.withJosa('으로', '로')} 변환';
const linkedLabel = '연결된 ${Terms.todo} 보기';

/// 달력 → 시험 날짜 → 시트의 시험 → 일정 상세
Future<void> goToSchedule(WidgetTester tester) async {
  await tapCalendarDay(tester, trialTestExamDay);
  await tester.tap(
    find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text(trialExamTitle),
    ),
  );
  await tester.pumpAndSettle();
}

/// 일정 상세에서 변환하고 알림의 '할 일 보기'로 할 일 단계까지
Future<void> goToTodo(WidgetTester tester) async {
  await goToSchedule(tester);
  await tester.tap(find.text(convertLabel));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(SnackBarAction, '${Terms.todo} 보기'));
  await tester.pumpAndSettle();
}

/// 할 일 단계에서 타이머를 시작한다(시트의 '시작'까지)
Future<void> startTimer(WidgetTester tester) async {
  await tester.tap(find.byTooltip('${Terms.timer} 시작'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('시작'));
  await tester.pumpAndSettle();
}

/// 타이머를 시작하고 알림의 '타이머 보기'로 타이머 단계까지. 시간이 지나가기 시작한 첫 프레임에서 멈춘다
Future<void> goToTimer(WidgetTester tester) async {
  await goToTodo(tester);
  await startTimer(tester);
  await tester.tap(find.widgetWithText(SnackBarAction, '${Terms.timer} 보기'));
  await tester.pump();
}

/// 타이머 단계에서 시간이 모두 지나가 끝까지
Future<void> goToEnd(WidgetTester tester) async {
  await goToTimer(tester);
  await tester.pump(trialTimerSweep);
  await tester.pumpAndSettle();
}
