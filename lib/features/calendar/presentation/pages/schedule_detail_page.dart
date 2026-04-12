import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_detail_providers.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_mutations.dart';
import 'package:momeet/features/calendar/presentation/utils/schedule_formatters.dart';
import 'package:momeet/features/calendar/presentation/widgets/info_row.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_form_sheet.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_timer_section.dart';
import 'package:momeet/features/todo/presentation/pages/tag_group_selector_page.dart';
import 'package:momeet/shared/widgets/confirm_dialog.dart';

/// 캘린더에서 일정을 탭하면 이동하는 풀스크린 상세 페이지.
/// 일정 정보, 타이머 이력, TODO 변환, 수정/삭제 기능을 제공합니다.
class ScheduleDetailPage extends ConsumerWidget {
  static final _createdAtFormat = DateFormat('yyyy.MM.dd HH:mm');

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
          ScheduleTimerSection(scheduleId: schedule.id),
          const SizedBox(height: 16),
          _buildTodoConversionRow(context, ref, schedule, mutations),
          const SizedBox(height: 16),
          _buildActionButtons(context, ref, schedule, mutations),
        ],
      ),
    );
  }

  // ============================================================
  // 일정 정보 섹션
  // ============================================================

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
    final statusColor = getScheduleStatusColor(schedule.state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoRow(
          icon: Icons.access_time,
          label: '시간',
          value: formatScheduleTime(schedule),
        ),
        if (schedule.description != null &&
            schedule.description!.isNotEmpty) ...[
          const SizedBox(height: 16),
          InfoRow(
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
        InfoRow(
          icon: Icons.flag,
          label: '상태',
          value: getScheduleStatusText(schedule.state),
          valueWidget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              getScheduleStatusText(schedule.state),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (schedule.recurrenceRule != null) ...[
          const SizedBox(height: 16),
          InfoRow(
            icon: Icons.repeat,
            label: '반복',
            value: parseRecurrenceRule(schedule.recurrenceRule!),
          ),
        ],
        const SizedBox(height: 16),
        InfoRow(
          icon: Icons.schedule,
          label: '생성',
          value: _createdAtFormat.format(schedule.createdAt.toLocal()),
        ),
      ],
    );
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

  // ============================================================
  // TODO 변환 + 액션 버튼
  // ============================================================

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

  // ============================================================
  // 핸들러
  // ============================================================

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
      context.goNamed(
        AppRoute.todoGroupDetail.name,
        pathParameters: {'groupId': tagGroupId},
      );
    } else {
      context.go(AppRoute.todo.path);
    }
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
