import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/meeting.dart'
    show
        MeetingQuestionPrompt,
        keepWords,
        meetingStepEnterDelay,
        meetingStepItem,
        meetingStepRise,
        meetingStepStagger;
import 'package:momeet/features/trial/presentation/widgets/trial_spotlight.dart';

part 'trial_prompt_reveal.dart';

/// 보상 줄이 나타나는 움직임의 시간. 누른 순간부터 잰다.
///
/// 앞 글은 [trialRewardLeave] 동안 흐려진다. 그 뒤 보상 줄의 낱말이 [trialRewardWordStagger]씩 늦게
/// [trialRewardWord] 동안 흐림 [trialRewardBlur]에서 또렷해지며 [trialRewardRiseBy]만큼 올라와 나타난다. 그동안
/// 글은 주색에서 옆 색으로 번지는 색이다. 낱말이 다 놓이면 밝은 띠가 [trialRewardSheen] 동안 글을 한 번 지나가고,
/// 글은 [trialRewardRelax] 동안 보통 앞 줄의 색으로 돌아온다. 큰 한 줄은 다음에 누를 것의 강조와 같이
/// [TrialSpotlight.settle]에 모임 만들기의 질문처럼 나타나고, 안내는 그보다 [meetingStepStagger] 늦게 맨 끝에 나타난다
const trialRewardLeave = meetingStepEnterDelay;
const trialRewardWord = Durations.medium2;
const trialRewardWordStagger = meetingStepStagger;
const trialRewardSheen = Durations.extralong1;
const trialRewardRelax = Durations.medium4;

/// 낱말이 올라오는 거리
const trialRewardRiseBy = 6.0;

/// 낱말이 나타나기 시작할 때의 흐림
const trialRewardBlur = 4.0;

/// 밝은 띠의 너비(글 너비에 대한 몫)
const _sheenWidth = 0.25;

/// 체험하기 단계의 글: 앞 줄([lead]), 큰 한 줄([headline]), 아래 안내([guide]). 큰 한 줄은 스크린 리더에 머리글로 읽힌다.
///
/// [reward]가 아니면 [MeetingQuestionPrompt]로 그린다. [reward]면 앞 줄은 방금 누른 것으로 얻은 것이다: 나타날
/// 때 앞 줄이 낱말마다 먼저 들어오고 큰 한 줄이 그 뒤에 들어온다. 같은 자리에서 글이 보상 줄로 바뀌면 앞 글은
/// 짧게 흐려지며 사라진다. 한 번만 움직이고 끝나면 보통 앞 줄과 같은 모습이다.
///
/// 낱말은 끝 모습의 줄 바꿈 그대로의 자리에 그려 처음 프레임부터 배치가 그대로다. 움직이는 동안에도 두 줄은
/// 스크린 리더에 읽힌다. 애니메이션을 줄였으면 바로 끝 모습이다.
///
/// 테스트: test/features/trial/presentation/widgets/trial_prompt_test.dart
class TrialPrompt extends StatefulWidget {
  const TrialPrompt({
    super.key,
    required this.lead,
    required this.headline,
    this.guide,
    this.reward = false,
  });

  /// 보상 줄이 나타나는 동안 낱말을 그리는 층
  static const revealKey = ValueKey('trial-prompt-reveal');

  final String lead;
  final String headline;
  final String? guide;
  final bool reward;

  @override
  State<TrialPrompt> createState() => _TrialPromptState();
}

/// [words]개 낱말인 보상 줄의 차례. 구간은 모두 누른 순간부터 끝까지에 대한 몫이다
class _Timeline {
  _Timeline(this.words) {
    final landed =
        trialRewardLeave +
        trialRewardWordStagger * (words - 1) +
        trialRewardWord;
    _sheenAt = landed;
    _relaxAt = landed + trialRewardSheen;
    final settled = _relaxAt + trialRewardRelax;
    final entered =
        TrialSpotlight.settle + meetingStepStagger + meetingStepItem;
    total = settled > entered ? settled : entered;
  }

  final int words;
  late final Duration total;
  late final Duration _sheenAt;
  late final Duration _relaxAt;

  Interval _span(Duration start, Duration length, Curve curve) => Interval(
    start.inMicroseconds / total.inMicroseconds,
    (start + length).inMicroseconds / total.inMicroseconds,
    curve: curve,
  );

  Interval get leave => _span(Duration.zero, trialRewardLeave, Curves.easeOut);

  Interval word(int index) => _span(
    trialRewardLeave + trialRewardWordStagger * index,
    trialRewardWord,
    Easing.emphasizedDecelerate,
  );

  Interval get sheen => _span(_sheenAt, trialRewardSheen, Easing.standard);

  Interval get relax => _span(_relaxAt, trialRewardRelax, Easing.standard);

  Interval get headline => _span(
    TrialSpotlight.settle,
    meetingStepItem,
    Easing.emphasizedDecelerate,
  );

  Interval get guide => _span(
    TrialSpotlight.settle + meetingStepStagger,
    meetingStepItem,
    Easing.emphasizedDecelerate,
  );
}

class _TrialPromptState extends State<TrialPrompt>
    with SingleTickerProviderStateMixin {
  late final _play = AnimationController(vsync: this, value: 1)
    ..addStatusListener(_played);
  late var _timeline = _timelineOf(widget.lead);

  /// 같은 자리에서 바뀌어 흐려지며 사라지는 앞 글
  TrialPrompt? _leaving;
  var _first = true;

  bool get _still => MediaQuery.disableAnimationsOf(context);

  static _Timeline _timelineOf(String lead) =>
      _Timeline(keepWords(lead).split(' ').length);

  void _start() {
    _timeline = _timelineOf(widget.lead);
    _play.duration = _timeline.total;
    _play.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_first) return;
    _first = false;
    if (widget.reward && !_still) _start();
  }

  @override
  void didUpdateWidget(TrialPrompt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lead == widget.lead &&
        oldWidget.headline == widget.headline &&
        oldWidget.guide == widget.guide &&
        oldWidget.reward == widget.reward) {
      return;
    }
    if (widget.reward && !_still) {
      _leaving = oldWidget;
      _start();
    } else {
      _leaving = null;
      _play.value = 1;
    }
  }

  void _played(AnimationStatus status) {
    if (status == AnimationStatus.completed && _leaving != null) {
      setState(() => _leaving = null);
    }
  }

  @override
  void dispose() {
    _play.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.reward
        ? _Reward(
            lead: widget.lead,
            headline: widget.headline,
            guide: widget.guide,
            play: _play,
            timeline: _timeline,
          )
        : MeetingQuestionPrompt(
            lead: widget.lead,
            headline: widget.headline,
            guide: widget.guide,
          );
    final leaving = _leaving;
    if (leaving == null) return current;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        current,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: FadeTransition(
                opacity: ReverseAnimation(
                  _play.drive(CurveTween(curve: _timeline.leave)),
                ),
                // 보상 줄도 끝 모습은 보통 앞 줄과 같다
                child: MeetingQuestionPrompt(
                  lead: leaving.lead,
                  headline: leaving.headline,
                  guide: leaving.guide,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 보상 줄과 큰 한 줄. [play]가 1이면 끝 모습이다
class _Reward extends StatelessWidget {
  const _Reward({
    required this.lead,
    required this.headline,
    required this.guide,
    required this.play,
    required this.timeline,
  });

  final String lead;
  final String headline;
  final String? guide;
  final AnimationController play;
  final _Timeline timeline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final guide = this.guide;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: play,
          builder: (context, _) => play.isCompleted
              ? Text(keepWords(lead), style: theme.textTheme.bodyLarge)
              : _Reveal(lead: lead, play: play, timeline: timeline),
        ),
        const SizedBox(height: 16),
        _Enter(
          shown: play.drive(CurveTween(curve: timeline.headline)),
          child: Semantics(
            header: true,
            child: Text(
              keepWords(headline),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
        if (guide != null) ...[
          const SizedBox(height: 6),
          _Enter(
            shown: play.drive(CurveTween(curve: timeline.guide)),
            child: Text(
              keepWords(guide),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
