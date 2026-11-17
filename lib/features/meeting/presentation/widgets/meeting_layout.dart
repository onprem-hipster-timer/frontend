import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_quiet_panels.dart';

/// 모임 화면의 배치. 넓으면 왼쪽에 [main](격자), 오른쪽 칸에 [side]를 위에서부터 둔다(상자 모양).
///
/// 좁으면 중요한 순서로 쌓는다: [header](조용한 한 줄) → [main] → [secondary] → [tertiary]. 끝의 [tertiary]는
/// 상자 없이 작은 제목으로 두고 구분선으로 나눈다. [bottom]은 화면 아래에 붙어 굴려도 그 자리다. 같은 위젯을
/// [side]와 좁은 목록에 함께 넣어도 한쪽만 그린다.
class MeetingLayout extends StatelessWidget {
  const MeetingLayout({
    super.key,
    required this.main,
    required this.side,
    this.header,
    this.secondary = const [],
    this.tertiary = const [],
    this.bottom,
  });

  /// 이 폭부터 두 칸
  static const _twoColumnsFrom = 840.0;
  static const _sideWidth = 380.0;

  /// 폭 [width]가 좁은(한 칸) 배치인지
  static bool narrow(double width) => width < _twoColumnsFrom;

  final Widget main;
  final List<Widget> side;
  final Widget? header;
  final List<Widget> secondary;
  final List<Widget> tertiary;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (narrow(constraints.maxWidth)) {
          return _NarrowLayout(
            header: header,
            main: main,
            secondary: secondary,
            tertiary: tertiary,
            bottom: bottom,
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: main),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: _sideWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, child) in side.indexed) ...[
                          if (i > 0) const SizedBox(height: 16),
                          child,
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 좁은 배치: 중요한 순서로 쌓고 [bottom]은 화면 아래에 붙인다
class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.header,
    required this.main,
    required this.secondary,
    required this.tertiary,
    required this.bottom,
  });

  final Widget? header;
  final Widget main;
  final List<Widget> secondary;
  final List<Widget> tertiary;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final header = this.header;
    final bottom = this.bottom;
    final content = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, header == null ? 12 : 4, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[
            MeetingQuietPanels(child: header),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 16),
          ],
          main,
          for (final child in secondary) ...[const SizedBox(height: 32), child],
          if (tertiary.isNotEmpty) ...[
            const SizedBox(height: 20),
            MeetingQuietPanels(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final child in tertiary) ...[
                    const Divider(height: 24),
                    child,
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
    if (bottom == null) return content;
    return Column(
      children: [
        Expanded(child: content),
        bottom,
      ],
    );
  }
}
