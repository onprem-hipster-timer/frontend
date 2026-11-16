@Tags(['layout_audit'])
library;

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart'
    show Tags, expect, find, findsOneWidget, setUpAll;
import 'package:go_router/go_router.dart';
import 'package:layout_audit/layout_audit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/auth/guest_user.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/auth/presentation/pages/guest_session_page.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_create_page.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_created_page.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/domain/meeting_names.dart';
import 'package:momeet/features/meeting/presentation/pages/meeting_page.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_autosave.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_sheet.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_guest_steps.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../features/meeting/guest_fixtures.dart';
import '../features/meeting/meeting_fixtures.dart';
import '../helpers/fake_turnstile.dart';
import '../helpers/layout_audit_app.dart';

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

/// 모임 화면을 불러온 뒤 [label] 단추를 한 번 누른 화면(예: 주인의 '편집')
class _PressWhenLoaded extends ConsumerStatefulWidget {
  const _PressWhenLoaded({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  ConsumerState<_PressWhenLoaded> createState() => _PressWhenLoadedState();
}

class _PressWhenLoadedState extends ConsumerState<_PressWhenLoaded> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(meetingBoardProvider('meeting-1'), (_, next) {
      if (_pressed || !next.hasValue) return;
      _pressed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final button = find.widgetWithText(TextButton, widget.label);
        (button.evaluate().first.widget as TextButton).onPressed!();
      });
    });
    return widget.child;
  }
}

/// 방문자 모임 화면을 불러온 뒤 'Guest'를 눌러 게스트 폼을 열고, 이름 [name]을 넣어 찾은 화면
class _GuestFormOpened extends ConsumerStatefulWidget {
  const _GuestFormOpened({required this.name, required this.child});

  final String name;
  final Widget child;

  @override
  ConsumerState<_GuestFormOpened> createState() => _GuestFormOpenedState();
}

class _GuestFormOpenedState extends ConsumerState<_GuestFormOpened> {
  var _opened = false;

  void _afterFrame(VoidCallback action) =>
      WidgetsBinding.instance.addPostFrameCallback((_) => action());

  @override
  Widget build(BuildContext context) {
    ref.listen(meetingHeadcountProvider('meeting-1'), (_, next) {
      if (_opened || !next.hasValue) return;
      _opened = true;
      _afterFrame(() {
        final guest = find.widgetWithText(FilledButton, 'Guest');
        (guest.evaluate().first.widget as FilledButton).onPressed!();
        _afterFrame(() {
          final field = find.byType(EditableText).evaluate().first;
          final editable = field.widget as EditableText;
          editable.controller.text = widget.name;
          editable.focusNode.requestFocus();
          // 이름 칸을 벗어나면 그 이름을 찾는다
          _afterFrame(editable.focusNode.unfocus);
        });
      });
    });
    return widget.child;
  }
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
    'meeting_page_owner_editing',
    subject: '참여자 이름',
    build: (text) => routed(
      const _PressWhenLoaded(
        label: '편집',
        child: MeetingPage(meetingId: 'meeting-1'),
      ),
      meetingOverrides(
        meetings: FakeMeetingsClient(
          meeting: meetingIn('hourly', title: '팀 회의'),
        )..availability = _fivePeople(text.value),
      ),
    ),
    verify: (tester) => expect(find.byTooltip('내 이름 바꾸기'), findsOneWidget),
  );

  for (final mode in ['hourly', 'daily', 'weekly']) {
    testLayoutAudit(
      'meeting_page_visitor_$mode',
      subject: '모임 제목',
      texts: const [StressTexts.koreanLong],
      build: (text) => routed(
        const MeetingPage(meetingId: 'meeting-1'),
        meetingOverrides(
          signedIn: false,
          meetings: FakeMeetingsClient(
            meeting: meetingIn(mode, title: text.value),
          )..availability = _fivePeople('참여자'),
        ),
      ),
    );
  }

  testLayoutAudit(
    'meeting_page_visitor_empty',
    subject: '모임 제목',
    texts: const [StressTexts.koreanLong],
    build: (text) => routed(
      const MeetingPage(meetingId: 'meeting-1'),
      meetingOverrides(
        signedIn: false,
        meetings: FakeMeetingsClient(
          meeting: meetingIn('hourly', title: text.value),
        ),
      ),
    ),
  );

  for (final signedIn in [false, true]) {
    testLayoutAudit(
      'meeting_page_not_found_${signedIn ? 'member' : 'visitor'}',
      subject: '안내',
      texts: const [StressTexts.koreanLong],
      build: (text) => routed(
        const MeetingPage(meetingId: 'meeting-1'),
        meetingOverrides(
          signedIn: signedIn,
          meetings: FakeMeetingsClient(meeting: null)..readError = notFound(),
        ),
      ),
    );
  }

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

  /// 게스트 [name]으로 들어온 모임 화면에 바꿔 끼우는 것
  List<Override> guestOverrides(FakeMeetingsClient meetings, String name) => [
    ...meetingOverrides(
      meetings: meetings..guestName = name,
      guest: GuestUser(id: 'g', handle: 'g@guest.invalid', name: name),
    ),
    guestsApiProvider.overrideWithValue(FakeGuestsClient()),
    FakeTurnstiles().override,
  ];

  for (final returning in [false, true]) {
    testLayoutAudit(
      'meeting_page_guest_entry_${returning ? 'returning' : 'new'}',
      subject: '게스트 이름',
      build: (text) => routed(
        _GuestFormOpened(
          // 게스트 이름은 50자까지다
          name: meetingDisplayName(text.value),
          child: const MeetingPage(meetingId: 'meeting-1'),
        ),
        [
          ...meetingOverrides(
            signedIn: false,
            meetings: FakeMeetingsClient(
              meeting: meetingIn(
                'hourly',
                title: '팀 회의',
              ).copyWith(allowGuests: true),
            ),
          ),
          guestsApiProvider.overrideWithValue(
            FakeGuestsClient()
              ..guests.addAll({
                if (returning)
                  guestName(meetingDisplayName(text.value)): 'g@guest.invalid',
              }),
          ),
          FakeTurnstiles().override,
        ],
      ),
      verify: (tester) => expect(
        returning
            ? find.text('이미 참여한 이름입니다. 본인이면 비밀번호를 입력하세요')
            : find.text('참여하기'),
        findsOneWidget,
      ),
    );
  }

  for (final mode in ['hourly', 'weekly']) {
    testLayoutAudit(
      'meeting_page_guest_$mode',
      subject: '게스트·참여자 이름',
      build: (text) => routed(
        const MeetingPage(meetingId: 'meeting-1'),
        guestOverrides(
          FakeMeetingsClient(meeting: meetingIn(mode, title: '팀 회의'))
            ..availability = _fivePeople(text.value),
          meetingDisplayName(text.value),
        ),
      ),
      verify: (tester) =>
          expect(find.textContaining('진행 중입니다'), findsOneWidget),
    );
  }

  testLayoutAudit(
    'meeting_page_guest_consent',
    subject: '안내',
    texts: const [StressTexts.koreanLong],
    build: (text) => routed(
      const MeetingPage(meetingId: 'meeting-1'),
      guestOverrides(
        FakeMeetingsClient(meeting: meetingIn('hourly', title: '팀 회의'))
          ..participateError = guestError(428, 'ConsentRequiredError'),
        '민수',
      ),
    ),
    verify: (tester) => expect(find.text('동의하고 계속하기'), findsOneWidget),
  );

  testLayoutAudit(
    'meeting_guest_sheet',
    subject: '게스트 이름',
    build: (text) => routed(
      OpenOnStart(
        open: (context) => showAppSheet<String>(
          context,
          builder: (context) => MeetingGuestSheet(
            meetingId: 'meeting-1',
            guest: GuestUser(
              id: 'g',
              handle: 'g@guest.invalid',
              name: meetingDisplayName(text.value),
            ),
          ),
        ),
      ),
      guestOverrides(
        FakeMeetingsClient(meeting: makeMeeting()),
        meetingDisplayName(text.value),
      ),
    ),
  );

  for (final known in [true, false]) {
    testLayoutAudit(
      'guest_session_page_${known ? 'meeting' : 'unknown'}',
      subject: '안내',
      texts: const [StressTexts.koreanLong],
      build: (text) => wrapWithApp(
        overrides: [
          currentGuestProvider.overrideWithValue(
            GuestUser(
              id: 'g',
              handle: 'g@guest.invalid',
              name: '민수',
              meetingId: known ? 'meeting-1' : null,
            ),
          ),
        ],
      )(const GuestSessionPage(redirect: '/todo')),
    );
  }
}
