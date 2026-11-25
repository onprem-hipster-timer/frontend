import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncValue;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_headcount.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_kept_guest_notice_view.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_link_panel_view.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_login_request_view.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_visitor_body_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../sample_provider_scope.dart';
import 'samples_grid.dart';
import 'samples_guest_form.dart';
import 'samples_meeting_a.dart';
import 'samples_turnstile.dart';

/// 화면 폭 노브의 선택지. null은 미리보기 기기 폭 그대로다
const _widths = <String, double?>{'기기 폭 그대로': null, '1024 (넓은 배치)': 1024};

/// 불러오기 노브의 선택지
enum _Load {
  data('불러옴'),
  loading('불러오는 중'),
  error('불러오지 못함');

  const _Load(this.label);

  final String label;
}

@widgetbook.UseCase(
  name: '로그인 전 모임 화면',
  type: MeetingVisitorBodyView,
  path: '[모임]/모임 화면',
)
Widget meetingVisitorBodyView(BuildContext context) {
  final knobs = context.knobs;
  final width = knobs.object.dropdown(
    label: '화면 폭',
    description:
        "840부터 오른쪽 칸에 로그인 상자를 둔다. 좁으면 로그인 상자 없이 화면 아래에 '내 시간 입력하기'를 붙인다",
    options: _widths.keys.toList(),
  );
  final load = knobs.object.dropdown(
    label: '불러오기',
    options: _Load.values,
    labelBuilder: (load) => load.label,
  );
  final mode = gridModeKnob(
    context,
    description: '모임을 만들 때 고른 방식. 칸 색은 이름 없이 사람 수만 보인다',
  );
  final answers = gridAnswersKnob(
    context,
    description: "'일정 참여자'에는 이름 없이 참여자 수만 보인다",
  );
  final guests = knobs.boolean(
    label: '게스트 받기',
    initialValue: true,
    description: "게스트를 받는 모임이면 '로그인' 옆에 'Guest'를 두고, 누르면 그 자리에서 게스트 폼을 연다",
  );
  final turnstile = turnstileKnob(
    context,
    description: '게스트 폼의 사람 확인 상자(Cloudflare Turnstile) 상태',
  );
  final kept = knobs.boolean(
    label: '따로 둔 게스트',
    description:
        "이 기기에서 게스트로 시간을 넣다가 정규 유저로 바꾸려고 로그인을 그만뒀으면 시간표 위에 '게스트로 계속하기'가 놓인다",
  );
  final meeting = gridMeeting(mode);
  final headcount = switch (load) {
    _Load.data => AsyncValue.data(_headcount(meeting, answers)),
    _Load.loading => const AsyncValue<MeetingHeadcount>.loading(),
    _Load.error => AsyncValue<MeetingHeadcount>.error(
      Exception('연결이 끊겼어요'),
      StackTrace.empty,
    ),
  };
  // 칠하려 하면 넓은 화면은 로그인 상자가 떨고, 좁은 화면은 '내 시간 입력하기' 시트가 올라온다
  return SampleProviderScope(
    key: ValueKey((guests, turnstile)),
    overrides: guestEntryOverrides,
    child: Scaffold(
      body: MeetingWidthFrame(
        width: _widths[width],
        child: Builder(
          builder: (context) => MeetingVisitorBodyView(
            headcount: headcount,
            guests: guests,
            keptGuestNotice: kept
                ? MeetingKeptGuestNoticeView(busy: false, onContinue: () {})
                : const SizedBox.shrink(),
            guestForm: SampleGuestForm(turnstile: turnstile),
            link: (title) => MeetingLinkPanelView(
              meetingId: meeting.id,
              owner: false,
              level: VisibilityLevel.public,
              onShare: () {},
            ),
            onLogin: () {},
            onNudged: () {},
            onRequest: () => _showRequest(context, guests: guests),
            onRetry: () {},
          ),
        ),
      ),
    ),
  );
}

/// 방문자가 보는 [meeting]의 사람 수. [answers]명이 시간을 넣었다
MeetingHeadcount _headcount(MeetingRead meeting, GridAnswers answers) {
  final board = gridBoard(
    meeting,
    viewer: GridViewer.visitor,
    answers: answers,
  );
  return MeetingHeadcount(
    MeetingResultRead(
      meeting: meeting,
      participantCount: answers.count,
      availabilityGrid: [
        for (final cell in board.grid.cells)
          AvailabilityCell(
            startTime: cell.span.start,
            endTime: cell.span.end,
            count: board.othersCountAt(cell),
            unavailableCount: board.othersUnavailableCountAt(cell),
          ),
      ],
    ),
  );
}

/// 좁은 화면에서 칠하려 하면 올라오는 '내 시간 입력하기' 시트
void _showRequest(BuildContext context, {required bool guests}) =>
    showAppSheet<void>(context, builder: (context) => _Request(guests: guests));

/// 'Guest'로 폼을 열고 '뒤로'로 돌아가도록 펼침 상태를 여기서 가진다
class _Request extends StatefulWidget {
  const _Request({required this.guests});

  final bool guests;

  @override
  State<_Request> createState() => _RequestState();
}

class _RequestState extends State<_Request> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final guests = widget.guests;
    return MeetingLoginRequestView(
      guestForm: guests && _open ? const SampleGuestForm() : null,
      onBack: () => setState(() => _open = false),
      onLogin: () => Navigator.of(context).pop(),
      onGuest: guests ? () => setState(() => _open = true) : null,
    );
  }
}
