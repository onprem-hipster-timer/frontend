import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';

/// 캘린더 뷰 전환을 위한 Segmented Button 위젯
///
/// Material 3의 SegmentedButton을 사용하여 일간/주간/월간/아젠다 뷰를 전환할 수 있습니다.
class CalendarViewSelector extends ConsumerWidget {
  /// AppBar에 사용할지 여부 (컴팩트 사이즈)
  final bool isCompact;

  const CalendarViewSelector({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(calendarSettingsProvider);
    final theme = Theme.of(context);

    final segments = [
      ButtonSegment<CalendarViewType>(
        value: CalendarViewType.day,
        label: isCompact ? null : const Text('일'),
        icon: Icon(Icons.view_day, size: isCompact ? 16 : 18),
        tooltip: '일간',
      ),
      ButtonSegment<CalendarViewType>(
        value: CalendarViewType.week,
        label: isCompact ? null : const Text('주'),
        icon: Icon(Icons.view_week, size: isCompact ? 16 : 18),
        tooltip: '주간',
      ),
      ButtonSegment<CalendarViewType>(
        value: CalendarViewType.month,
        label: isCompact ? null : const Text('월'),
        icon: Icon(Icons.calendar_view_month, size: isCompact ? 16 : 18),
        tooltip: '월간',
      ),
      ButtonSegment<CalendarViewType>(
        value: CalendarViewType.agenda,
        label: isCompact ? null : const Text('목록'),
        icon: Icon(Icons.view_list, size: isCompact ? 16 : 18),
        tooltip: '아젠다',
      ),
    ];

    final segmentedButton = SegmentedButton<CalendarViewType>(
      segments: segments,
      selected: {settings.viewType},
      onSelectionChanged: (newSelection) {
        if (newSelection.isNotEmpty) {
          ref
              .read(calendarSettingsProvider.notifier)
              .setViewType(newSelection.first);
        }
      },
      style: ButtonStyle(
        visualDensity:
            isCompact ? VisualDensity.compact : VisualDensity.standard,
        textStyle: WidgetStateProperty.all(
          theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isCompact ? 10 : 12,
          ),
        ),
      ),
    );

    if (isCompact) {
      // AppBar용 컴팩트 버전
      return segmentedButton;
    } else {
      // 일반 버전 (기존)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: segmentedButton,
      );
    }
  }
}
