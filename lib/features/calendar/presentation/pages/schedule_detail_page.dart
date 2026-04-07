import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_detail_providers.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_mutations.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_form_sheet.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/pages/tag_group_selector_page.dart';
import 'package:momeet/shared/widgets/confirm_dialog.dart';

/// 캘린더에서 일정을 탭하면 이동하는 풀스크린 상세 페이지.
/// 일정 정보, 타이머 이력, TODO 변환, 수정/삭제 기능을 제공합니다.
class ScheduleDetailPage extends ConsumerWidget {
  static final _dateFormat = DateFormat('yyyy.MM.dd HH:mm');
  static final _dateFormatFull = DateFormat('yyyy년 MM월 dd일 (E)', 'ko');
  static final _dateFormatShort = DateFormat('yyyy년 MM월 dd일', 'ko');
  static final _timeFormat = DateFormat('HH:mm', 'ko');
  static final _dateTimeFormat = DateFormat('yyyy년 MM월 dd일 HH:mm', 'ko');

  final String scheduleId;

  const ScheduleDetailPage({super.key, required this.scheduleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheduleAsync = ref.watch(scheduleDetailProvider(scheduleId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('일정 상세'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: scheduleAsync.when(
        data: (schedule) => _buildBody(context, ref, theme, schedule),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('일정을 불러올 수 없습니다', style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () =>
                    ref.invalidate(scheduleDetailProvider(scheduleId)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ScheduleRead schedule,
  ) {
    final mutations = ref.watch(scheduleMutationsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScheduleHeader(theme, schedule),
          const SizedBox(height: 24),
          _buildScheduleInfo(context, schedule),
          const SizedBox(height: 16),
          _buildTimerSection(context, ref, schedule.id),
          const SizedBox(height: 16),
          _buildTodoConversionRow(context, ref, schedule, mutations),
          const SizedBox(height: 16),
          _buildActionButtons(context, ref, schedule, mutations),
        ],
      ),
    );
  }

  Widget _buildScheduleHeader(ThemeData theme, ScheduleRead schedule) {
    return Row(
      children: [
        Icon(Icons.event, color: theme.colorScheme.primary, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            schedule.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleInfo(BuildContext context, ScheduleRead schedule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(
          icon: Icons.access_time,
          label: '시간',
          value: _formatScheduleTime(schedule),
        ),
        if (schedule.description != null &&
            schedule.description!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.description,
            label: '설명',
            value: schedule.description!,
            isMultiline: true,
          ),
        ],
        if (schedule.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildTagsSection(context, schedule.tags.toList()),
        ],
        const SizedBox(height: 16),
        _InfoRow(
          icon: Icons.flag,
          label: '상태',
          value: _getStatusText(schedule.state),
          valueWidget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(schedule.state).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusText(schedule.state),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _getStatusColor(schedule.state),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (schedule.recurrenceRule != null) ...[
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.repeat,
            label: '반복',
            value: _parseRecurrenceRule(schedule.recurrenceRule!),
          ),
        ],
        const SizedBox(height: 16),
        _InfoRow(
          icon: Icons.schedule,
          label: '생성',
          value: _dateFormat.format(schedule.createdAt.toLocal()),
        ),
      ],
    );
  }

  Widget _buildTimerSection(
    BuildContext context,
    WidgetRef ref,
    String scheduleId,
  ) {
    final timersAsync = ref.watch(scheduleTimersProvider(scheduleId));
    final theme = Theme.of(context);

    return timersAsync.when(
      data: (timers) {
        if (timers.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  '타이머',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${timers.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...timers.map((timer) => _buildTimerRow(context, timer)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildTimerRow(BuildContext context, TimerRead timer) {
    final theme = Theme.of(context);
    final statusColor = _getTimerStatusColor(timer.status);
    final statusText = _getTimerStatusText(timer.status);

    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 8),
      child: Row(
        children: [
          Icon(_getTimerStatusIcon(timer.status), size: 16, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              timer.title ?? '제목 없음',
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatDuration(Duration(seconds: timer.elapsedTime)),
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: theme.textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoConversionRow(
    BuildContext context,
    WidgetRef ref,
    ScheduleRead schedule,
    AsyncValue<void> mutations,
  ) {
    final hasLinkedTodo = schedule.sourceTodoId != null;

    if (hasLinkedTodo) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _navigateToLinkedTodo(context, schedule),
          icon: const Icon(Icons.link),
          label: const Text('연결된 TODO 보기'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonal(
        onPressed: mutations.isLoading
            ? null
            : () => _handleConvertToTodo(context, ref, schedule),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: mutations.isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.transform, size: 18),
                  SizedBox(width: 8),
                  Text('TODO로 변환'),
                ],
              ),
      ),
    );
  }

  /// tagGroupId가 없으면 사용자에게 선택하게 한 뒤 TODO로 변환
  Future<void> _handleConvertToTodo(
    BuildContext context,
    WidgetRef ref,
    ScheduleRead schedule,
  ) async {
    String? tagGroupId = schedule.tagGroupId;

    if (tagGroupId == null) {
      final selected = await Navigator.of(context).push<TagGroupRead>(
        MaterialPageRoute(builder: (_) => const TagGroupSelectorPage()),
      );
      if (selected == null || !context.mounted) return;
      tagGroupId = selected.id;
    }

    try {
      await ref
          .read(scheduleMutationsProvider.notifier)
          .convertToTodo(schedule.id, tagGroupId);

      if (context.mounted) {
        _showSnackBar(context, message: 'TODO로 변환되었습니다');
      }
    } catch (error) {
      if (context.mounted) {
        _showSnackBar(context, message: '변환에 실패했습니다: $error', isError: true);
      }
    }
  }

  void _navigateToLinkedTodo(BuildContext context, ScheduleRead schedule) {
    final tagGroupId = schedule.tagGroupId;
    if (tagGroupId != null) {
      context.go('${AppRoute.todo.path}/$tagGroupId');
    } else {
      context.go(AppRoute.todo.path);
    }
  }

  Widget _buildTagsSection(BuildContext context, List<TagRead> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.label, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              '태그',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) => _buildTagChip(context, tag)).toList(),
        ),
      ],
    );
  }

  Widget _buildTagChip(BuildContext context, TagRead tag) {
    final color = HexColor.fromHex(tag.color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        tag.name,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    ScheduleRead schedule,
    AsyncValue<void> mutations,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: mutations.isLoading
                ? null
                : () => _handleEdit(context, schedule),
            icon: const Icon(Icons.edit),
            label: const Text('수정'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: mutations.isLoading
                ? null
                : () => _handleDelete(context, ref, schedule),
            icon: mutations.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete),
            label: Text(mutations.isLoading ? '삭제 중...' : '삭제'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleEdit(BuildContext context, ScheduleRead schedule) {
    showScheduleEditSheet(context, schedule);
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    ScheduleRead schedule,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '일정 삭제',
      content: '"${schedule.title}" 일정을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
      confirmText: '삭제',
      destructive: true,
    );

    if (!confirmed) return;

    try {
      await ref
          .read(scheduleMutationsProvider.notifier)
          .deleteSchedule(schedule.id);

      if (context.mounted) {
        context.pop();
        _showSnackBar(context, message: '일정이 삭제되었습니다');
      }
    } catch (error) {
      if (context.mounted) {
        _showSnackBar(context, message: '삭제에 실패했습니다: $error', isError: true);
      }
    }
  }

  String _formatScheduleTime(ScheduleRead schedule) {
    final start = schedule.startTime.toLocal();
    final end = schedule.endTime.toLocal();

    if (_isAllDay(start, end)) {
      if (_isSameDay(start, end.subtract(const Duration(days: 1)))) {
        return '${_dateFormatFull.format(start)} 종일';
      } else {
        return '${_dateFormatShort.format(start)} ~ ${_dateFormatShort.format(end.subtract(const Duration(days: 1)))}';
      }
    }

    if (_isSameDay(start, end)) {
      return '${_dateFormatFull.format(start)}\n${_timeFormat.format(start)} ~ ${_timeFormat.format(end)}';
    } else {
      return '${_dateTimeFormat.format(start)} ~\n${_dateTimeFormat.format(end)}';
    }
  }

  bool _isAllDay(DateTime start, DateTime end) {
    return start.hour == 0 &&
        start.minute == 0 &&
        end.hour == 0 &&
        end.minute == 0 &&
        end.difference(start).inHours >= 24;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getStatusText(ScheduleState state) => switch (state) {
    ScheduleState.planned => '계획됨',
    ScheduleState.confirmed => '확정됨',
    ScheduleState.cancelled => '취소됨',
    ScheduleState.$unknown => state.toString(),
  };

  Color _getStatusColor(ScheduleState state) => switch (state) {
    ScheduleState.planned => Colors.orange,
    ScheduleState.confirmed => Colors.green,
    ScheduleState.cancelled => Colors.red,
    ScheduleState.$unknown => Colors.grey,
  };

  IconData _getTimerStatusIcon(TimerStatus status) => switch (status) {
    TimerStatus.notStarted => Icons.hourglass_empty,
    TimerStatus.running => Icons.play_arrow,
    TimerStatus.paused => Icons.pause,
    TimerStatus.completed => Icons.check_circle,
    TimerStatus.cancelled => Icons.cancel,
    TimerStatus.$unknown => Icons.timer,
  };

  Color _getTimerStatusColor(TimerStatus status) => switch (status) {
    TimerStatus.notStarted => Colors.blueGrey,
    TimerStatus.running => Colors.green,
    TimerStatus.paused => Colors.orange,
    TimerStatus.completed => Colors.blue,
    TimerStatus.cancelled => Colors.grey,
    TimerStatus.$unknown => Colors.grey,
  };

  /// RFC 5545 RRULE → 사람이 읽을 수 있는 한국어 텍스트.
  /// 예: "FREQ=WEEKLY;BYDAY=MO,WE" → "매주 (월, 수)"
  String _parseRecurrenceRule(String rule) {
    final upper = rule.toUpperCase();

    // FREQ 추출
    final freqMatch = RegExp(r'FREQ=(\w+)').firstMatch(upper);
    if (freqMatch == null) return rule;

    final freq = freqMatch.group(1);
    final interval =
        RegExp(r'INTERVAL=(\d+)').firstMatch(upper)?.group(1) ?? '1';
    final intervalNum = int.tryParse(interval) ?? 1;

    // BYDAY 추출 (주간 반복용)
    final byDay = RegExp(r'BYDAY=([A-Z,]+)').firstMatch(upper)?.group(1);

    String base;
    switch (freq) {
      case 'DAILY':
        base = intervalNum > 1 ? '$intervalNum일마다' : '매일';
        break;
      case 'WEEKLY':
        final days = byDay != null ? ' (${_translateDays(byDay)})' : '';
        base = intervalNum > 1 ? '$intervalNum주마다$days' : '매주$days';
        break;
      case 'MONTHLY':
        base = intervalNum > 1 ? '$intervalNum개월마다' : '매월';
        break;
      case 'YEARLY':
        base = intervalNum > 1 ? '$intervalNum년마다' : '매년';
        break;
      default:
        return rule;
    }

    return base;
  }

  String _translateDays(String byDay) {
    const dayMap = {
      'MO': '월',
      'TU': '화',
      'WE': '수',
      'TH': '목',
      'FR': '금',
      'SA': '토',
      'SU': '일',
    };
    return byDay.split(',').map((d) => dayMap[d.trim()] ?? d).join(', ');
  }

  String _getTimerStatusText(TimerStatus status) => switch (status) {
    TimerStatus.notStarted => '시작 전',
    TimerStatus.running => '진행중',
    TimerStatus.paused => '일시정지',
    TimerStatus.completed => '완료',
    TimerStatus.cancelled => '취소',
    TimerStatus.$unknown => '알 수 없음',
  };
  void _showSnackBar(
    BuildContext context, {
    required String message,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? valueWidget;
  final bool isMultiline;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueWidget,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isMultiline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child:
                valueWidget ?? Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: valueWidget ?? Text(value, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}
