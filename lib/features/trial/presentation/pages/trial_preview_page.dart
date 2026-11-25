import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/landing/landing_preview_bridge.dart'
    if (dart.library.js_interop) 'package:momeet/core/landing/landing_preview_bridge_web.dart';
import 'package:momeet/features/timer/timer.dart' show defaultFocusDuration;
import 'package:momeet/features/trial/presentation/utils/trial_preview_kind.dart';
import 'package:momeet/features/trial/presentation/utils/trial_samples.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_calendar_preview.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_inert.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_meeting_preview.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_timer_dashboard.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_todo_row.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 미리보기의 타이머가 지나간 시간. 시험에서 바꾼 할 일로 기본 집중 시간의 타이머를 시작해 이만큼 지난 때를 보인다
const _elapsed = Duration(minutes: 10);

/// 타이머 대시보드가 낮은 칸의 배치로 바꾸지 않는 높이. 칸이 이보다 낮으면 이 높이로 그려 줄인다
const _timerMinHeight = 400.0;

/// 랜딩의 기능 소개에 두는 미리보기 화면(`/demo/preview?kind=<종류>`). 배포 때 이 화면을 찍어 그림으로 둔다.
///
/// 체험하기와 같은 견본([trialStart])으로 앱의 위젯 하나를 화면 가득 그린다: 견본 일정이 든 두 주의 달력, 시험에서
/// 바꾼 할 일 한 줄, 그 할 일로 시작한 타이머, 견본 약속으로 만든 모임의 모임 화면 그림([TrialMeetingPreview]).
/// 체험하기의 머리띠나 안내 없이 앱의 밝은 테마로만 그리고(랜딩이 밝다), 무엇도
/// 반응하지 않는다([TrialInert]). 앱의 데이터 Provider와 서버는 쓰지 않는다.
///
/// 모임 화면 그림은 폭 360 휴대폰 화면을 칸의 폭에 맞게 줄이고 칸 높이만큼 위에서부터 보인다. 격자와 추천 시간
/// 제목까지 들려면 칸의 높이가 폭의 2.2배는 되어야 한다(test/landing/landing_previews_markup_test.dart).
///
/// 첫 화면 뒤에 받는 글꼴 굵기([fontWeights])를 기다려 그 글꼴로 한 프레임을 그린 뒤 [onReady]로 종류의 이름을
/// 알린다. 굵기를 받지 못해도 알린다.
///
/// 테스트: test/features/trial/presentation/pages/trial_preview_page_test.dart
class TrialPreviewPage extends StatefulWidget {
  const TrialPreviewPage({
    super.key,
    required this.kind,
    this.now = DateTime.now,
    this.fontWeights = appFontWeights,
    this.onReady = markLandingPreviewReady,
  });

  final TrialPreviewKind kind;

  /// 견본 일정의 날을 정하는 시각
  final DateTime Function() now;

  /// 앱 글꼴의 나머지 굵기 불러오기
  final Future<void> Function() fontWeights;

  /// 찍을 준비가 되면 종류의 이름으로 부른다
  final ValueChanged<String> onReady;

  @override
  State<TrialPreviewPage> createState() => _TrialPreviewPageState();
}

class _TrialPreviewPageState extends State<TrialPreviewPage> {
  late final _flow = trialStart(
    widget.now(),
  ).openExam().convert().openTodo().startTimer(defaultFocusDuration);

  late final _timer = _flow.timer!.copyWith(elapsedTime: _elapsed.inSeconds);

  late final _meeting = trialMeeting(_flow);

  @override
  void initState() {
    super.initState();
    _signalReady();
  }

  Future<void> _signalReady() async {
    try {
      await widget.fontWeights();
    } on Object {
      // 받지 못한 굵기는 있는 글꼴로 그린 채 알린다
    }
    // 글꼴이 바뀌었다는 알림은 다음 차례에 오므로 한 차례 넘긴 뒤 그 글꼴로 한 프레임을 그린다
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await SchedulerBinding.instance.endOfFrame;
    if (mounted) widget.onReady(widget.kind.name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.light();
    final todo = _flow.todo!;
    return Theme(
      data: theme,
      child: Material(
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: TrialInert(
            child: switch (widget.kind) {
              TrialPreviewKind.calendar => TrialCalendarPreview(
                exam: _flow.exam,
                dinner: _flow.dinner,
                today: _flow.now,
              ),
              TrialPreviewKind.todo => _ScaledToFit(
                child: Card.outlined(
                  margin: EdgeInsets.zero,
                  child: TrialTodoRow(todo: todo, timer: _timer),
                ),
              ),
              TrialPreviewKind.timer => _ScaledToFit(
                minHeight: _timerMinHeight,
                child: TrialTimerDashboard(
                  timer: _timer,
                  remaining: defaultFocusDuration - _elapsed,
                ),
              ),
              TrialPreviewKind.meeting => TrialMeetingPreview(
                board: _meeting,
                email: trialMeetingEmail,
              ),
            },
          ),
        ),
      ),
    );
  }
}

/// [child]를 칸의 폭으로, 높이는 [minHeight]와 칸 높이 가운데 큰 쪽(없으면 제 높이)으로 그린 뒤 칸 가운데에 둔다.
/// 칸에 들어가지 않으면 비율을 지켜 줄인다
class _ScaledToFit extends StatelessWidget {
  const _ScaledToFit({this.minHeight, required this.child});

  final double? minHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final minHeight = this.minHeight;
    return LayoutBuilder(
      builder: (context, constraints) => FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: constraints.maxWidth,
          height: minHeight == null
              ? null
              : math.max(minHeight, constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }
}
