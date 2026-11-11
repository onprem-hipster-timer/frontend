import 'package:material_ui/material_ui.dart';

/// 칸에 다 들어가지 않는 한 줄 글자를 [active]인 동안 전광판처럼 왼쪽으로 흘린다
///
/// [active]가 아니거나, 다 들어가거나, 시스템의 동작 줄이기가 켜져 있으면 [maxLines]줄까지 보이고
/// 나머지는 말줄임으로 줄인다. 흐르는 동안에도 스크린 리더는 제목을 한 번만 읽는다.
class MarqueeText extends StatefulWidget {
  const MarqueeText(
    this.text, {
    super.key,
    required this.style,
    required this.active,
    this.maxLines = 1,
    this.loops,
  });

  final String text;
  final TextStyle style;
  final bool active;
  final int maxLines;

  /// 이만큼 흐른 뒤 멈추고 말줄임으로 돌아간다. null이면 [active]인 동안 계속 흐른다
  final int? loops;

  /// 흐르는 속도(논리 픽셀/초)
  static const speed = 40.0;

  /// 끝과 다시 시작하는 글자 사이 간격
  static const gap = 32.0;

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _finished = true);
      }
    });

  /// [MarqueeText.loops]만큼 다 흘렀는지
  bool _finished = false;

  @override
  void didUpdateWidget(MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 다시 활성이 되면 처음부터 흐른다
    if (widget.active && !oldWidget.active) _finished = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 한 바퀴 거리 [distance]로 돌린다. 이미 같은 거리로 돌고 있으면 그대로 둔다
  void _run(double distance) {
    final duration = Duration(
      milliseconds: (distance / MarqueeText.speed * 1000).round(),
    );
    if (_controller.isAnimating && _controller.duration == duration) return;
    _controller
      ..duration = duration
      ..repeat(count: widget.loops);
  }

  @override
  Widget build(BuildContext context) {
    final still = Text(
      widget.text,
      maxLines: widget.maxLines,
      overflow: TextOverflow.ellipsis,
      style: widget.style,
    );
    if (!widget.active ||
        _finished ||
        MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      return still;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          textScaler: MediaQuery.textScalerOf(context),
          textDirection: Directionality.of(context),
          maxLines: 1,
        )..layout();
        final textWidth = painter.width;
        final lineHeight = painter.height;
        painter.dispose();
        if (textWidth <= constraints.maxWidth) {
          _controller.stop();
          return still;
        }
        final distance = textWidth + MarqueeText.gap;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.active) _run(distance);
        });
        final line = Text(
          widget.text,
          maxLines: 1,
          softWrap: false,
          style: widget.style,
        );
        return SizedBox(
          width: constraints.maxWidth,
          height: lineHeight,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.translate(
                offset: Offset(-_controller.value * distance, 0),
                child: child,
              ),
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: double.infinity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    line,
                    const SizedBox(width: MarqueeText.gap),
                    // 이어 붙인 두 번째 글자는 끊김 없이 돌기 위한 것이라 읽지 않는다
                    ExcludeSemantics(child: line),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
