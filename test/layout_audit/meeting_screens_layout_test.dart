@Tags(['layout_audit'])
library;

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart' show Tags;
import 'package:go_router/go_router.dart';
import 'package:layout_audit/layout_audit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_create_page.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_created_page.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_page.dart';
import 'package:momeet/shared/ui/ui.dart';

import '../features/meeting/meeting_fixtures.dart';

/// 모임 만들기·만든 뒤·모임 화면을 화면 크기 × 글자 배율 × 긴 문구로 점검한다.
///
/// 사용자가 정하는 글자(제목 자리 글자의 이름, 모임 제목)에 [StressText]를 넣는다.
/// 모임 화면들은 go_router로 이동하므로 라우터 안에 띄운다.
void main() {
  Widget routed(Widget page, List<Override> overrides) => ProviderScope(
    retry: appRetry,
    overrides: overrides,
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
    'meeting_create_page',
    subject: '제목 자리 글자의 이름',
    build: (text) => routed(
      const MeetingCreatePage(),
      meetingOverrides(meetings: FakeMeetingsClient(), name: text.value),
    ),
  );

  testLayoutAudit(
    'meeting_created_page',
    subject: '안내',
    texts: const [StressTexts.koreanLong],
    build: (text) => routed(
      const MeetingCreatedPage(meetingId: 'meeting-1'),
      meetingOverrides(
        meetings: FakeMeetingsClient(
          meeting: makeMeeting(startDate: DateTime.utc(2027, 9, 30)),
        ),
      ),
    ),
  );

  testLayoutAudit(
    'meeting_page',
    subject: '모임 제목',
    build: (text) => routed(
      const MeetingPage(meetingId: 'meeting-1'),
      meetingOverrides(
        meetings: FakeMeetingsClient(
          meeting: makeMeeting(
            title: text.value,
            startDate: DateTime.utc(2027, 3, 1),
            endDate: DateTime.utc(2027, 3, 15),
            availableDays: [0, 4],
          ),
        ),
      ),
    ),
  );
}
