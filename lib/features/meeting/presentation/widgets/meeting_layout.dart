import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_quiet_panels.dart';

/// 모임 화면의 배치. 넓으면 왼쪽에 [main](격자), 오른쪽 칸에 [side]를 위에서부터 둔다(상자 모양).
///
/// 넓은 화면의 오른쪽 칸은 화면 높이를 넘지 않는다. [sideFill]은 [side] 아래 남은 높이를 채우고(스스로 굴린다),
/// 오른쪽 칸이 그래도 넘치면 그 칸 안에서 굴린다. 화면은 격자가 화면보다 길 때만 굴러가고, 그동안 오른쪽 칸은
/// 화면에 머문다.
///
/// 좁으면 중요한 순서로 쌓는다: [header](조용한 한 줄) → [main] → [secondary] → [tertiary]. 끝의 [tertiary]는
/// 상자 없이 작은 제목으로 두고 구분선으로 나눈다. [bottom]은 화면 아래에 붙어 굴려도 그 자리다. 같은 위젯을
/// [side]와 좁은 목록에 함께 넣어도 한쪽만 그린다.
class MeetingLayout extends StatelessWidget {
  const MeetingLayout({
    super.key,
    required this.main,
    required this.side,
    this.sideFill,
    this.header,
    this.secondary = const [],
    this.tertiary = const [],
    this.bottom,
  });

  /// 이 폭부터 두 칸
  static const _twoColumnsFrom = 840.0;

  /// 폭 [width]가 좁은(한 칸) 배치인지
  static bool narrow(double width) => width < _twoColumnsFrom;

  final Widget main;
  final List<Widget> side;
  final Widget? sideFill;
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
        return _WideLayout(main: main, side: side, sideFill: sideFill);
      },
    );
  }
}

/// 넓은 배치: 왼쪽 [main], 오른쪽 화면 높이의 칸. 화면이 굴러가도 오른쪽 칸은 화면에 머문다
class _WideLayout extends StatefulWidget {
  const _WideLayout({
    required this.main,
    required this.side,
    required this.sideFill,
  });

  final Widget main;
  final List<Widget> side;
  final Widget? sideFill;

  @override
  State<_WideLayout> createState() => _WideLayoutState();
}

class _WideLayoutState extends State<_WideLayout> {
  static const _padding = 24.0;
  static const _sideWidth = 380.0;

  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// 오른쪽 칸을 화면에 붙여 두려고 내리는 거리
  double get _stuck =>
      _scroll.hasClients && _scroll.position.hasContentDimensions
      ? _scroll.offset.clamp(0, _scroll.position.maxScrollExtent)
      : 0;

  @override
  Widget build(BuildContext context) {
    // 머리띠 뒤로 이어진 본문이라 위 여백에 머리띠 높이를 더한다
    final top = MediaQuery.paddingOf(context).top;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.all(_padding).add(EdgeInsets.only(top: top)),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: widget.main),
                const SizedBox(width: _padding),
                SizedBox(
                  width: _sideWidth,
                  height: math.max(
                    0,
                    constraints.maxHeight - top - _padding * 2,
                  ),
                  child: AnimatedBuilder(
                    animation: _scroll,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _stuck),
                      child: child,
                    ),
                    child: _SideColumn(
                      side: widget.side,
                      fill: widget.sideFill,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 오른쪽 칸: [side]를 위에서부터 두고 [fill]이 남은 높이(적어도 [_minFill])를 채운다. 넘치면 칸 안에서 굴린다
class _SideColumn extends StatelessWidget {
  const _SideColumn({required this.side, required this.fill});

  final List<Widget> side;
  final Widget? fill;

  static const _gap = 16.0;
  static const _minFill = 200.0;

  @override
  Widget build(BuildContext context) {
    final fill = this.fill;
    return CustomScrollView(
      slivers: [
        for (final (i, child) in side.indexed)
          SliverPadding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : _gap),
            sliver: SliverToBoxAdapter(child: child),
          ),
        if (fill != null)
          SliverLayoutBuilder(
            builder: (context, constraints) => SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: side.isEmpty ? 0 : _gap),
                child: SizedBox(
                  height: math.max(
                    _minFill,
                    constraints.viewportMainAxisExtent -
                        constraints.precedingScrollExtent -
                        (side.isEmpty ? 0 : _gap),
                  ),
                  child: fill,
                ),
              ),
            ),
          ),
      ],
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
      padding: EdgeInsets.fromLTRB(
        16,
        (header == null ? 12 : 4) + MediaQuery.paddingOf(context).top,
        16,
        32,
      ),
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
