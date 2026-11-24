import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncValue;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/tag_group_with_tags.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form/todo_form_status_chips.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form/todo_group_field_view.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form/todo_tag_picker_view.dart';
import 'package:momeet/features/todo/presentation/utils/todo_form_values.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 할 일 생성/수정 폼 시트. 제목, 설명, 할 일 목록, 상태, 마감일, 태그를 편집한다.
///
/// [todo]가 있으면 그 값으로 채운 수정 폼이다. 칸을 모두 검사한 뒤 고른 값으로 [onSubmit]을 부르고,
/// [busy]인 동안은 버튼에 진행 표시를 둔다.
class TodoFormSheetView extends StatefulWidget {
  const TodoFormSheetView({
    super.key,
    this.todo,
    this.defaultTodoGroupId,
    this.groupLocked = false,
    required this.todoGroups,
    required this.tagGroups,
    required this.busy,
    required this.onSubmit,
    required this.onCreateTag,
  });

  /// 수정할 Todo (null인 경우 생성 모드)
  final TodoRead? todo;

  /// 새 할 일의 할 일 그룹 칸에 미리 고를 그룹 ID. 없으면 기본 그룹을 보인다
  final String? defaultTodoGroupId;

  /// 할 일 그룹 칸을 바꿀 수 없게 한다(하위 할 일은 상위 할 일의 그룹을 따른다)
  final bool groupLocked;

  final AsyncValue<List<TodoGroupRead>> todoGroups;
  final AsyncValue<List<TagGroupWithTags>> tagGroups;
  final bool busy;
  final ValueChanged<TodoFormValues> onSubmit;

  /// 새 태그를 만든다. 태그 그룹 줄에서 누르면 그 그룹 id, 아니면 null
  final ValueChanged<String?> onCreateTag;

  @override
  State<TodoFormSheetView> createState() => _TodoFormSheetViewState();
}

class _TodoFormSheetViewState extends State<TodoFormSheetView> {
  final _formKey = GlobalKey<FormState>();
  late final _isEditMode = widget.todo != null;
  late final _titleController = TextEditingController(text: widget.todo?.title);
  late final _descriptionController = TextEditingController(
    text: widget.todo?.description,
  );
  late var _selectedStatus = widget.todo?.status ?? TodoStatus.unscheduled;
  late final _selectedTagIds = {...?widget.todo?.tags.map((tag) => tag.id)};
  late var _selectedDeadline = widget.todo?.deadline;
  late var _selectedGroupId =
      widget.todo?.todoGroupId ?? widget.defaultTodoGroupId;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: _isEditMode ? '${Terms.todo} 수정' : '새 ${Terms.todo} 만들기',
      formKey: _formKey,
      actions: AppFormActionBar(
        submitLabel: _isEditMode ? '수정' : '생성',
        onSubmit: _submit,
        busy: widget.busy,
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
        TodoGroupFieldView(
          groups: widget.todoGroups,
          selectedId: _selectedGroupId,
          onChanged: (id) => setState(() => _selectedGroupId = id),
          locked: widget.groupLocked,
          pickerContent: _isEditMode ? todoGroupMoveNote(widget.todo!) : null,
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
        TodoTagPickerView(
          tagGroups: widget.tagGroups,
          selectedTagIds: _selectedTagIds,
          onToggle: _toggleTag,
          onCreateTag: widget.onCreateTag,
        ),
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

  /// 칸을 검사하고 고른 값을 넘긴다
  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    widget.onSubmit((
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _selectedStatus,
      tagIds: _selectedTagIds.toList(),
      deadline: _selectedDeadline,
      todoGroupId: _selectedGroupId,
    ));
  }
}
