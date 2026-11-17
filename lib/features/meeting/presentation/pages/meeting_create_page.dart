import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/providers/auth_selectors.dart';
import 'package:momeet/core/providers/timezone_provider.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_mode.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/providers/pending_meeting_store.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_calendar.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_choice_row.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_home_button.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_mode_selector.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_section_title.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_shake.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_time_range.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_timezone_label.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_title_field.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 모임 만들기 화면(`/meetings`). 탭 셸 밖의 독립 화면이다.
///
/// 쉬운 입력부터 두고 비용이 큰 제목은 맨 끝 화살표 옆에 둔다: 날짜 → 시간 → 공개·게스트 → 제목.
/// 값이 규칙에 걸려 저절로 바뀌면 묻지 않고 바꾼 뒤 그 자리를 떤다.
///
/// 로그인하지 않아도 모두 넣을 수 있다. 화살표를 누르면 그때 로그인이 필요한 까닭과 로그인을 제목 아래에
/// 보인다. 로그인하러 가는 동안 폼을 이 기기에 두고([PendingMeetingStore]), 로그인해 돌아오면 넣은 그대로
/// 열려 화살표 한 번으로 만든다.
class MeetingCreatePage extends ConsumerStatefulWidget {
  const MeetingCreatePage({super.key});

  @override
  ConsumerState<MeetingCreatePage> createState() => _MeetingCreatePageState();
}

class _MeetingCreatePageState extends ConsumerState<MeetingCreatePage> {
  final _title = TextEditingController();
  var _draft = const MeetingDraft();
  final _loginRequest = GlobalKey();

  /// 로그인하지 않은 사람이 화살표를 눌렀다
  var _askLogin = false;

  /// 시간별에서 날짜별로 저절로 바뀐 횟수
  var _modeShakes = 0;

  /// 공개를 꺼서 게스트 로그인이 저절로 꺼진 횟수
  var _guestShakes = 0;

  @override
  void initState() {
    super.initState();
    final pending = ref
        .read(pendingMeetingStoreProvider)
        .take(today: DateTime.now());
    if (pending != null) {
      _draft = pending.draft;
      _title.text = pending.title;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _change(MeetingDraft next) => setState(() => _draft = next);

  /// 날짜를 누른다. 시간별에서 날짜별로 바뀌면 방식 고르기를 떤다
  void _tapDay(DateTime day) {
    final next = _draft.tapDay(day);
    setState(() {
      if (next.mode != _draft.mode) _modeShakes++;
      _draft = next;
    });
  }

  /// 공개를 바꾼다. 게스트 로그인이 꺼지면 그 줄을 떤다
  void _setPublic(bool value) {
    final next = _draft.withPublic(value);
    setState(() {
      if (next.allowGuests != _draft.allowGuests) _guestShakes++;
      _draft = next;
    });
  }

  Future<void> _submit() async {
    if (ref.read(createMeetingMutation).isPending) return;
    final draft = _draft;
    if (draft.dates.isEmpty) {
      showAppSnackBar(context, '${Terms.meeting} 날짜를 골라 주세요');
      return;
    }
    if (ref.read(currentUserProvider) == null) {
      setState(() => _askLogin = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final request = _loginRequest.currentContext;
        if (request == null || !request.mounted) return;
        Scrollable.ensureVisible(
          request,
          duration: MediaQuery.disableAnimationsOf(request)
              ? Duration.zero
              : const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      });
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
      draft: _draft,
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
    final draft = _draft;
    final today = calendarDay(DateTime.now());
    final name = ref.watch(currentUserProvider.select((user) => user?.name));
    final signedIn = ref.watch(
      currentUserProvider.select((user) => user != null),
    );
    return Scaffold(
      appBar: AppBar(
        leading: meetingAppBarLeading(context),
        title: const Text('새 ${Terms.meeting}'),
      ),
      body: _FormLayout(
        dates: _DatesSection(
          calendar: MeetingCalendar(
            firstDay: today,
            shownDay: draft.dates.isEmpty ? null : draft.dates.first,
            stateOf: (day) => draft.dayState(day, today: today),
            onDayTap: _tapDay,
          ),
        ),
        time: _TimeSection(
          draft: draft,
          timezone: ref.watch(timezoneProvider).value,
          shakes: _modeShakes,
          onChanged: _change,
        ),
        sharing: _SharingSection(
          draft: draft,
          guestShakes: _guestShakes,
          onPublicChanged: _setPublic,
          onChanged: _change,
        ),
        title: MeetingTitleField(
          controller: _title,
          placeholder: meetingTitlePlaceholder(name),
          submitting: ref.watch(createMeetingMutation).isPending,
          onSubmit: _submit,
        ),
        loginRequest: _askLogin && !signedIn
            ? _LoginRequest(key: _loginRequest, onLogin: _goToLogin)
            : null,
      ),
    );
  }
}

/// 넓으면 날짜를 왼쪽, 나머지를 오른쪽 칸에 두고, 좁으면 같은 순서로 위에서 아래로 쌓는다
class _FormLayout extends StatelessWidget {
  const _FormLayout({
    required this.dates,
    required this.time,
    required this.sharing,
    required this.title,
    required this.loginRequest,
  });

  /// 이 폭부터 두 칸
  static const _twoColumnsFrom = 720.0;

  final Widget dates;
  final Widget time;
  final Widget sharing;
  final Widget title;

  /// 제목 아래에 두는 로그인 요청. 로그인하지 않은 사람이 화살표를 눌렀을 때만 있다
  final Widget? loginRequest;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _twoColumnsFrom;
        final settings = [
          time,
          const SizedBox(height: 24),
          sharing,
          const SizedBox(height: 28),
          title,
          if (loginRequest case final request?) ...[
            const SizedBox(height: 12),
            request,
          ],
        ];
        return SingleChildScrollView(
          padding: EdgeInsets.all(wide ? 32 : 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: wide
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: dates),
                            const SizedBox(width: 40),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: settings,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        dates,
                        const SizedBox(height: 24),
                        ...settings,
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

/// '모임 날짜'와 달력
class _DatesSection extends StatelessWidget {
  const _DatesSection({required this.calendar});

  final Widget calendar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MeetingSectionTitle('${Terms.meeting} 날짜'),
        const SizedBox(height: 12),
        calendar,
      ],
    );
  }
}

/// '모임 시간': 받는 방식, 시간별 하루 범위, 시간 기준
class _TimeSection extends StatelessWidget {
  const _TimeSection({
    required this.draft,
    required this.timezone,
    required this.shakes,
    required this.onChanged,
  });

  final MeetingDraft draft;

  /// 아직 모르면 null
  final String? timezone;

  final int shakes;
  final ValueChanged<MeetingDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timezone = this.timezone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MeetingSectionTitle(
          '${Terms.meeting} 시간',
          caption: '최대 범위 설정',
          help:
              '참여자가 가능한 시간을 고를 범위입니다. '
              '시간별은 $hourlyMaxDays일 이내 날짜의 하루 시간 범위를, 날짜별은 날짜만, '
              '요일별은 한 주의 요일만 받습니다.',
        ),
        const SizedBox(height: 4),
        MeetingShake(
          count: shakes,
          child: MeetingModeSelector(
            mode: draft.mode,
            hourlyEnabled: draft.hourlyAvailable,
            onChanged: (mode) => onChanged(draft.withMode(mode)),
          ),
        ),
        Text(
          '${hourlyMaxDays + 1}일 이상부터는 시간별 선택이 불가합니다',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (draft.mode == MeetingMode.hourly) ...[
          const SizedBox(height: 12),
          MeetingTimeRange(
            startHour: draft.startHour,
            endHour: draft.endHour,
            onStartChanged: (hour) => onChanged(draft.withStartHour(hour)),
            onEndChanged: (hour) => onChanged(draft.withEndHour(hour)),
          ),
        ],
        if (timezone != null) ...[
          const SizedBox(height: 12),
          MeetingTimezoneLabel(timezone),
        ],
      ],
    );
  }
}

/// '공개 여부'와 '게스트 로그인'. 공개가 아니면 게스트 로그인을 고를 수 없다
class _SharingSection extends StatelessWidget {
  const _SharingSection({
    required this.draft,
    required this.guestShakes,
    required this.onPublicChanged,
    required this.onChanged,
  });

  final MeetingDraft draft;
  final int guestShakes;
  final ValueChanged<bool> onPublicChanged;
  final ValueChanged<MeetingDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MeetingSectionTitle(
          '공개 여부',
          help:
              '허용하면 링크가 있는 누구나 이 ${Terms.meeting.withJosa('을', '를')} 볼 수 있습니다. '
              '비허용이면 나만 볼 수 있습니다.',
        ),
        MeetingChoiceRow(
          label: '공개 여부',
          value: draft.isPublic,
          onChanged: onPublicChanged,
        ),
        const SizedBox(height: 16),
        const MeetingSectionTitle(
          '게스트 로그인',
          help:
              '허용하면 회원이 아니어도 이름과 비밀번호로 참여할 수 있습니다. '
              '공개 ${Terms.meeting}에서만 허용할 수 있습니다.',
        ),
        MeetingShake(
          count: guestShakes,
          child: MeetingChoiceRow(
            label: '게스트 로그인',
            value: draft.allowGuests,
            onChanged: draft.isPublic
                ? (value) => onChanged(draft.withGuests(value))
                : null,
          ),
        ),
      ],
    );
  }
}

/// 로그인하지 않은 사람이 만들려 할 때 제목 아래에 보이는 요청: 까닭, 넣은 것이 남는다는 것, 로그인
class _LoginRequest extends StatelessWidget {
  const _LoginRequest({super.key, required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: AppRadius.lgAll,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, size: 20, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${Terms.meeting.withJosa('을', '를')} 만들고 나중에 고치려면 로그인이 필요해요',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '입력한 내용은 그대로 남아요',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: onLogin,
                  child: const Text('로그인하고 계속하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
