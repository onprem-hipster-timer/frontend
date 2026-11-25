import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

/// 모임 만들기에서 질문이 넘어가는 움직임의 시간. Material 3 움직임 값([Durations], [Easing])으로 맞춘다.
///
/// 답한 질문은 누른 답을 [meetingStepHold] 동안 보인 뒤 [meetingStepLeave] 동안 줄어들며 사라지고
/// ([Easing.emphasizedAccelerate]), 다음 질문은 누른 뒤 [meetingStepEnterDelay]부터 질문 글 → 안내 → 답 차례로
/// [meetingStepStagger]씩 늦게 [meetingStepItem] 동안 [meetingStepRise]만큼 올라오며 나타난다
/// ([Easing.emphasizedDecelerate]). 모두 400ms 안에 끝난다
const meetingStepHold = Durations.short1;
const meetingStepLeave = Durations.short3;
const meetingStepEnterDelay = Durations.short2;
const meetingStepStagger = Durations.short1;
const meetingStepItem = Durations.short4;

/// 나타나는 질문이 올라오는 거리
const meetingStepRise = 20.0;

/// 질문의 글·안내·답이 나타나는 차례의 수(질문 글 0, 안내 1, 답 2)
const _orders = 3;

/// 들어오는 질문 하나의 나타나는 시간
final _enterDuration =
    meetingStepEnterDelay +
    meetingStepStagger * (_orders - 1) +
    meetingStepItem;

/// [context]가 든 질문이 나타나는 움직임(0 → 1). 넘어가는 질문 밖이면 null이다
Animation<double>? meetingStepEntrance(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<_StepEntrance>()?.animation;

/// 나타나는 질문 안에서 [order]번째(질문 글 0, 안내 1, 답 2) 조각이 나타나는 구간
Interval meetingStepInterval(int order) {
  final total = _enterDuration.inMicroseconds;
  final start = meetingStepEnterDelay + meetingStepStagger * order;
  return Interval(
    start.inMicroseconds / total,
    (start + meetingStepItem).inMicroseconds / total,
    curve: Easing.emphasizedDecelerate,
  );
}

/// 질문을 바꿀 때의 움직임을 한 곳에서 맡는다. [step]이 바뀌면 앞 질문은 누른 답을 잠깐 보인 뒤 위쪽을 기준으로
/// 조금 작아지며 흐려지고 높이가 접혀 사라진다(그동안 누를 수 없고 스크린 리더도 읽지 않는다). 새 질문은 그
/// 아래에서 조각마다([MeetingStagger]) 차례로 올라오며 나타나고, 스크린 리더에 [announcement]를 알린다. 앞
/// 질문이 다 접히면 새 질문이 화면에 들게 부드럽게 굴린다. 화면보다 긴 질문은 끝이 보이게 굴리고, [revealStart]면
/// 첫머리가 보이게 굴린다.
///
/// 상태가 먼저다. 넘어가는 중에 또 답하면 지금 질문도 바로 사라지기 시작하고 새 질문이 들어온다. 처음 그리는
/// 질문은 움직이지 않는다. 애니메이션을 줄였으면 한 프레임에 바꾸고 바로 굴린다.
///
/// 테스트: test/features/meeting/presentation/widgets/meeting_step_switcher_test.dart
class MeetingStepSwitcher extends StatefulWidget {
  const MeetingStepSwitcher({
    super.key,
    required this.step,
    required this.announcement,
    required this.child,
    this.revealStart = false,
  });

  /// 지금 질문을 가리는 값. 바뀌면 넘어간다
  final Object step;
  final String announcement;
  final Widget child;

  /// 화면보다 긴 새 질문을 첫머리가 보이게 굴린다(누를 것이 위에 있는 질문)
  final bool revealStart;

  @override
  State<MeetingStepSwitcher> createState() => _MeetingStepSwitcherState();
}

/// 그리는 질문 하나: 나타나는 움직임과(사라지는 중이면) 사라지는 움직임
class _Entry {
  _Entry(this.child, {required this.enter});

  final GlobalKey key = GlobalKey();
  Widget child;
  final AnimationController enter;
  AnimationController? leave;

  void dispose() {
    enter.dispose();
    leave?.dispose();
  }
}

class _MeetingStepSwitcherState extends State<MeetingStepSwitcher>
    with TickerProviderStateMixin {
  late _Entry _current = _Entry(
    widget.child,
    enter: AnimationController(vsync: this, value: 1),
  );
  final _leaving = <_Entry>[];

  @override
  void didUpdateWidget(MeetingStepSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step == widget.step) {
      _current.child = widget.child;
      return;
    }
    final reduce = MediaQuery.disableAnimationsOf(context);
    final previous = _current;
    _current = _Entry(
      widget.child,
      enter: AnimationController(
        vsync: this,
        duration: _enterDuration,
        value: reduce ? 1 : 0,
      ),
    );
    SemanticsService.sendAnnouncement(
      View.of(context),
      widget.announcement,
      Directionality.of(context),
    );
    if (reduce) {
      final gone = [previous, ..._leaving];
      _leaving.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final entry in gone) {
          entry.dispose();
        }
        _show(Duration.zero);
      });
      return;
    }
    _current.enter.forward();
    final leave = previous.leave = AnimationController(
      vsync: this,
      duration: meetingStepHold + meetingStepLeave,
    );
    _leaving.add(previous);
    leave.forward().whenCompleteOrCancel(() => _gone(previous));
  }

  /// 사라진 질문을 뺀다. 남은 것이 없으면 지금 질문이 보이게 굴린다
  void _gone(_Entry entry) {
    if (!mounted || !_leaving.remove(entry)) return;
    setState(() {});
    // 다음 프레임에 떠난 질문을 뺀 뒤 버리고, 남은 질문도 배치가 끝난 뒤 크기를 잰다.
    // 보상 줄처럼 크기를 다시 계산하는 자식이 움직이는 중에는 아직 배치가 필요할 수 있다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      entry.dispose();
      if (_leaving.isEmpty) _show(meetingStepItem);
    });
  }

  void _show(Duration duration) {
    final target = _current.key.currentContext;
    if (!mounted || target == null) return;
    final viewport = Scrollable.maybeOf(target)?.position.viewportDimension;
    final taller = viewport != null && (target.size?.height ?? 0) > viewport;
    Scrollable.ensureVisible(
      target,
      duration: duration,
      curve: Easing.emphasizedDecelerate,
      alignmentPolicy: widget.revealStart && taller
          ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
          : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  @override
  void dispose() {
    _current.dispose();
    for (final entry in _leaving) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 지금 질문이 사라지기 시작해도 같은 자리의 같은 모양이라 누른 답 등 상태가 이어진다
    Widget stage(_Entry entry) => KeyedSubtree(
      key: entry.key,
      child: _Stage(
        leave: entry.leave,
        child: _StepEntrance(animation: entry.enter, child: entry.child),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final entry in _leaving) stage(entry), stage(_current)],
    );
  }
}

/// 질문 하나의 자리. [leave]가 있으면 사라지는 중이다: 누른 답을 잠깐 보인 뒤 위를 기준으로 조금 작아지며
/// 흐려지고 높이가 접힌다. 그동안 누를 수 없고 스크린 리더도 읽지 않는다
class _Stage extends StatelessWidget {
  const _Stage({required this.leave, required this.child});

  /// 0 → 1로 사라진다. 지금 질문이면 null
  final Animation<double>? leave;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final leave = this.leave;
    final total = (meetingStepHold + meetingStepLeave).inMicroseconds;
    final gone = leave == null
        ? kAlwaysDismissedAnimation
        : leave.drive(
            CurveTween(
              curve: Interval(
                meetingStepHold.inMicroseconds / total,
                1,
                curve: Easing.emphasizedAccelerate,
              ),
            ),
          );
    final shown = gone.drive(Tween<double>(begin: 1, end: 0));
    return IgnorePointer(
      ignoring: leave != null,
      child: ExcludeSemantics(
        excluding: leave != null,
        child: SizeTransition(
          sizeFactor: shown,
          alignment: AlignmentDirectional.topStart,
          child: FadeTransition(
            opacity: shown,
            child: ScaleTransition(
              scale: gone.drive(Tween<double>(begin: 1, end: 0.96)),
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// 질문이 나타나는 움직임을 그 안의 조각([MeetingStagger])에 건넨다
class _StepEntrance extends InheritedWidget {
  const _StepEntrance({required this.animation, required super.child});

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_StepEntrance oldWidget) =>
      oldWidget.animation != animation;
}
