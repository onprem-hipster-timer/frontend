import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_detail_providers.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_mutations.dart';
import 'package:momeet/features/calendar/presentation/utils/linked_todo_navigation.dart';
import 'package:momeet/features/calendar/presentation/utils/source_todo_policy_dialog.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_detail_body.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_form_sheet.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_timer_section.dart';
import 'package:momeet/features/timer/presentation/utils/linked_timer_policy_dialog.dart';
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
enum _PendingAction { convert, openLinked, delete }

class _ScheduleDetailPageState extends ConsumerState<ScheduleDetailPage> {
  _PendingAction? _pendingAction;

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(scheduleDetailProvider(widget.scheduleId));
    final isBusy =
        ref.watch(deleteScheduleMutation).isPending ||
        ref.watch(convertToTodoMutation).isPending ||
        _pendingAction != null;

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
          child: ScheduleDetailBody(
            schedule: schedule,
            timerSection: ScheduleTimerSection(scheduleId: schedule.id),
            converting:
                _pendingAction == _PendingAction.convert ||
                _pendingAction == _PendingAction.openLinked,
            deleting: _pendingAction == _PendingAction.delete,
            onOpenLinked: isBusy
                ? null
                : () => _navigateToLinkedTodo(context, schedule.sourceTodoId!),
            onConvert: isBusy
                ? null
                : () => _handleConvertToTodo(context, ref, schedule),
            onEdit: isBusy
                ? null
                : () => showScheduleEditSheet(context, schedule),
            onDelete: isBusy
                ? null
                : () => _handleDelete(context, ref, schedule),
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

  /// 일정을 할 일로 바꾼다. 할 일은 기본 할 일 그룹에 들어간다.
  /// 바꾸면 '할 일 보기'(바꾼 할 일이 있는 할 일 그룹으로 이동)가 있는 알림을 띄운다
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
        // 알림이 떠 있는 사이 상세 화면을 떠나도 이동할 수 있게 라우터와 컨테이너를 잡아 둔다
        final router = GoRouter.of(context);
        final container = ProviderScope.containerOf(context, listen: false);
        showAppSnackBar(
          context,
          '${Terms.todo.withJosa('으로', '로')} 변환되었습니다',
          kind: AppNoticeKind.success,
          actionLabel: '${Terms.todo} 보기',
          onAction: () => goToTodoOfSchedule(container, router, schedule.id),
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
    setState(() => _pendingAction = _PendingAction.openLinked);
    final groupId = await todoGroupIdOf(
      ProviderScope.containerOf(context, listen: false),
      todoId,
    );
    if (mounted) setState(() => _pendingAction = null);
    if (!context.mounted) return;
    goToTodoGroup(GoRouter.of(context), groupId);
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
