import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 다이얼 옆에 둘 때 작업 제목·시계·버튼 칸의 가장 좁은 폭. 일시정지 타이머의 버튼 세 개(216)가 들어간다
const _sideControlsMinWidth = 232.0;

/// 낮은 칸에서 다이얼을 옆에 둘 때 다이얼이 이보다 작아지면 위아래로 둔다
const _sideDialMinSide = 80.0;

/// 대시보드 배치
///
/// 보통은 위에서부터 [addTimer], [header], [dial](남는 높이를 모두 씀), [controls]를 둔다.
/// 높이 400 미만인데 다이얼을 옆에 둘 수 없으면 다이얼을 칸 높이의 절반으로 두고 넘치는 만큼 굴린다.
/// 아주 작은 화면의 집중 보기([focus])는 시계를 다이얼 가운데에 겹친다.
/// 높이 400 미만이고 폭이 높이 이상이며 옆에 두어도 다이얼이 [_sideDialMinSide] 이상인 칸(가로 휴대폰)은
/// 다이얼을 왼쪽에 두고 나머지를 오른쪽에 두며, 오른쪽이 칸보다 길면 굴린다.
class TimerDashboardLayout extends StatelessWidget {
  const TimerDashboardLayout({
    super.key,
    required this.constraints,
    required this.dial,
    required this.addTimer,
    required this.header,
    required this.clock,
    required this.controls,
    this.focus = false,
    this.focusLeading,
    this.focusActions = const [],
  });

  final BoxConstraints constraints;
  final Widget dial;
  final Widget? addTimer;
  final Widget header;

  /// 남은 시간 시계
  final Widget clock;

  /// 시계 아래 상태 문구부터 조작 버튼까지
  final List<Widget> controls;

  /// 아주 작은 화면의 집중 보기. 시계를 다이얼 가운데에 겹치고 [addTimer]를 제목 옆에 둔다
  final bool focus;

  /// 집중 보기의 작업명 줄 왼쪽·오른쪽에 두는 것
  final Widget? focusLeading;
  final List<Widget> focusActions;

  /// 칸이 낮은지. 낮으면 간격과 시계를 줄인다
  static bool isShort(BoxConstraints constraints) =>
      constraints.maxHeight < 400;

  @override
  Widget build(BuildContext context) {
    final short = isShort(constraints);
    final gap = SizedBox(height: short ? 8 : 16);
    final addTimer = this.addTimer;
    if (focus) {
      return _Focus(
        leading: focusLeading,
        actions: focusActions,
        dial: dial,
        clock: clock,
        addTimer: addTimer,
        header: header,
        gap: gap,
        controls: controls,
      );
    }
    final below = [clock, ...controls];
    final sideDialWidth =
        constraints.maxWidth - 24 * 2 - 16 - _sideControlsMinWidth;
    if (short &&
        constraints.maxWidth >= constraints.maxHeight &&
        sideDialWidth >= _sideDialMinSide) {
      return _SideBySide(
        dial: dial,
        addTimer: addTimer,
        children: [header, gap, ...below],
      );
    }
    if (short) {
      // 낮고 좁은 칸은 다이얼을 칸 높이의 절반으로 두고, 나머지가 넘치면 굴린다
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            if (addTimer != null) ...[
              Align(alignment: Alignment.centerRight, child: addTimer),
              gap,
            ],
            header,
            gap,
            SizedBox(height: constraints.maxHeight / 2, child: dial),
            gap,
            ...below,
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
          ...below,
        ],
      ),
    );
  }
}

/// 아주 작은 화면의 집중 보기. 제목 줄 옆에 [addTimer], 다이얼 가운데에 [clock], 아래에 [controls]
class _Focus extends StatelessWidget {
  const _Focus({
    required this.leading,
    required this.actions,
    required this.dial,
    required this.clock,
    required this.addTimer,
    required this.header,
    required this.gap,
    required this.controls,
  });

  final Widget? leading;
  final List<Widget> actions;
  final Widget dial;
  final Widget clock;
  final Widget? addTimer;
  final Widget header;
  final Widget gap;
  final List<Widget> controls;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
      child: Column(
        children: [
          // 작업명은 남은 시간보다 덜 눈에 띄게 한 단계 작게, 큰 글자 설정에서도 1.3배까지만 키운다
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Theme(
              data: theme.copyWith(
                textTheme: theme.textTheme.copyWith(
                  titleLarge: theme.textTheme.titleMedium,
                ),
              ),
              child: Row(
                children: [
                  ?leading,
                  Expanded(child: header),
                  ?addTimer,
                  ...actions,
                ],
              ),
            ),
          ),
          gap,
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                alignment: Alignment.center,
                children: [
                  dial,
                  // 다이얼 안쪽(긴 눈금 안) 지름의 72%까지 쓰고, 바탕 판으로 가운데 점·부채꼴을 가린다
                  SizedBox(
                    width: constraints.biggest.shortestSide * 0.72,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.9),
                        borderRadius: AppRadius.pillAll,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        // 남은 시간이 화면의 첫 정보가 되게 판 폭에 맞춰 키운다
                        child: FittedBox(child: clock),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
