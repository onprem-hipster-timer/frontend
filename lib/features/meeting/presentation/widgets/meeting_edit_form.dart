import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/providers/auth_selectors.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_edit.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_edit_providers.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_edit_texts.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_create_form.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_edit_actions.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 모임 설정: 만들기의 펼친 폼([MeetingCreateForm])에 지금 값을 채워 고친다. 규칙과 저절로 맞추는 것은 만들기와
/// 같다.
///
/// 저장하기는 바꾼 것만 정한 순서로 보낸다([MeetingEditBase.plan]). 모두 저장하면 모임 화면으로 돌아가고, 하나라도
/// 저장하지 못하면 이 화면에 남아 무엇을 저장했고 무엇을 못 했는지 알리며, 다시 읽은 서버 값을 기준으로 남은
/// 것만 다시 보낼 수 있다. 서버가 거절한 칸은 그 아래에 알린다. 참여자가 이미 답을 넣었으면 방식을 바꾸거나
/// 날이 빠질 때 저장 전에 한 줄로 알린다. 맨 아래 '모임 삭제'는 확인한 뒤 지우고 처음 화면으로 간다.
///
/// 테스트: test/features/meeting/presentation/pages/meeting_edit_page_test.dart
class MeetingEditForm extends ConsumerStatefulWidget {
  const MeetingEditForm({super.key, required this.source});

  final MeetingEditSource source;

  @override
  ConsumerState<MeetingEditForm> createState() => _MeetingEditFormState();
}

class _MeetingEditFormState extends ConsumerState<MeetingEditForm> {
  late var _base = widget.source.base;
  late var _flow = MeetingFlow(draft: _base.draft, expanded: true);
  late final _title = TextEditingController(text: _base.meeting.title)
    ..addListener(_titleChanged);
  var _saving = false;
  var _deleting = false;

  /// 비공개인데 참여할 사람을 정하지 않고 저장하기를 눌렀다
  var _accessAsked = false;

  /// 마지막 저장에서 저장하지 못한 것이 있었다(다시 바꾸면 지운다)
  MeetingEditOutcome? _failed;

  String get _meetingId => _base.meeting.id;

  String get _placeholder =>
      meetingTitlePlaceholder(ref.read(currentUserProvider)?.name);

  String get _titleText {
    final typed = _title.text.trim();
    return typed.isEmpty ? _placeholder : typed;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _titleChanged() => setState(() => _failed = null);

  void _change(MeetingFlow next) => setState(() {
    _flow = next;
    _failed = null;
  });

  Future<void> _save() async {
    if (_saving) return;
    if (_flow.rangeStart != null) {
      showAppSnackBar(context, meetingRangeUnfinished);
      return;
    }
    final steps = _base.plan(_flow.draft, title: _titleText);
    if (steps == null) return setState(() => _accessAsked = true);
    if (steps.isEmpty) return;
    setState(() => _saving = true);
    final outcome = await ref
        .read(meetingEditRequestsProvider)
        .save(_base, steps);
    ref.invalidate(meetingProvider(_meetingId));
    if (!mounted) return;
    if (!outcome.complete) {
      return setState(() {
        _saving = false;
        _base = outcome.base;
        _failed = outcome;
      });
    }
    showAppSnackBar(context, meetingEditSaved, kind: AppNoticeKind.success);
    if (context.canPop()) return context.pop();
    context.goNamed(
      AppRoute.meeting.name,
      pathParameters: {'meetingId': _meetingId},
    );
  }

  Future<void> _delete() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: meetingDelete,
      content: meetingDeleteQuestion,
      confirmText: meetingDeleteConfirm,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ref.read(meetingEditRequestsProvider).delete(_meetingId);
    } on Exception {
      if (!mounted) return;
      setState(() => _deleting = false);
      showAppSnackBar(context, meetingDeleteFailed, kind: AppNoticeKind.error);
      return;
    }
    if (!mounted) return;
    showAppSnackBar(context, meetingDeleted);
    context.goNamed(AppRoute.calendar.name);
  }

  @override
  Widget build(BuildContext context) {
    final draft = _flow.draft;
    final steps = _base.plan(draft, title: _titleText);
    final failed = _failed;
    final refusals = {
      if (failed != null)
        for (final part in meetingEditRefused(failed))
          part: meetingEditRefusalText(part),
    };
    // 지난 날에 시작한 모임도 지금 기간을 그대로 보이고 고를 수 있다
    final today = calendarDay(DateTime.now());
    final first = _base.draft.dates.first;
    final busy = _saving || _deleting;
    return MeetingCreateForm(
      flow: _flow,
      today: first.isBefore(today) ? first : today,
      accessAsked: _accessAsked,
      accessRequiredText: meetingEditAccessRequired,
      timezone: _base.meeting.timezone,
      refusals: refusals,
      onChanged: _change,
      titleField: MeetingEditActions(
        controller: _title,
        placeholder: _placeholder,
        notices: [
          if (widget.source.hasAnswers)
            for (final notice in _base.notices(draft))
              meetingEditNoticeText(notice),
        ],
        saving: _saving,
        onSave: busy || (steps != null && steps.isEmpty) ? null : _save,
        titleRefusal: refusals[MeetingEditPart.title],
        outcome: failed == null ? null : meetingEditOutcomeText(failed),
      ),
      footer: TextButton.icon(
        onPressed: busy ? null : _delete,
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
