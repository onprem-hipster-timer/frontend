import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_detail_info.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 일정 상세의 본문: 제목, 정보, 타이머 이력([timerSection]), 할 일 변환, 수정·삭제.
/// 일정 상세 화면과 체험하기 흐름이 함께 쓰려고 공개한다.
///
/// 할 일과 이어졌으면(`sourceTodoId`) '연결된 할 일 보기'를, 아니면 '할 일로 변환'을 둔다.
/// 콜백이 null이면 다른 작업이 진행 중이라 누를 수 없다.
class ScheduleDetailBody extends StatelessWidget {
  const ScheduleDetailBody({
    super.key,
    required this.schedule,
    required this.timerSection,
    this.converting = false,
    this.deleting = false,
    required this.onOpenLinked,
    required this.onConvert,
    required this.onEdit,
    required this.onDelete,
  });

  final ScheduleRead schedule;

  /// 일정에 연결된 타이머 목록 자리
  final Widget timerSection;

  /// 할 일로 바꾸는 중이거나 연결된 할 일을 받는 중이다
  final bool converting;
  final bool deleting;
  final VoidCallback? onOpenLinked;
  final VoidCallback? onConvert;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScheduleTitle(title: schedule.title),
        const SizedBox(height: 24),
        ScheduleDetailInfo(schedule: schedule),
        const SizedBox(height: 16),
        timerSection,
        const SizedBox(height: 16),
        _TodoConversionButton(
          linked: schedule.sourceTodoId != null,
          busy: converting,
          onOpenLinked: onOpenLinked,
          onConvert: onConvert,
        ),
        const SizedBox(height: 16),
        _EditDeleteButtons(
          deleting: deleting,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ],
    );
  }
}

/// 일정을 할 일로 바꾼 뒤의 알림. '할 일 보기'를 누르면 [onShowTodo]를 부른다.
/// 일정 상세 화면과 체험하기 흐름이 같은 알림을 띄우려고 공개한다.
void showTodoConvertedNotice(
  BuildContext context, {
  required VoidCallback onShowTodo,
}) => showAppSnackBar(
  context,
  '${Terms.todo.withJosa('으로', '로')} 변환되었습니다',
  kind: AppNoticeKind.success,
  actionLabel: '${Terms.todo} 보기',
  onAction: onShowTodo,
);

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
    required this.busy,
    required this.onOpenLinked,
    required this.onConvert,
  });

  final bool linked;

  /// 할 일로 바꾸는 중이거나 연결된 할 일을 받는 중이다
  final bool busy;

  /// null이면 다른 작업이 진행 중이라 누를 수 없다
  final VoidCallback? onOpenLinked;

  /// null이면 다른 작업이 진행 중이라 누를 수 없다
  final VoidCallback? onConvert;

  @override
  Widget build(BuildContext context) {
    if (linked) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onOpenLinked,
          icon: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.link),
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
        child: busy
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
