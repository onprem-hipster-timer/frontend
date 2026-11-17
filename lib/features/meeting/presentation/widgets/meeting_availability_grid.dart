import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_shading.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_cells.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_geometry.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_legend.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_hourly_grid.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 내 시간 격자와 색 설명. 방식마다 모양이 다르다.
///
/// - 시간별: 위에 날짜, 왼쪽에 정각 시각, 날짜마다 세로 띠(정각 실선, 그 밖의 칸 경계 점선)([MeetingHourlyGrid])
/// - 날짜별: 일요일부터의 요일 머리와 달력 칸
/// - 요일별: 월요일부터 일곱 칸
///
/// [brush]로 칠한다. [onPaint]가 없으면 칠할 수 없고, 칸을 누르면 [onLocked]를 부른다([MeetingGridCells]).
class MeetingAvailabilityGrid extends StatelessWidget {
  const MeetingAvailabilityGrid({
    super.key,
    required this.shading,
    required this.onPaint,
    this.brush = MeetingAnswer.available,
    this.onBlocked,
    this.onResetDay,
    this.dayShakes = const {},
    this.onLocked,
  });

  final MeetingShading shading;
  final MeetingPaint? onPaint;
  final MeetingAnswer brush;

  /// 다른 방식으로 표시한 묶음이라 칠하지 못했다
  final MeetingBlocked? onBlocked;

  /// 시간별 날짜 머리로 답한 날을 지운다
  final ValueChanged<List<MeetingCell>>? onResetDay;

  /// 시간별 날짜 열마다 날짜 머리를 떤 횟수
  final Map<int, int> dayShakes;
  final VoidCallback? onLocked;

  @override
  Widget build(BuildContext context) {
    final grid = shading.grid;
    if (grid.cells.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('이 모임 기간에는 고를 수 있는 날이 없습니다'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        switch (grid.mode) {
          MeetingMode.hourly => MeetingHourlyGrid(
            shading: shading,
            brush: brush,
            onPaint: onPaint,
            onBlocked: onBlocked,
            onResetDay: onResetDay,
            dayShakes: dayShakes,
            onLocked: onLocked,
          ),
          MeetingMode.weekly => MeetingGridCells(
            shading: shading,
            shape: MeetingCellShape.weekly,
            brush: brush,
            onPaint: onPaint,
            onBlocked: onBlocked,
            onLocked: onLocked,
          ),
          MeetingMode.daily || MeetingMode.$unknown => _DailyGrid(
            shading: shading,
            brush: brush,
            onPaint: onPaint,
            onBlocked: onBlocked,
            onLocked: onLocked,
          ),
        },
        const SizedBox(height: 8),
        MeetingGridLegend(
          othersTotal: shading.othersTotal,
          hasSelf: shading.hasSelf,
        ),
      ],
    );
  }
}

const _sundayFirstHeads = ['일', '월', '화', '수', '목', '금', '토'];

/// 날짜별: 일요일부터의 요일 머리와 달력 칸
class _DailyGrid extends StatelessWidget {
  const _DailyGrid({
    required this.shading,
    required this.brush,
    required this.onPaint,
    required this.onBlocked,
    required this.onLocked,
  });

  final MeetingShading shading;
  final MeetingAnswer brush;
  final MeetingPaint? onPaint;
  final MeetingBlocked? onBlocked;

  final VoidCallback? onLocked;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    final gap = MeetingCellShape.daily.columnGap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              for (var column = 0; column < 7; column++) ...[
                if (column > 0) SizedBox(width: gap),
                Expanded(
                  child: Text(
                    _sundayFirstHeads[column],
                    textAlign: TextAlign.center,
                    style: style?.copyWith(
                      color: meetingWeekendColor(context, column),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        MeetingGridCells(
          shading: shading,
          shape: MeetingCellShape.daily,
          brush: brush,
          onPaint: onPaint,
          onBlocked: onBlocked,
          onLocked: onLocked,
        ),
      ],
    );
  }
}
