import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_edit.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_edit_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_create_form.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_edit_actions.dart';

/// 모임 설정 폼: 만들기의 펼친 폼([MeetingCreateForm])에 [base]의 값을 채워 고친다. 규칙과 저절로 맞추는 것은
/// 만들기와 같다.
///
/// 저장하기는 바꾼 것이 있을 때만 누를 수 있고, 누르면 폼의 값과 적은 제목을 [onSave]에 넘긴다. 참여자가 이미 답을
/// 넣었으면([hasAnswers]) 방식을 바꾸거나 날이 빠질 때 저장 전에 한 줄로 알린다. 서버가 거절한 칸은
/// [refusals]로 그 아래에, 저장하지 못한 것은 [outcome]으로 저장하기 아래에 알린다. 맨 아래는 '모임 삭제'다.
/// 고칠 때마다 [onEdited]를 부른다
class MeetingEditFormView extends StatefulWidget {
  const MeetingEditFormView({
    super.key,
    required this.base,
    required this.hasAnswers,
    required this.today,
    required this.placeholder,
    required this.saving,
    required this.deleting,
    required this.accessAsked,
    required this.refusals,
    required this.outcome,
    required this.onEdited,
    required this.onSave,
    required this.onDelete,
  });

  /// 지금 서버의 값. 폼은 처음 받은 값으로 채우고, 저장할 것은 지금 값과 비교해 고른다
  final MeetingEditBase base;

  /// 참여자가 넣은 답이 있는지(저장 전 알림은 이때만 보인다)
  final bool hasAnswers;

  /// 달력의 오늘
  final DateTime today;

  /// 제목을 비웠을 때 보이고 저장하는 제목
  final String placeholder;
  final bool saving;
  final bool deleting;

  /// 비공개인데 참여할 사람을 정하지 않고 저장하기를 눌렀다
  final bool accessAsked;

  /// 서버가 거절한 칸과 그 아래에 보일 말
  final Map<MeetingEditPart, String> refusals;

  /// 저장하지 못한 것을 알리는 말. null이면 알리지 않는다
  final String? outcome;
  final VoidCallback onEdited;

  /// 폼의 값과 제목 칸에 적은 글
  final void Function(MeetingFlow flow, String title) onSave;
  final VoidCallback onDelete;

  @override
  State<MeetingEditFormView> createState() => _MeetingEditFormViewState();
}

class _MeetingEditFormViewState extends State<MeetingEditFormView> {
  late var _flow = MeetingFlow(draft: widget.base.draft, expanded: true);
  late final _title = TextEditingController(text: widget.base.meeting.title)
    ..addListener(_titleChanged);

  String get _titleText {
    final typed = _title.text.trim();
    return typed.isEmpty ? widget.placeholder : typed;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _titleChanged() {
    setState(() {});
    widget.onEdited();
  }

  void _change(MeetingFlow next) {
    setState(() => _flow = next);
    widget.onEdited();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.base;
    final draft = _flow.draft;
    final steps = base.plan(draft, title: _titleText);
    final busy = widget.saving || widget.deleting;
    return MeetingCreateForm(
      flow: _flow,
      today: widget.today,
      accessAsked: widget.accessAsked,
      accessRequiredText: meetingEditAccessRequired,
      timezone: base.meeting.timezone,
      refusals: widget.refusals,
      onChanged: _change,
      titleField: MeetingEditActions(
        controller: _title,
        placeholder: widget.placeholder,
        notices: [
          if (widget.hasAnswers)
            for (final notice in base.notices(draft))
              meetingEditNoticeText(notice),
        ],
        saving: widget.saving,
        onSave: busy || (steps != null && steps.isEmpty)
            ? null
            : () => widget.onSave(_flow, _title.text),
        titleRefusal: widget.refusals[MeetingEditPart.title],
        outcome: widget.outcome,
      ),
      footer: TextButton.icon(
        onPressed: busy ? null : widget.onDelete,
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
          minimumSize: const Size(48, 48),
        ),
        icon: const Icon(Icons.delete_outline),
        label: const Text(meetingDelete),
      ),
    );
  }
}
