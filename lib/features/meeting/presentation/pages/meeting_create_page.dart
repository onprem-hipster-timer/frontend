import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/providers/auth_selectors.dart';
import 'package:momeet/core/providers/timezone_provider.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/providers/pending_meeting_store.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_create_form.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_create_layout.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_create_login_prompt.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_create_questions.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_glass_scaffold.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_title_field.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 모임 만들기 화면(`/meetings`). 탭 셸 밖의 독립 화면이다.
///
/// 한 번에 한 질문씩 묻는다([MeetingCreateQuestions]): 기간 → 제외 → 받는 방식 → 시간(시간별만) → 공개 여부 →
/// 게스트(공개만) → 제목. '전체 설정 펼치기'를 누르면 모든 설정을 한 폼으로 보인다([MeetingCreateForm]).
///
/// 로그인하지 않아도 모두 넣을 수 있고, 그동안 로그인 말은 없다. 화살표를 누르면 그때 로그인이 필요한 까닭을
/// 묻는 창(좁으면 하단 시트, 넓으면 대화상자)을 연다. 로그인하러 가는 동안 폼을 이 기기에 두고
/// ([PendingMeetingStore]), 로그인해 돌아오면 답한 그대로(펼친 폼이면 펼친 폼으로) 열려 화살표 한 번으로 만든다.
class MeetingCreatePage extends ConsumerStatefulWidget {
  const MeetingCreatePage({super.key});

  @override
  ConsumerState<MeetingCreatePage> createState() => _MeetingCreatePageState();
}

class _MeetingCreatePageState extends ConsumerState<MeetingCreatePage> {
  final _title = TextEditingController();
  var _flow = const MeetingFlow();

  /// 처음 보이는 질문(되살린 폼 포함)은 그대로 두고, 답한 뒤 나타나는 질문부터 펼친다
  var _animate = false;

  @override
  void initState() {
    super.initState();
    final pending = ref
        .read(pendingMeetingStoreProvider)
        .take(today: DateTime.now());
    if (pending != null) {
      _flow = pending.flow;
      _title.text = pending.title;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _change(MeetingFlow next) => setState(() {
    _flow = next;
    _animate = true;
  });

  Future<void> _submit() async {
    if (ref.read(createMeetingMutation).isPending) return;
    final draft = _flow.draft;
    if (_flow.rangeStart != null || draft.dates.isEmpty) {
      showAppSnackBar(
        context,
        _flow.rangeStart != null
            ? meetingRangeUnfinished
            : '${Terms.meeting} 날짜를 골라 주세요',
      );
      return;
    }
    if (ref.read(currentUserProvider) == null) {
      final wide =
          MediaQuery.sizeOf(context).width >= MeetingCreateLayout.wideFrom;
      if (await askLoginToCreateMeeting(context, wide: wide) && mounted) {
        await _goToLogin();
      }
      return;
    }
    final typed = _title.text.trim();
    final title = typed.isEmpty
        ? meetingTitlePlaceholder(ref.read(currentUserProvider)?.name)
        : typed;
    try {
      final meeting = await createMeetingMutation.run(ref, (tsx) async {
        final timezone = await tsx.get(timezoneProvider.future);
        return tsx
            .get(meetingMutationsProvider.notifier)
            .create(
              draft.toMeetingCreate(title: title, timezone: timezone),
              isPublic: draft.isPublic,
              allowGuests: draft.allowGuests,
            );
      });
      if (!mounted) return;
      context.goNamed(
        AppRoute.meetingCreated.name,
        pathParameters: {'meetingId': meeting.id},
      );
    } catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          '${Terms.meeting.withJosa('을', '를')} 만들지 못했습니다: $error',
          kind: AppNoticeKind.error,
        );
      }
    }
  }

  /// 지금 폼을 이 기기에 두고 로그인하러 간다. 로그인하면 이 화면으로 돌아온다
  Future<void> _goToLogin() async {
    await ref.read(pendingMeetingStoreProvider).save((
      flow: _flow,
      title: _title.text,
    ));
    if (!mounted) return;
    context.goNamed(
      AppRoute.login.name,
      queryParameters: {
        'redirect': context.namedLocation(AppRoute.meetings.name),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = calendarDay(DateTime.now());
    final name = ref.watch(currentUserProvider.select((user) => user?.name));
    final timezone = ref.watch(timezoneProvider).value;
    final titleField = MeetingTitleField(
      controller: _title,
      placeholder: meetingTitlePlaceholder(name),
      submitting: ref.watch(createMeetingMutation).isPending,
      onSubmit: _submit,
    );
    return MeetingGlassScaffold(
      title: const Text('새 ${Terms.meeting}'),
      body: _flow.expanded
          ? MeetingCreateForm(
              flow: _flow,
              today: today,
              timezone: timezone,
              titleField: titleField,
              onChanged: _change,
            )
          : MeetingCreateQuestions(
              flow: _flow,
              today: today,
              animate: _animate,
              timezone: timezone,
              titleField: titleField,
              onChanged: _change,
              onExpand: () => _change(_flow.expand()),
            ),
    );
  }
}
