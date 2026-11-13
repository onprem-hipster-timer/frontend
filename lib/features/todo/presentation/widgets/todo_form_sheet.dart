import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form/todo_form_status_chips.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form/todo_tag_picker.dart';
import 'package:momeet/features/todo/presentation/utils/todo_form_submit.dart';
import 'package:momeet/shared/domain/terms.dart';

/// Todo 생성/수정 폼 시트
///
/// Modal Bottom Sheet로 표시되며, Todo의 제목, 설명, 태그, 상태를 편집할 수 있습니다.
class TodoFormSheet extends ConsumerStatefulWidget {
  /// 수정할 Todo (null인 경우 생성 모드)
  final TodoRead? todo;

  /// 기본 상위 Todo ID (생성 시 사용)
  final String? defaultParentId;

  /// 새 할 일이 들어갈 할 일 그룹 ID. 없으면 서버가 기본 그룹에 넣는다
  final String? defaultTodoGroupId;

  const TodoFormSheet({
    super.key,
    this.todo,
    this.defaultParentId,
    this.defaultTodoGroupId,
  });

  @override
  ConsumerState<TodoFormSheet> createState() => _TodoFormSheetState();
}

class _TodoFormSheetState extends ConsumerState<TodoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _isEditMode = widget.todo != null;
  late final _titleController = TextEditingController(text: widget.todo?.title);
  late final _descriptionController = TextEditingController(
    text: widget.todo?.description,
  );
  late var _selectedStatus = widget.todo?.status ?? TodoStatus.unscheduled;
  late final _selectedTagIds = {...?widget.todo?.tags.map((tag) => tag.id)};
  late var _selectedDeadline = widget.todo?.deadline;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isEditMode
        ? ref.watch(updateTodoMutation).isPending
        : ref.watch(createTodoMutation).isPending;

    return AppFormSheet(
      title: _isEditMode ? '${Terms.todo} 수정' : '새 ${Terms.todo} 만들기',
      formKey: _formKey,
      actions: AppFormActionBar(
        submitLabel: _isEditMode ? '수정' : '생성',
        onSubmit: _handleSubmit,
        busy: isLoading,
      ),
      children: [
        TextFormField(
          controller: _titleController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: '${Terms.todo} 제목',
            hintText: '${Terms.todo.withJosa('을', '를')} 입력하세요',
            hintMaxLines: 2,
            prefixIcon: const Icon(Icons.task_alt),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '${Terms.todo} 제목을 입력해주세요';
            }
            if (value.trim().length > 200) {
              return '제목은 200자 이하로 입력해주세요';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            label: Text('설명 (선택사항)', maxLines: 2),
            hintText: '상세 설명을 입력하세요',
            prefixIcon: Icon(Icons.notes),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          validator: (value) {
            if (value != null && value.length > 500) {
              return '설명은 500자 이하로 입력해주세요';
            }
            return null;
          },
          textInputAction: TextInputAction.done,
        ),
        TodoFormStatusChips(
          selected: _selectedStatus,
          onChanged: (status) => setState(() => _selectedStatus = status),
        ),
        AppPickerField(
          label: '마감일',
          icon: Icons.calendar_today,
          value: _selectedDeadline == null
              ? null
              : '${_selectedDeadline!.year}년 ${_selectedDeadline!.month}월 ${_selectedDeadline!.day}일',
          placeholder: '선택 안 함',
          onTap: () async {
            final picked = await pickTodoDeadline(context, _selectedDeadline);
            if (picked != null) setState(() => _selectedDeadline = picked);
          },
          onClear: () => setState(() => _selectedDeadline = null),
        ),
        TodoTagPicker(selectedTagIds: _selectedTagIds, onToggle: _toggleTag),
      ],
    );
  }

  void _toggleTag(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedTagIds.add(id);
      } else {
        _selectedTagIds.remove(id);
      }
    });
  }

  /// 마감일 선택

  /// 폼 제출 처리
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final values = (
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _selectedStatus,
      tagIds: _selectedTagIds.toList(),
      deadline: _selectedDeadline,
    );
    try {
      if (_isEditMode) {
        if (!mounted) return;
        final sent = await updateTodoFromForm(
          context,
          ref,
          widget.todo!,
          values,
        );
        if (!sent) return;
      } else {
        await createTodoFromForm(
          ref,
          values,
          todoGroupId: widget.defaultTodoGroupId,
          parentId: widget.defaultParentId,
        );
      }
      if (mounted) {
        navigator.pop();
        scaffoldMessenger.showAppSnackBar(
          _isEditMode
              ? '${Terms.todo.withJosa('이', '가')} 수정되었습니다'
              : '${Terms.todo.withJosa('이', '가')} 생성되었습니다',
          kind: AppNoticeKind.success,
        );
      }
    } catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          _isEditMode
              ? '${Terms.todo} 수정에 실패했습니다: $error'
              : '${Terms.todo} 생성에 실패했습니다: $error',
          kind: AppNoticeKind.error,
        );
      }
    }
  }
}

/// Todo 폼 시트를 표시하는 헬퍼 함수
///
/// 사용 예:
/// ```dart
/// showTodoFormSheet(
///   context,
///   defaultTodoGroupId: groupId,
/// );
/// ```
Future<void> showTodoFormSheet(
  BuildContext context, {
  TodoRead? todo,
  String? defaultParentId,
  String? defaultTodoGroupId,
}) {
  return showAppSheet<void>(
    context,
    builder: (context) => TodoFormSheet(
      todo: todo,
      defaultParentId: defaultParentId,
      defaultTodoGroupId: defaultTodoGroupId,
    ),
  );
}
