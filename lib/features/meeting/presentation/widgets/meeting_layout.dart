import 'package:material_ui/material_ui.dart';

/// 모임 화면의 배치. 넓으면 왼쪽에 [main](격자), 오른쪽 칸에 [side]를 위에서부터 둔다. 좁으면 [stacked]를
/// 위에서 아래로 쌓는다(같은 위젯을 두 목록에 넣어도 한쪽만 그린다).
class MeetingLayout extends StatelessWidget {
  const MeetingLayout({
    super.key,
    required this.main,
    required this.side,
    required this.stacked,
  });

  /// 이 폭부터 두 칸
  static const _twoColumnsFrom = 840.0;
  static const _sideWidth = 380.0;

  final Widget main;
  final List<Widget> side;
  final List<Widget> stacked;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _twoColumnsFrom) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, child) in stacked.indexed) ...[
                  // 격자 앞뒤는 상자 사이보다 넓게 띄운다
                  if (i > 0)
                    SizedBox(
                      height:
                          identical(child, main) ||
                              identical(stacked[i - 1], main)
                          ? 24
                          : 12,
                    ),
                  child,
                ],
              ],
            ),
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
