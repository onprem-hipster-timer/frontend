@Tags(['layout_audit'])
library;

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' show Tags, setUpAll;
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:layout_audit/layout_audit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/trial/presentation/pages/trial_page.dart';
import 'package:momeet/features/trial/presentation/pages/trial_preview_page.dart';
import 'package:momeet/features/trial/presentation/utils/trial_preview_kind.dart';
import 'package:momeet/features/trial/presentation/utils/trial_samples.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_end.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_timer_dashboard.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_todo_row.dart';
import 'package:momeet/shared/ui/ui.dart';

import '../helpers/layout_audit_app.dart';

/// 체험하기 화면과 단계마다의 앱 위젯을 화면 크기 × 글자 배율로 점검한다.
///
/// 체험하기의 글은 정해진 견본이라 사용자가 넣는 글자가 없다. 한국어 긴 글 한 가지로만 점검한다.
void main() {
  final now = DateTime(2026, 11, 25, 10);
  final started = trialStart(
    now,
  ).openExam().convert().openTodo().startTimer(const Duration(minutes: 25));
  final ended = started.openTimer().finishTimer();
  const texts = [StressTexts.koreanLong];

  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  /// 머리띠가 앞 화면을 보므로 GoRouter 안에 연 체험하기
  Widget routed(Widget page) => ProviderScope(
    child: MaterialApp.router(
      routerConfig: GoRouter(
        routes: [GoRoute(path: '/', builder: (context, state) => page)],
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      locale: const Locale('ko', 'KR'),
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
    ),
  );

  testLayoutAudit(
    'trial_page',
    subject: '체험하기 달력',
    texts: texts,
    build: (_) => routed(TrialPage(now: () => now)),
  );

  testLayoutAudit(
    'trial_todo_row',
    subject: '체험하기 할 일 줄',
    texts: texts,
    build: (_) => wrapWithApp()(
      ListView(
        children: [
          TrialTodoRow(todo: started.todo!, onStartTimer: () {}),
          TrialTodoRow(todo: started.todo!, timer: started.timer),
        ],
      ),
    ),
  );

  testLayoutAudit(
    'trial_timer_dashboard',
    subject: '체험하기 타이머',
    texts: texts,
    build: (_) => wrapWithApp()(
      TrialTimerDashboard(
        timer: started.timer!,
        remaining: const Duration(minutes: 12, seconds: 30),
      ),
    ),
  );

  testLayoutAudit(
    'trial_end',
    subject: '체험하기 끝',
    texts: texts,
    build: (_) => wrapWithApp()(
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: TrialEnd(
          todo: ended.todo!,
          recordedSeconds: ended.recordedSeconds,
          onSignUp: () {},
          onCreateMeeting: () {},
        ),
      ),
    ),
  );

  for (final kind in TrialPreviewKind.values) {
    testLayoutAudit(
      'trial_preview_${kind.name}',
      subject: '랜딩 미리보기 ${kind.name}',
      texts: texts,
      build: (_) => wrapWithApp()(
        TrialPreviewPage(
          kind: kind,
          now: () => now,
          fontWeights: () async {},
          onReady: (_) {},
        ),
      ),
    );
  }
}
