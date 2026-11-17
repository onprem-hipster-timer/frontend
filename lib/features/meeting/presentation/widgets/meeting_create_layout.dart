import 'package:material_ui/material_ui.dart';

/// 모임 만들기 화면의 틀: 유리 머리띠 아래에서 시작하는 굴림 영역 가운데에 폭 [maxWidth]까지 내용을 놓는다.
/// 넓으면(폭 [wideFrom] 이상) 카드에 담는다. [footer]는 내용 맨 아래 오른쪽에 둔다. [maxWidth]가 바뀌면 폭이
/// 부드럽게 바뀐다(애니메이션을 줄였으면 바로)
class MeetingCreateLayout extends StatelessWidget {
  const MeetingCreateLayout({
    super.key,
    required this.builder,
    this.maxWidth = 880,
    this.footer,
  });

  /// 이 폭부터 넓은 배치
  static const wideFrom = 720.0;

  /// [wide]면 넓은 배치의 내용을 만든다
  final Widget Function(BuildContext context, bool wide) builder;

  final double maxWidth;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final footer = this.footer;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= wideFrom;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            builder(context, wide),
            if (footer != null) ...[
              const SizedBox(height: 16),
              Align(alignment: AlignmentDirectional.centerEnd, child: footer),
            ],
          ],
        );
        final box = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: wide
              ? Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: content,
                  ),
                )
              : content,
        );
        return SingleChildScrollView(
          padding: EdgeInsets.all(
            wide ? 32 : 16,
          ).add(EdgeInsets.only(top: MediaQuery.paddingOf(context).top)),
          child: Center(
            child: MediaQuery.disableAnimationsOf(context)
                ? box
                : AnimatedSize(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    child: box,
                  ),
          ),
        );
      },
    );
  }
}
