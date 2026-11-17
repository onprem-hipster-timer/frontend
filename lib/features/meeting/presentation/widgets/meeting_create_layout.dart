import 'package:material_ui/material_ui.dart';

/// 모임 만들기 화면의 틀: 유리 머리띠 아래에서 시작하는 굴림 영역 가운데에 폭 [maxWidth]까지 내용을 놓는다.
/// 넓으면(폭 [wideFrom] 이상) 카드에 담는다. [header]는 내용 맨 위 오른쪽에 한 줄로, [footer]는 내용 맨 아래
/// 오른쪽에 둔다. [maxWidth]가 바뀌면 폭이
/// 부드럽게 바뀐다(애니메이션을 줄였으면 바로)
class MeetingCreateLayout extends StatelessWidget {
  const MeetingCreateLayout({
    super.key,
    required this.builder,
    this.maxWidth = 880,
    this.header,
    this.footer,
  });

  /// 이 폭부터 넓은 배치
  static const wideFrom = 720.0;

  /// [wide]면 넓은 배치의 내용을 만든다
  final Widget Function(BuildContext context, bool wide) builder;

  final double maxWidth;
  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final header = this.header;
    final footer = this.footer;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= wideFrom;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) ...[
              Align(alignment: AlignmentDirectional.centerEnd, child: header),
              const SizedBox(height: 8),
            ],
            builder(context, wide),
            if (footer != null) ...[
              const SizedBox(height: 16),
              Align(alignment: AlignmentDirectional.centerEnd, child: footer),
            ],
          ],
        );
        final box = wide
            ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: content,
                ),
              )
            : content;
        // 폭만 부드럽게 바꾼다. 높이는 내용을 그대로 따라 늘 모두 누를 수 있다
        return SingleChildScrollView(
          padding: EdgeInsets.all(
            wide ? 32 : 16,
          ).add(EdgeInsets.only(top: MediaQuery.paddingOf(context).top)),
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: maxWidth),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              builder: (context, width, child) => ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width),
                child: child,
              ),
              child: box,
            ),
          ),
        );
      },
    );
  }
}
