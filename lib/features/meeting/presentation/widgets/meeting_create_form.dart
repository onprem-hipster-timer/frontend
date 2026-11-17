import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_calendar.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_create_layout.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_form_settings.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_section_title.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';

/// '전체 설정 펼치기'로 펼친 모임 만들기 폼: 날짜, 시간, 공개·게스트, 제목과 화살표를 한 번에 보인다. 넓으면
/// 날짜를 왼쪽, 나머지를 오른쪽에 두고, 좁으면 같은 순서로 쌓는다.
///
/// 달력은 '기간'이면 시작하는 날과 끝나는 날을 차례로(요일별은 시작하는 날만) 고르고, '제외할 날'이면 기간
/// 안의 날을 빼거나 되돌린다. 값이 규칙에 걸려 저절로 바뀌면 묻지 않고 바꾼 뒤 그 자리를 떤다.
///
/// 테스트: test/features/meeting/presentation/pages/meeting_create_page_test.dart
class MeetingCreateForm extends StatefulWidget {
  const MeetingCreateForm({
    super.key,
    required this.flow,
    required this.today,
    required this.timezone,
    required this.titleField,
    required this.onChanged,
  });

  final MeetingFlow flow;
  final DateTime today;

  /// 아직 모르면 null
  final String? timezone;

  /// 제목 칸과 만들기 화살표
  final Widget titleField;

  final ValueChanged<MeetingFlow> onChanged;

  @override
  State<MeetingCreateForm> createState() => _MeetingCreateFormState();
}

class _MeetingCreateFormState extends State<MeetingCreateForm> {
  /// 달력이 제외할 날을 고르는지
  var _excluding = false;

  /// 시간별에서 날짜별로 저절로 바뀐 횟수
  var _modeShakes = 0;

  /// 공개를 꺼서 게스트 로그인이 저절로 꺼진 횟수
  var _guestShakes = 0;

  MeetingFlow get _flow => widget.flow;

  /// 기간 안에 뺄 수 있는 날이 있고 요일별이 아니면 제외할 날을 고를 수 있다
  bool get _canExclude =>
      _flow.draft.dates.span > 2 && _flow.draft.mode != MeetingMode.weekly;

  bool get _excludingNow => _excluding && _canExclude;

  void _tapDay(DateTime day) {
    final dates = _flow.draft.dates;
    if (_excludingNow && dates.inPeriod(day) && !dates.canExclude(day)) {
      showAppSnackBar(context, meetingEndsNotExcludable);
      return;
    }
    final next = _flow.tapDayInForm(day, excluding: _excludingNow);
    if (next.draft.mode != _flow.draft.mode) setState(() => _modeShakes++);
    widget.onChanged(next);
  }

  void _setPublic(bool value) {
    final next = _flow.draft.withPublic(value);
    if (next.allowGuests != _flow.draft.allowGuests) {
      setState(() => _guestShakes++);
    }
    widget.onChanged(_flow.withDraft(next));
  }

  @override
  Widget build(BuildContext context) {
    final flow = _flow;
    return MeetingCreateLayout(
      builder: (context, wide) {
        final dates = _FormDates(
          excluding: _excludingNow,
          canExclude: _canExclude,
          weekly: flow.draft.mode == MeetingMode.weekly,
          canExcludeWeekends:
              _excludingNow &&
              flow.draft.dates.weekendsInside.any(flow.draft.dates.contains),
          onExcludingChanged: (value) => setState(() => _excluding = value),
          onExcludeWeekends: () => widget.onChanged(
            flow.withDraft(
              flow.draft.withDates(flow.draft.dates.withoutWeekends()),
            ),
          ),
          calendar: MeetingCalendar(
            firstDay: widget.today,
            shownDay:
                flow.rangeStart ??
                (flow.draft.dates.isEmpty ? null : flow.draft.dates.first),
            stateOf: (day) => flow.dayState(
              day,
              today: widget.today,
              excluding: _excludingNow,
            ),
            onDayTap: _tapDay,
          ),
        );
        final settings = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MeetingFormSettings(
              draft: flow.draft,
              timezone: widget.timezone,
              modeShakes: _modeShakes,
              guestShakes: _guestShakes,
              onChanged: (draft) => widget.onChanged(flow.withDraft(draft)),
              onPublicChanged: _setPublic,
            ),
            const SizedBox(height: 28),
            widget.titleField,
          ],
        );
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [dates, const SizedBox(height: 24), settings],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: dates),
            const SizedBox(width: 40),
            Expanded(child: settings),
          ],
        );
      },
    );
  }
}

/// 펼친 폼의 '모임 날짜': 기간 / 제외할 날 고르기, 주말 제외, 달력
class _FormDates extends StatelessWidget {
  const _FormDates({
    required this.excluding,
    required this.canExclude,
    required this.weekly,
    required this.canExcludeWeekends,
    required this.onExcludingChanged,
    required this.onExcludeWeekends,
    required this.calendar,
  });

  final bool excluding;
  final bool canExclude;
  final bool weekly;
  final bool canExcludeWeekends;
  final ValueChanged<bool> onExcludingChanged;
  final VoidCallback onExcludeWeekends;
  final Widget calendar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MeetingSectionTitle(
          meetingFormDatesTitle,
          caption: excluding
              ? meetingFormExcludeGuide
              : weekly
              ? meetingFormWeeklyGuide
              : meetingRangeGuide,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                const ButtonSegment(
                  value: false,
                  label: Text(meetingFormRangeSegment),
                ),
                ButtonSegment(
                  value: true,
                  label: const Text(meetingFormExcludeSegment),
                  enabled: canExclude,
                ),
              ],
              selected: {excluding},
              onSelectionChanged: (selection) =>
                  onExcludingChanged(selection.first),
            ),
            if (canExcludeWeekends)
              TextButton.icon(
                onPressed: onExcludeWeekends,
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                icon: const Icon(Icons.weekend_outlined),
                label: const Text(meetingExcludeWeekends),
              ),
          ],
        ),
        const SizedBox(height: 12),
        calendar,
      ],
    );
  }
}
