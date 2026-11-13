import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_detail_providers.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_mutations.dart';
import 'package:momeet/features/calendar/presentation/utils/source_todo_policy_dialog.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_detail_info.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_form_sheet.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_timer_section.dart';
import 'package:momeet/features/timer/presentation/utils/linked_timer_policy_dialog.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 캘린더에서 일정을 탭하면 이동하는 풀스크린 상세 페이지.
/// 일정 정보, 타이머 이력, TODO 변환, 수정/삭제 기능을 제공합니다.
class ScheduleDetailPage extends ConsumerStatefulWidget {
  final String scheduleId;

  const ScheduleDetailPage({super.key, required this.scheduleId});

  @override
  ConsumerState<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

/// 상세 페이지에서 진행 중인 mutation 종류 — 버튼별 로딩 표시를 구분하기 위함.
enum _PendingAction { convert, delete }

class _ScheduleDetailPageState extends ConsumerState<ScheduleDetailPage> {
  _PendingAction? _pendingAction;

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(scheduleDetailProvider(widget.scheduleId));
    final isMutating =
        ref.watch(deleteScheduleMutation).isPending ||
        ref.watch(convertToTodoMutation).isPending;

    return Scaffold(
      appBar: AppBar(
        title: const Text('일정 상세'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: scheduleAsync.when(
        data: (schedule) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ScheduleTitle(title: schedule.title),
              const SizedBox(height: 24),
              ScheduleDetailInfo(schedule: schedule),
              const SizedBox(height: 16),
              ScheduleTimerSection(scheduleId: schedule.id),
              const SizedBox(height: 16),
              _TodoConversionButton(
                linked: schedule.sourceTodoId != null,
                converting: _pendingAction == _PendingAction.convert,
                onOpenLinked: () =>
                    _navigateToLinkedTodo(context, schedule.sourceTodoId!),
                onConvert: isMutating
                    ? null
                    : () => _handleConvertToTodo(context, ref, schedule),
              ),
              const SizedBox(height: 16),
              _EditDeleteButtons(
                deleting: _pendingAction == _PendingAction.delete,
                onEdit: isMutating
                    ? null
                    : () => showScheduleEditSheet(context, schedule),
                onDelete: isMutating
                    ? null
                    : () => _handleDelete(context, ref, schedule),
              ),
            ],
          ),
        ),
        loading: () => const AppLoading(),
        error: (error, stack) => AppErrorState(
          title: '일정을 불러올 수 없습니다',
          onRetry: () =>
              ref.invalidate(scheduleDetailProvider(widget.scheduleId)),
        ),
      ),
    );
  }

  /// 일정을 할 일로 바꾼다. 할 일은 기본 할 일 그룹에 들어간다
  Future<void> _handleConvertToTodo(
    BuildContext context,
    WidgetRef ref,
    ScheduleRead schedule,
  ) async {
    setState(() => _pendingAction = _PendingAction.convert);
    try {
      await convertToTodoMutation.run(
        ref,
        (tsx) => tsx
            .get(scheduleMutationsProvider.notifier)
            .convertToTodo(schedule.id),
      );

      if (context.mounted) {
        showAppSnackBar(
          context,
          '${Terms.todo.withJosa('으로', '로')} 변환되었습니다',
          kind: AppNoticeKind.success,
        );
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          '변환에 실패했습니다: $error',
          kind: AppNoticeKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _pendingAction = null);
    }
  }

  /// 연결된 할 일이 있는 할 일 그룹으로 간다. 할 일을 받지 못하면 할 일 탭으로 간다
  Future<void> _navigateToLinkedTodo(
    BuildContext context,
    String todoId,
  ) async {
    final provider = todoByIdProvider(todoId);
    // 받는 동안 autoDispose 프로바이더를 붙잡아 둔다
    final keepAlive = ref.listenManual(provider, (_, _) {});
    String? groupId;
    try {
      groupId = (await ref.read(provider.future)).todoGroupId;
    } catch (_) {
      groupId = null;
    } finally {
      keepAlive.close();
    }
    if (!context.mounted) return;
    if (groupId == null) {
      context.goNamed(AppRoute.todo.name);
    } else {
      context.goNamed(
        AppRoute.todoGroupDetail.name,
        pathParameters: {'groupId': groupId},
      );
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    ScheduleRead schedule,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: '일정 삭제',
      content: '"${schedule.title}" 일정을 삭제하시겠습니까?\n되돌릴 수 없습니다.',
      confirmText: '삭제',
      destructive: true,
    );

    if (!confirmed || !context.mounted) return;

    // 할 일 마감일에서 만들어진 일정이면 원본 할 일 처리를 사용자가 정해야 한다
    SourceTodoPolicy? sourceTodoPolicy;
    if (schedule.sourceTodoId != null) {
      sourceTodoPolicy = await showSourceTodoPolicyDialog(
        context,
        scheduleTitle: schedule.title,
      );
      if (sourceTodoPolicy == null || !context.mounted) return;
    }

    setState(() => _pendingAction = _PendingAction.delete);
    try {
      final deleted = await deleteAskingLinkedTimerPolicy(
        context,
        itemTitle: schedule.title,
        delete: (linkedTimerPolicy) => deleteScheduleMutation.run(
          ref,
          (tsx) => tsx
              .get(scheduleMutationsProvider.notifier)
              .deleteSchedule(
                schedule.id,
                sourceTodoPolicy: sourceTodoPolicy,
                linkedTimerPolicy: linkedTimerPolicy,
              ),
        ),
      );

      if (deleted && context.mounted) {
        context.pop();
        showAppSnackBar(context, '일정이 삭제되었습니다', kind: AppNoticeKind.success);
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          '삭제에 실패했습니다: $error',
          kind: AppNoticeKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _pendingAction = null);
    }
  }
}

/// 상세 화면의 넓은 버튼 공통 모양
final _actionButtonStyle = ButtonStyle(
  padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 12)),
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
  ),
);

/// 일정 제목 줄
class _ScheduleTitle extends StatelessWidget {
  const _ScheduleTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(Icons.event, color: theme.colorScheme.primary, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// 할 일과 이어졌으면 그 할 일로 가고, 아니면 할 일로 바꾼다
class _TodoConversionButton extends StatelessWidget {
  const _TodoConversionButton({
    required this.linked,
    required this.converting,
    required this.onOpenLinked,
    required this.onConvert,
  });

  final bool linked;
  final bool converting;
  final VoidCallback onOpenLinked;

  /// null이면 다른 작업이 진행 중이라 누를 수 없다
  final VoidCallback? onConvert;

  @override
  Widget build(BuildContext context) {
    if (linked) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onOpenLinked,
          icon: const Icon(Icons.link),
          label: const Text('연결된 ${Terms.todo} 보기'),
          style: _actionButtonStyle,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonal(
        onPressed: onConvert,
        style: _actionButtonStyle,
        child: converting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.transform, size: 18),
                  const SizedBox(width: 8),
                  Text('${Terms.todo.withJosa('으로', '로')} 변환'),
                ],
              ),
      ),
    );
  }
}

/// 수정·삭제 버튼 줄. 콜백이 null이면 누를 수 없다
class _EditDeleteButtons extends StatelessWidget {
  const _EditDeleteButtons({
    required this.deleting,
    required this.onEdit,
    required this.onDelete,
  });

  final bool deleting;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
            label: const Text('수정'),
            style: _actionButtonStyle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: onDelete,
            icon: deleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete),
            label: Text(deleting ? '삭제 중...' : '삭제'),
            style: _actionButtonStyle.copyWith(
              backgroundColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.error,
              ),
              foregroundColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.onError,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
