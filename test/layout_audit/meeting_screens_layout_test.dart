@Tags(['layout_audit'])
library;

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart' show Tags, setUpAll;
import 'package:go_router/go_router.dart';
import 'package:layout_audit/layout_audit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_create_page.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_created_page.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_page.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_autosave.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../features/meeting/meeting_fixtures.dart';

/// 서울 2027년 3월 [day]일 [hour]시의 UTC 시각
DateTime _seoul(int day, int hour) => DateTime.utc(2027, 3, day, hour - 9);

/// 이름이 모두 [name]으로 시작하는 다섯 참여자(첫째가 나이자 주인, 마지막은 게스트). 3월 1일 9~12시에 겹친다
List<AvailabilityRead> _fivePeople(String name) => [
  for (var i = 0; i < 5; i++)
    availabilityOf(
      'p$i',
      name: i == 0 ? name : '$name $i',
      userId: i == 0 ? 'user-1' : null,
      owner: i == 0,
      guest: i == 4,
      slots: [
        (_seoul(1, 9 + i % 2), _seoul(1, 12)),
        (_seoul(2, 0), _seoul(9, 0)),
      ],
    ),
];

/// 저장하지 못한 상태로 여는 모임 화면 값
class _FailedSave extends MeetingBoardNotifier {
  _FailedSave(this.meeting, this.availability);

  final MeetingRead meeting;
  final List<AvailabilityRead> availability;

  @override
  Future<MeetingBoardState> build(String meetingId) async => MeetingBoardState(
    MeetingBoard(
      meeting: meeting,
      availability: availability,
      userId: 'user-1',
      selfName: '지현',
    ),
    status: MeetingSaveStatus.failed,
  );
}

/// 모임 만들기·만든 뒤·모임 화면을 화면 크기 × 글자 배율 × 긴 문구로 점검한다.
///
/// 사용자가 정하는 글자(제목 자리 글자의 이름, 모임 제목)에 [StressText]를 넣는다.
/// 모임 화면들은 go_router로 이동하므로 라우터 안에 띄운다.
void main() {
  setUpAll(tz.initializeTimeZones);

  Widget routed(Widget page, List<Override> overrides) => ProviderScope(
    retry: appRetry,
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: GoRouter(
        routes: [
          GoRoute(path: '/', builder: (context, state) => page),
          // 모임 화면의 링크 상자가 이 이름으로 모임 주소를 만든다
          GoRoute(
            path: AppRoute.meeting.path,
            name: AppRoute.meeting.name,
            builder: (context, state) => page,
          ),
        ],
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

  MeetingRead meetingIn(String mode, {required String title}) => switch (mode) {
    'hourly' => makeMeeting(title: title, ownerId: 'user-1'),
    'daily' => makeMeeting(
      title: title,
      ownerId: 'user-1',
      startDate: DateTime.utc(2027, 3, 1),
      endDate: DateTime.utc(2027, 3, 31),
      availableDays: [0, 1, 2, 3, 4, 5, 6],
      startTime: '00:00:00',
      endTime: '00:00:00',
    ),
    _ => makeMeeting(
      title: title,
      ownerId: 'user-1',
      startDate: DateTime.utc(2027, 3, 3),
      endDate: DateTime.utc(2027, 3, 9),
      availableDays: [0, 1, 2, 3, 4, 5, 6],
      startTime: '00:00:00',
      endTime: '00:00:00',
    ),
  };

  for (final mode in ['hourly', 'daily', 'weekly']) {
    testLayoutAudit(
      'meeting_page_$mode',
      subject: '모임 제목과 참여자 이름',
      build: (text) => routed(
        const MeetingPage(meetingId: 'meeting-1'),
        meetingOverrides(
          meetings: FakeMeetingsClient(
            meeting: meetingIn(mode, title: text.value),
          )..availability = _fivePeople(text.value),
        ),
      ),
    );
  }

  testLayoutAudit(
    'meeting_page_empty',
    subject: '모임 제목',
    texts: const [StressTexts.koreanLong],
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

  testLayoutAudit(
    'meeting_page_save_failed',
    subject: '참여자 이름',
    texts: const [StressTexts.koreanLong],
    build: (text) {
      final meeting = meetingIn('hourly', title: '팀 회의');
      return routed(const MeetingPage(meetingId: 'meeting-1'), [
        ...meetingOverrides(meetings: FakeMeetingsClient(meeting: meeting)),
        meetingBoardProvider.overrideWith(
          () => _FailedSave(meeting, _fivePeople(text.value)),
        ),
      ]);
    },
  );
}
