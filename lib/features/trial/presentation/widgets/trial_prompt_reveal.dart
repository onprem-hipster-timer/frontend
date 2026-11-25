part of 'trial_prompt.dart';

/// 나타나는 중인 보상 줄. 끝 모습의 글을 보이지 않게 두어 배치와 스크린 리더를 맡기고, 그 위에 낱말마다 끝
/// 모습의 자리에 그린다. 글 색은 [_tint]가 칠한다
class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.lead,
    required this.play,
    required this.timeline,
  });

  final String lead;
  final Animation<double> play;
  final _Timeline timeline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = keepWords(lead);
    final style = DefaultTextStyle.of(
      context,
    ).style.merge(theme.textTheme.bodyLarge);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: direction,
          textScaler: scaler,
        )..layout(maxWidth: constraints.maxWidth);
        // 낱말을 따로 그린 첫 글자가 온 글의 그 글자 자리에 겹치게 놓는다
        Rect firstGlyph(TextPainter painter, int at) => painter
            .getBoxesForSelection(
              TextSelection(baseOffset: at, extentOffset: at + 1),
            )
            .first
            .toRect();
        final words = <({String word, Offset at})>[];
        var start = 0;
        for (final word in text.split(' ')) {
          final alone = TextPainter(
            text: TextSpan(text: word, style: style),
            textDirection: direction,
            textScaler: scaler,
          )..layout();
          final there = firstGlyph(painter, start);
          final here = firstGlyph(alone, 0);
          alone.dispose();
          words.add((word: word, at: there.topLeft - here.topLeft));
          start += word.length + 1;
        }
        painter.dispose();
        final mask = style.copyWith(color: Colors.white);
        return Stack(
          children: [
            Text(text, style: style.copyWith(color: Colors.transparent)),
            Positioned.fill(
              child: ExcludeSemantics(
                child: ShaderMask(
                  key: TrialPrompt.revealKey,
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => _tint(theme.colorScheme, bounds),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final (index, word) in words.indexed)
                        Positioned(
                          left: word.at.dx,
                          top: word.at.dy,
                          child: _Word(
                            shown: play.drive(
                              CurveTween(curve: timeline.word(index)),
                            ),
                            child: Text(
                              word.word,
                              style: mask,
                              textScaler: scaler,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 주색에서 옆 색으로 번지는 글 색. 밝은 띠가 지나가고, 보통 앞 줄의 색으로 돌아온다
  Shader _tint(ColorScheme scheme, Rect bounds) {
    final sheen = timeline.sheen.transform(play.value);
    final relax = timeline.relax.transform(play.value);
    final plain = scheme.onSurface;
    final from = Color.lerp(scheme.primary, plain, relax)!;
    final to = Color.lerp(scheme.tertiary, plain, relax)!;
    Color base(double t) => Color.lerp(from, to, t)!;
    // 밝은 띠는 화면 바탕 쪽으로 밝힌다(어두운 테마에서는 글 쪽)
    final light = scheme.brightness == Brightness.light
        ? scheme.surface
        : scheme.onSurface;
    final passing = sheen > 0 && sheen < 1;
    final center = -_sheenWidth + sheen * (1 + 2 * _sheenWidth);
    final stops = passing
        ? [
            0.0,
            (center - _sheenWidth).clamp(0.0, 1.0),
            center.clamp(0.0, 1.0),
            (center + _sheenWidth).clamp(0.0, 1.0),
            1.0,
          ]
        : [0.0, 1.0];
    // 띠의 가운데(셋째 멈춤)만 밝힌다
    final colors = [
      for (final (index, stop) in stops.indexed)
        passing && index == 2
            ? Color.lerp(base(stop), light, 0.7)!
            : base(stop),
    ];
    return LinearGradient(
      colors: colors,
      stops: stops,
    ).createShader(Offset.zero & bounds.size);
  }
}

/// [shown]에 따라 흐림과 아래 [trialRewardRiseBy] 자리에서 또렷해지며 올라오는 낱말
class _Word extends StatelessWidget {
  const _Word({required this.shown, required this.child});

  final Animation<double> shown;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: shown,
      child: AnimatedBuilder(
        animation: shown,
        builder: (context, child) {
          final left = 1 - shown.value;
          final blur = trialRewardBlur * left;
          return Transform.translate(
            offset: Offset(0, trialRewardRiseBy * left),
            child: blur < 0.01
                ? child
                : ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: child,
                  ),
          );
        },
        child: child,
      ),
    );
  }
}
