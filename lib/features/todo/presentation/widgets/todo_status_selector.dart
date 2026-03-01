import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/rest/export.dart';
import '../providers/todo_provider.dart';

/// Todo 상태 선택 위젯
///
/// 4가지 상태(미예정, 예정됨, 완료, 취소)를 관리할 수 있는 커스텀 상태 컨트롤러입니다.
/// 사용자가 아이콘을 탭하면 상태 선택 팝업 메뉴가 표시됩니다.
class TodoStatusSelector extends ConsumerWidget {
  /// Todo 데이터
  final TodoRead todo;

  /// 아이콘 크기 (기본값: 24.0)
  final double iconSize;

  const TodoStatusSelector({
    super.key,
    required this.todo,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<TodoStatus>(
      initialValue: todo.status,
      onSelected: (TodoStatus newStatus) async {
        if (newStatus != todo.status) {
          await ref.read(todoMutationsProvider.notifier).changeStatus(
                todo.id,
                newStatus,
              );
        }
      },
      itemBuilder: (BuildContext context) {
        return TodoStatus.values
            .where((status) => status != TodoStatus.$unknown)
            .map((TodoStatus status) {
          return PopupMenuItem<TodoStatus>(
            value: status,
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(context, status),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(_getStatusLabel(status)),
              ],
            ),
          );
        }).toList();
      },
      child: Icon(
        _getStatusIcon(todo.status),
        color: _getStatusColor(context, todo.status),
        size: iconSize,
      ),
    );
  }

  /// 상태별 아이콘 반환
  IconData _getStatusIcon(TodoStatus status) {
    switch (status) {
      case TodoStatus.unscheduled:
        return Icons.circle_outlined; // 텅 빈 원
      case TodoStatus.scheduled:
        return Icons.schedule; // 일정 아이콘
      case TodoStatus.done:
        return Icons.check_circle; // 체크 아이콘 (rounded 제거하여 form과 일치)
      case TodoStatus.cancelled:
        return Icons.cancel; // 취소 아이콘
      case TodoStatus.$unknown:
        return Icons.help_outline; // 알 수 없음
    }
  }

  /// 상태별 색상 반환
  Color _getStatusColor(BuildContext context, TodoStatus status) {
    switch (status) {
      case TodoStatus.unscheduled:
        return Colors.grey; // 회색
      case TodoStatus.scheduled:
        return Colors.blue; // 파란색
      case TodoStatus.done:
        return Colors.green; // 녹색
      case TodoStatus.cancelled:
        return Colors.red; // 빨간색
      case TodoStatus.$unknown:
        return Colors.grey; // 회색
    }
  }

  /// 상태별 라벨 반환
  String _getStatusLabel(TodoStatus status) {
    switch (status) {
      case TodoStatus.unscheduled:
        return '미예정';
      case TodoStatus.scheduled:
        return '예정됨';
      case TodoStatus.done:
        return '완료';
      case TodoStatus.cancelled:
        return '취소';
      case TodoStatus.$unknown:
        return '알 수 없음';
    }
  }
}
