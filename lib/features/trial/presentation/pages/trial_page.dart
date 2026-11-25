import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/title/page_title.dart';
import 'package:momeet/features/calendar/calendar.dart'
    show ScheduleDetailBody, ScheduleTimerSectionView, showTodoConvertedNotice;
import 'package:momeet/features/meeting/meeting.dart'
    show
        MeetingCreateLayout,
        MeetingGlassScaffold,
        MeetingQuestionPrompt,
        MeetingStagger,
        MeetingStepSwitcher;
import 'package:momeet/features/timer/timer.dart'
    show StartTimerInput, StartTimerSheetView, defaultFocusDuration;
import 'package:momeet/features/todo/todo.dart' show showTimerStartedNotice;
import 'package:momeet/features/trial/domain/trial_flow.dart';
import 'package:momeet/features/trial/presentation/utils/trial_samples.dart';
import 'package:momeet/features/trial/presentation/utils/trial_texts.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_calendar.dart';
import 'package:momeet/features/trial/presentation/utils/trial_spotlights.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_end.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_spotlight.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_timer_dashboard.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_todo_row.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 달력과 타이머 대시보드의 높이
const _stageHeight = 440.0;

/// 체험하기 화면(`/demo`). 탭 셸 밖의 독립 화면이고, 로그인하지 않았거나 게스트여도 머문다.
///
/// 처음 온 사람이 입력 없이 앱의 한 바퀴를 따라간다([TrialFlow]): 달력의 시험 → 일정 상세에서 할 일로 변환 →
/// 할 일에서 타이머 시작 → 타이머의 시간이 [trialTimerSweep] 만에 지나감 → 끝. 모임 만들기처럼 한 번에 한
/// 단계씩, 다음에 누를 것을 말하는 한 줄 아래에 앱의 위젯을 그대로 두고, 누르면 앱처럼 시트와 알림(이동 단추
/// 포함)을 띄운다. 단계가 바뀌면 떠 있던 알림을 닫는다. 서버에 보내지 않고 앱의 데이터 Provider도 읽지 않는다.
///
/// 다음에 누를 컨트롤은 [TrialSpotlight]로 강조한다([trialSpotlightOf]).
///
/// 끝 전까지 머리띠 오른쪽에 단계 표시와 '건너뛰기'(가입 화면으로 간다)를 둔다. 끝에는 가입하기와 모임 만들기를 둔다.
///
/// 테스트: test/features/trial/presentation/pages/trial_page_test.dart
class TrialPage extends StatelessWidget {
  const TrialPage({super.key, this.now = DateTime.now});

  /// 견본 일정의 날을 정하는 시각
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    // 알림이 이 화면에만 뜨고 화면을 떠나면 함께 사라진다
    return PageTitle(
      title: trialDocumentTitle,
      child: ScaffoldMessenger(child: _Trial(start: now())),
    );
  }
}

class _Trial extends StatefulWidget {
  const _Trial({required this.start});

  final DateTime start;

  @override
  State<_Trial> createState() => _TrialState();
}

class _TrialState extends State<_Trial> with SingleTickerProviderStateMixin {
  late var _flow = trialStart(widget.start);

  /// 타이머의 정한 시간이 지나가는 움직임(0 → 1). 다 지나가면 끝으로 간다
  /// 시간이 흐르는 것을 보이므로 애니메이션을 줄여도 같은 길이다
  late final _sweep = AnimationController(
    vsync: this,
    duration: trialTimerSweep,
    animationBehavior: AnimationBehavior.preserve,
  )..addStatusListener(_swept);

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  void _swept(AnimationStatus status) {
    if (status == AnimationStatus.completed) _go(_flow.finishTimer());
  }

  void _go(TrialFlow next) {
    if (!mounted || identical(next, _flow)) return;
    if (next.step != _flow.step) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } else if (trialHeadline(next) != trialHeadline(_flow)) {
      // 단계가 바뀌면 MeetingStepSwitcher가 알리고, 같은 단계에서 한 줄만 바뀌면 여기서 알린다
      SemanticsService.sendAnnouncement(
        View.of(context),
        trialHeadline(next),
        Directionality.of(context),
      );
    }
    setState(() => _flow = next);
    if (next.step == TrialStep.timer) _sweep.forward(from: 0);
  }

  void _convert() {
    _go(_flow.convert());
    // 체험하기의 알림은 누르거나 단계가 바뀔 때까지 남는다
    showTodoConvertedNotice(
      context,
      onShowTodo: () => _go(_flow.openTodo()),
      persist: true,
    );
  }

  /// 앱처럼 할 일을 고르고 기본 집중 시간을 채운 새 작업 시트를 연다. 다른 할 일은 고를 수 없다
  Future<void> _startTimer() async {
    final todo = _flow.todo;
    if (todo == null) return;
    final input = await showAppSheet<StartTimerInput>(
      context,
      builder: (_) => StartTimerSheetView(
        initialDuration: defaultFocusDuration,
        initialTodo: todo,
        todos: AsyncData([todo]),
        onPickTodos: (_) async => null,
      ),
    );
    if (input == null || !mounted) return;
    _go(_flow.startTimer(input.duration, title: input.title));
    showTimerStartedNotice(
      ScaffoldMessenger.of(context),
      onShowTimer: () => _go(_flow.openTimer()),
      persist: true,
    );
  }

  void _signUp() => context.goNamed(AppRoute.signup.name);

  @override
  Widget build(BuildContext context) {
    final flow = _flow;
    final step = flow.step;
    return MeetingGlassScaffold(
      title: _TrialTitle(
        number: step == TrialStep.end ? null : step.index + 1,
        onSkip: _signUp,
      ),
      body: MeetingCreateLayout(
        maxWidth: 640,
        // 단계가 넘어가며 잘리지 않도록 강조는 넘어가는 단계 밖에 그린다
        builder: (context, wide) => TrialSpotlight(
          target: trialSpotlightOf(flow),
          child: MeetingStepSwitcher(
            step: step,
            announcement: trialHeadline(flow),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MeetingQuestionPrompt(headline: trialHeadline(flow)),
                const SizedBox(height: 24),
                MeetingStagger(
                  order: 2,
                  child: _TrialStage(
                    flow: flow,
                    sweep: _sweep,
                    onOpenExam: () => _go(_flow.openExam()),
                    onConvert: _convert,
                    onOpenTodo: () => _go(_flow.openTodo()),
                    onStartTimer: _startTimer,
                    onOpenTimer: () => _go(_flow.openTimer()),
                    onSignUp: _signUp,
                    onCreateMeeting: () =>
                        context.pushNamed(AppRoute.meetings.name),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 단계마다 앱의 위젯. 길 밖의 수정·삭제는 누를 수 없게 둔다. 달력과 타이머 대시보드는 [_stageHeight] 높이에 둔다
class _TrialStage extends StatelessWidget {
  const _TrialStage({
    required this.flow,
    required this.sweep,
    required this.onOpenExam,
    required this.onConvert,
    required this.onOpenTodo,
    required this.onStartTimer,
    required this.onOpenTimer,
    required this.onSignUp,
    required this.onCreateMeeting,
  });

  final TrialFlow flow;

  /// 타이머의 정한 시간이 지나간 몫(0 → 1)
  final Animation<double> sweep;
  final VoidCallback onOpenExam;
  final VoidCallback onConvert;
  final VoidCallback onOpenTodo;
  final VoidCallback onStartTimer;
  final VoidCallback onOpenTimer;
  final VoidCallback onSignUp;
  final VoidCallback onCreateMeeting;

  @override
  Widget build(BuildContext context) {
    final todo = flow.todo;
    final timer = flow.timer;
    return switch (flow.step) {
      TrialStep.calendar => SizedBox(
        height: _stageHeight,
        child: TrialCalendar(
          exam: flow.exam,
          dinner: flow.dinner,
          today: flow.now,
          onOpenExam: onOpenExam,
        ),
      ),
      TrialStep.schedule => ScheduleDetailBody(
        schedule: flow.exam,
        timerSection: ScheduleTimerSectionView(
          timers: const AsyncData([]),
          now: flow.now,
        ),
        onOpenLinked: onOpenTodo,
        onConvert: onConvert,
        onEdit: null,
        onDelete: null,
      ),
      TrialStep.todo => Card.outlined(
        child: TrialTodoRow(
          todo: todo!,
          timer: timer,
          onStartTimer: timer == null ? onStartTimer : null,
          onOpenTimer: onOpenTimer,
        ),
      ),
      TrialStep.timer => SizedBox(
        height: _stageHeight,
        child: AnimatedBuilder(
          animation: sweep,
          builder: (context, _) => TrialTimerDashboard(
            timer: timer!,
            remaining:
                Duration(seconds: timer.allocatedDuration) * (1 - sweep.value),
          ),
        ),
      ),
      TrialStep.end => TrialEnd(
        todo: todo!,
        recordedSeconds: flow.recordedSeconds,
        onSignUp: onSignUp,
        onCreateMeeting: onCreateMeeting,
      ),
    };
  }
}

/// 머리띠의 제목 줄: '체험하기', 그리고 끝 전까지 오른쪽에 단계 표시('1/4')와 '건너뛰기'. 본문을 굴려도 늘 보인다
class _TrialTitle extends StatelessWidget {
  const _TrialTitle({required this.number, required this.onSkip});

  /// 지금 단계. 끝이면 null
  final int? number;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = this.number;
    return Row(
      children: [
        // 글자가 크면 단계 표시와 '건너뛰기'를 두려고 제목을 줄인다
        const Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(trialTitle),
          ),
        ),
        if (number != null) ...[
          Text(
            trialStepLabel(number),
            semanticsLabel: trialStepSemantics(number),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          TextButton(onPressed: onSkip, child: const Text(trialSkip)),
        ],
      ],
    );
  }
}
