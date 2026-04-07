import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 특정 날짜의 일정 목록을 표시하는 바텀시트
///
/// 다중 일정이 있는 날짜를 탭하거나 "+N more"를 탭했을 때
/// 해당 날짜의 모든 일정을 리스트로 표시합니다.
/// 일정을 선택하면 상세 페이지로 이동합니다.
class ScheduleListSheet extends StatelessWidget {
  static final _headerDateFormat = DateFormat('M월 d일 (E)', 'ko');
  static final _timeFormat = DateFormat('HH:mm');

  final DateTime date;
  final List<ScheduleRead> schedules;

  const ScheduleListSheet({
    super.key,
    required this.date,
    required this.schedules,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 날짜 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  _headerDateFormat.format(date),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${schedules.length}개 일정',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 일정 목록
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: schedules.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 56),
              itemBuilder: (context, index) {
                final schedule = schedules[index];
                return _buildScheduleTile(context, theme, schedule);
              },
            ),
          ),

          // 안전 영역
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildScheduleTile(
    BuildContext context,
    ThemeData theme,
    ScheduleRead schedule,
  ) {
    final hasTag = schedule.tags.isNotEmpty;
    final tagColor = hasTag
        ? HexColor.fromHex(schedule.tags.first.color)
        : theme.colorScheme.outlineVariant;

    final start = schedule.startTime.toLocal();
    final end = schedule.endTime.toLocal();
    final isAllDay =
        start.hour == 0 &&
        start.minute == 0 &&
        end.hour == 0 &&
        end.minute == 0 &&
        end.difference(start).inHours >= 24;

    final timeText = isAllDay
        ? '종일'
        : '${_timeFormat.format(start)} - ${_timeFormat.format(end)}';

    return ListTile(
      leading: Container(
        width: 4,
        height: 40,
        decoration: BoxDecoration(
          color: tagColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(
        schedule.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        timeText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {
        Navigator.of(context).pop();
        context.pushNamed(
          AppRoute.scheduleDetail.name,
          queryParameters: {'id': schedule.id},
        );
      },
    );
  }
}

/// 일정 목록 바텀시트를 표시하는 헬퍼 함수
Future<void> showScheduleListSheet(
  BuildContext context,
  DateTime date,
  List<ScheduleRead> schedules,
) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.5,
    ),
    builder: (context) => ScheduleListSheet(date: date, schedules: schedules),
  );
}
