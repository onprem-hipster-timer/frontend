import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_edit.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_edit_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_form_access.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_form_settings.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

final _ranges = {
  '나흘 (시간별 가능)': MeetingDates.range(
    DateTime.utc(2027, 3, 2),
    DateTime.utc(2027, 3, 5),
  ),
  '열흘 (시간별 불가)': MeetingDates.range(
    DateTime.utc(2027, 3, 2),
    DateTime.utc(2027, 3, 11),
  ),
};

const _modes = {
  '시간별': MeetingMode.hourly,
  '날짜별': MeetingMode.daily,
  '요일별': MeetingMode.weekly,
};

final _refusals = {
  '없음': const <MeetingEditPart, String>{},
  for (final (label, part) in const [
    ('받는 방식', MeetingEditPart.mode),
    ('공개 범위', MeetingEditPart.visibility),
    ('게스트 로그인', MeetingEditPart.guests),
  ])
    label: {part: meetingEditRefusalText(part)},
};

@widgetbook.UseCase(
  name: '모임 시간·공개 설정',
  type: MeetingFormSettings,
  path: '[모임]/모임 만들기',
)
Widget meetingFormSettings(BuildContext context) {
  final knobs = context.knobs;
  final range = knobs.object.dropdown(
    label: '고른 기간',
    description: '시간별은 5일까지라 그보다 길면 시간별을 고를 수 없다',
    options: _ranges.keys.toList(),
  );
  final mode = knobs.object.dropdown(
    label: '받는 방식',
    options: _modes.keys.toList(),
  );
  final public = knobs.boolean(
    label: '공개',
    description: '끄면 아래에 참여할 사람 칸이 열리고 게스트 로그인을 고를 수 없다',
    initialValue: true,
  );
  final refusal = knobs.object.dropdown(
    label: '저장하지 못한 칸',
    description: '모임 설정에서 저장하기를 눌렀는데 서버가 받지 않은 칸',
    options: _refusals.keys.toList(),
  );
  final timezone = knobs.boolean(
    label: '시간 기준 표시',
    description: '기기 시간대를 아직 모르면 줄이 없다',
    initialValue: true,
  );
  // 시간별을 받을 수 없는 기간이면 앱처럼 날짜별에 머문다
  final draft = MeetingDraft(
    mode: MeetingMode.daily,
    dates: _ranges[range]!,
  ).withMode(_modes[mode]!).withPublic(public);
  // 앱의 펼친 만들기 폼(모임 설정)에서 날짜 아래, 제목 위에 놓인다
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: _Settings(
      key: ValueKey((range, mode, public)),
      initial: MeetingFlow(draft: draft, expanded: true),
      timezone: timezone ? 'Asia/Seoul' : null,
      refusals: _refusals[refusal]!,
    ),
  );
}

/// 앱의 만들기 폼처럼 값을 바꾸고, 공개를 끄며 게스트 로그인이 꺼지면 그 줄을 떤다
class _Settings extends StatefulWidget {
  const _Settings({
    super.key,
    required this.initial,
    required this.timezone,
    required this.refusals,
  });

  final MeetingFlow initial;
  final String? timezone;
  final Map<MeetingEditPart, String> refusals;

  @override
  State<_Settings> createState() => _SettingsState();
}

class _SettingsState extends State<_Settings> {
  late var _flow = widget.initial;
  var _guestShakes = 0;

  void _changed(MeetingDraft draft) =>
      setState(() => _flow = _flow.withDraft(draft));

  void _setPublic(bool value) {
    final next = _flow.draft.withPublic(value);
    setState(() {
      if (next.allowGuests != _flow.draft.allowGuests) _guestShakes++;
      _flow = _flow.withDraft(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final flow = _flow;
    return MeetingFormSettings(
      draft: flow.draft,
      timezone: widget.timezone,
      modeShakes: 0,
      guestShakes: _guestShakes,
      adjusted: flow.adjusted,
      onChanged: _changed,
      onModeChanged: (mode) => setState(() => _flow = flow.changeMode(mode)),
      onPublicChanged: _setPublic,
      refusals: widget.refusals,
      access: MeetingFormAccess(
        draft: flow.draft,
        asked: false,
        onChanged: _changed,
      ),
    );
  }
}
