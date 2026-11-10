import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// 다이얼 옆에 둘 때 작업 제목·시계·버튼 칸의 가장 좁은 폭. 일시정지 타이머의 버튼 세 개(216)가 들어간다
const _sideControlsMinWidth = 232.0;

/// 낮은 칸에서 다이얼을 옆에 둘 때 다이얼이 이보다 작아지면 위아래로 둔다
const _sideDialMinSide = 80.0;

/// 대시보드 배치
///
/// 보통은 위에서부터 [addTimer], [header], [dial](남는 높이를 모두 씀), [controls]를 둔다.
/// 높이 400 미만이고 폭이 높이 이상이며 옆에 두어도 다이얼이 [_sideDialMinSide] 이상인 칸(가로 휴대폰)은
/// 다이얼을 왼쪽에 두고 나머지를 오른쪽에 두며, 오른쪽이 칸보다 길면 굴린다.
class TimerDashboardLayout extends StatelessWidget {
  const TimerDashboardLayout({
    super.key,
    required this.constraints,
    required this.dial,
    required this.addTimer,
    required this.header,
    required this.controls,
  });

  final BoxConstraints constraints;
  final Widget dial;
  final Widget? addTimer;
  final Widget header;

  /// 시계부터 조작 버튼까지. 칸이 낮으면 사이 간격이 좁다
  final List<Widget> controls;

  /// 칸이 낮은지. 낮으면 간격과 시계를 줄인다
  static bool isShort(BoxConstraints constraints) =>
      constraints.maxHeight < 400;

  @override
  Widget build(BuildContext context) {
    final short = isShort(constraints);
    final gap = SizedBox(height: short ? 8 : 16);
    final addTimer = this.addTimer;
    final sideDialWidth =
        constraints.maxWidth - 24 * 2 - 16 - _sideControlsMinWidth;
    if (short &&
        constraints.maxWidth >= constraints.maxHeight &&
        sideDialWidth >= _sideDialMinSide) {
      return _SideBySide(
        dial: dial,
        addTimer: addTimer,
        children: [header, gap, ...controls],
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: short ? 8 : 16),
      child: Column(
        children: [
          if (addTimer != null) ...[
            Align(alignment: Alignment.centerRight, child: addTimer),
            gap,
          ],
          header,
          gap,
          Expanded(child: dial),
          gap,
          ...controls,
        ],
      ),
    );
  }
}

/// 낮고 넓은 칸의 배치. 다이얼을 왼쪽에, [addTimer]와 [children]을 오른쪽에 두고 오른쪽이 길면 굴린다
class _SideBySide extends StatelessWidget {
  const _SideBySide({
    required this.dial,
    required this.addTimer,
    required this.children,
  });

  final Widget dial;
  final Widget? addTimer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final addTimer = this.addTimer;
    return LayoutBuilder(
      builder: (context, constraints) {
        final controlsWidth = math.max(
          _sideControlsMinWidth,
          (constraints.maxWidth - 24 * 2 - 16) / 2,
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Expanded(child: dial),
              const SizedBox(width: 16),
              SizedBox(
                width: controlsWidth,
                child: Column(
                  children: [
                    if (addTimer != null)
                      Align(alignment: Alignment.centerRight, child: addTimer),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: children,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
