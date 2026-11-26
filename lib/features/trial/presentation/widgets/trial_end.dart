import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/todo.dart'
    show TodoElapsedBadgeView, TodoTagIndicators, TodoTreeTileView;
import 'package:momeet/features/trial/presentation/utils/trial_texts.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 모임 화면 그림의 크기
const _previewSize = Size(180, 450);

/// 이 폭부터 모임 화면 그림을 답과 모임 만들기 옆에 둔다
const _sideBySideFrom = 480.0;

/// 답이 펼쳐지고 접히는 시간
const _duration = Durations.medium1;

/// 펼쳐지는 답이 올라오는 거리(답 높이에 대한 몫)
const _rise = 0.04;

/// 체험하기의 끝. 할 일 줄(읽기만: 상태 아이콘·누적 집중 시간·태그, [TodoTreeTileView]), 가입하기([onSignUp])와
/// 그 바로 아래 조용한 링크([trialTrust], [onOpenTrust])를 두고, 구분선 아래에 방문자의 물음([trialMeetingQuestion])을 조용한 글자 버튼 한 줄로 둔다.
///
/// 물음을 누르면 그 아래에 답이 펼쳐진다: 답 한 줄([trialMeetingLead]), 모임 만들기([onCreateMeeting]), 모임 화면
/// 그림([meetingPreview], [_previewSize]. 좁으면 그 아래, 넓으면 그 옆). 다시 누르면 접힌다. 처음에는 접혀 있고,
/// 접혀 있는 동안 답은 그리지 않는다. 펼치면 스크린 리더에 답 한 줄을 알리고, 답 한 줄과 모임 만들기가 보이게
/// 굴린다. 애니메이션을 줄였으면 바로 펼치고 접는다.
///
/// 테스트: test/features/trial/presentation/pages/trial_page_test.dart
class TrialEnd extends StatefulWidget {
  const TrialEnd({
    super.key,
    required this.todo,
    required this.recordedSeconds,
    required this.onSignUp,
    required this.onOpenTrust,
    required this.onCreateMeeting,
    required this.meetingPreview,
    this.initiallyExpanded = false,
  });

  final TodoRead todo;
  final int recordedSeconds;
  final VoidCallback onSignUp;

  /// 개인정보 보호 조치 안내를 연다
  final VoidCallback onOpenTrust;
  final VoidCallback onCreateMeeting;

  /// 펼친 답에 두는 모임 화면 그림
  final Widget meetingPreview;

  /// 처음부터 답을 펼쳐 둔다(카탈로그와 배치 점검에서 펼친 모양을 보인다)
  final bool initiallyExpanded;

  @override
  State<TrialEnd> createState() => _TrialEndState();
}

class _TrialEndState extends State<TrialEnd>
    with SingleTickerProviderStateMixin {
  late final _open = AnimationController(
    vsync: this,
    duration: _duration,
    value: widget.initiallyExpanded ? 1 : 0,
  )..addStatusListener((_) => setState(() {}));

  late final _curve = CurvedAnimation(
    parent: _open,
    curve: Easing.emphasizedDecelerate,
    reverseCurve: Easing.emphasizedAccelerate,
  );

  /// 펼친 뒤 보이게 굴리는 답 한 줄과 모임 만들기
  final _answerKey = GlobalKey();

  @override
  void dispose() {
    _curve.dispose();
    _open.dispose();
    super.dispose();
  }

  bool get _expanded =>
      _open.status == AnimationStatus.forward ||
      _open.status == AnimationStatus.completed;

  Future<void> _toggle() async {
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (_expanded) {
      if (reduce) {
        _open.value = 0;
      } else {
        _open.reverse();
      }
      return;
    }
    SemanticsService.sendAnnouncement(
      View.of(context),
      trialMeetingLead,
      Directionality.of(context),
    );
    if (reduce) {
      _open.value = 1;
      await WidgetsBinding.instance.endOfFrame;
    } else {
      try {
        await _open.forward().orCancel;
      } on TickerCanceled {
        // 펼치는 중에 다시 눌러 접었다
        return;
      }
    }
    if (!mounted || !_expanded) return;
    final answer = _answerKey.currentContext;
    if (answer == null || !answer.mounted) return;
    await Scrollable.ensureVisible(
      answer,
      duration: reduce ? Duration.zero : _duration,
      curve: Easing.standard,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  @override
  Widget build(BuildContext context) {
    final widget = this.widget;
    final curve = _curve;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card.outlined(
          child: TodoTreeTileView(
            todo: widget.todo,
            meta: [
              TodoElapsedBadgeView(finishedSeconds: widget.recordedSeconds),
              if (widget.todo.tags.isNotEmpty)
                TodoTagIndicators(tags: widget.todo.tags),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: widget.onSignUp,
          child: const Text(trialSignUp),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: widget.onOpenTrust,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            child: const Text(trialTrust),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        _Question(expanded: _expanded, turns: curve, onPressed: _toggle),
        if (!_open.isDismissed)
          SizeTransition(
            sizeFactor: curve,
            alignment: AlignmentDirectional.topStart,
            child: FadeTransition(
              opacity: curve,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, _rise),
                  end: Offset.zero,
                ).animate(curve),
                child: _Answer(
                  answerKey: _answerKey,
                  onCreateMeeting: widget.onCreateMeeting,
                  preview: widget.meetingPreview,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 방문자의 물음: 처음에 맞춘 조용한 한 줄과 끝의 펼침 표시. 펼친 상태를 스크린 리더에 알린다
class _Question extends StatelessWidget {
  const _Question({
    required this.expanded,
    required this.turns,
    required this.onPressed,
  });

  final bool expanded;

  /// 펼친 몫(0 → 1). 펼침 표시가 반 바퀴 돈다
  final Animation<double> turns;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        expanded: expanded,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            alignment: AlignmentDirectional.centerStart,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            children: [
              const Expanded(child: Text(trialMeetingQuestion)),
              const SizedBox(width: 8),
              RotationTransition(
                turns: Tween(begin: 0.0, end: 0.5).animate(turns),
                child: const Icon(Icons.expand_more),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 펼친 답: 답 한 줄과 모임 만들기([answerKey]), 그리고 모임 화면 그림. 좁으면 그림을 아래에, 넓으면 옆에 둔다
class _Answer extends StatelessWidget {
  const _Answer({
    required this.answerKey,
    required this.onCreateMeeting,
    required this.preview,
  });

  final GlobalKey answerKey;
  final VoidCallback onCreateMeeting;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    final answer = Column(
      key: answerKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(trialMeetingLead),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: onCreateMeeting,
          child: const Text(trialMeetingAction),
        ),
      ],
    );
    final picture = SizedBox.fromSize(size: _previewSize, child: preview);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < _sideBySideFrom) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                answer,
                const SizedBox(height: 16),
                Center(child: picture),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: answer),
              const SizedBox(width: 24),
              picture,
            ],
          );
        },
      ),
    );
  }
}
