import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/network/explicit_null_interceptor.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/todo/presentation/utils/linked_schedule_policy_dialog.dart';
import 'package:momeet/shared/providers/tag_providers.dart' as tag_providers;
import 'package:momeet/features/tag/presentation/widgets/tag_form_sheet.dart';
import 'package:momeet/shared/domain/tag_group_with_tags.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form/todo_form_status_chips.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form/todo_tag_picker.dart';

/// 서버에 보낼 상태. UNSCHEDULED/SCHEDULED는 서버가 마감일 유무로 정하는 값이라
/// 보내지 않는다(보내서 실제와 다르면 422). 사용자가 고르는 상태는 완료·취소뿐이다.
@visibleForTesting
TodoStatus? todoStatusForRequest(TodoStatus selected) =>
    isActiveTodoStatus(selected) ? null : selected;

/// Todo 생성/수정 폼 시트
///
/// Modal Bottom Sheet로 표시되며, Todo의 제목, 설명, 태그, 상태를 편집할 수 있습니다.
class TodoFormSheet extends ConsumerStatefulWidget {
  /// 수정할 Todo (null인 경우 생성 모드)
  final TodoRead? todo;

  /// 기본 상위 Todo ID (생성 시 사용)
  final String? defaultParentId;

  /// 기본 태그 그룹 ID (생성 시 사용)
  final String? defaultTagGroupId;

  const TodoFormSheet({
    super.key,
    this.todo,
    this.defaultParentId,
    this.defaultTagGroupId,
  });

  @override
  ConsumerState<TodoFormSheet> createState() => _TodoFormSheetState();
}

class _TodoFormSheetState extends ConsumerState<TodoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late TodoStatus _selectedStatus;
  late String _selectedTagGroupId;
  final Set<String> _selectedTagIds = {};
  DateTime? _selectedDeadline;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();

    _isEditMode = widget.todo != null;

    if (_isEditMode) {
      // 수정 모드: 기존 데이터로 초기화
      final todo = widget.todo!;
      _titleController.text = todo.title;
      _descriptionController.text = todo.description ?? '';
      _selectedStatus = todo.status;
      _selectedTagGroupId = todo.tagGroupId;
      _selectedTagIds.addAll(todo.tags.map((tag) => tag.id));
      _selectedDeadline = todo.deadline;
    } else {
      // 생성 모드: 기본값으로 초기화
      _selectedStatus = TodoStatus.unscheduled;
      _selectedTagGroupId = widget.defaultTagGroupId ?? '';
    }
  }

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
      title: _isEditMode ? '할 일 수정' : '새 할 일 만들기',
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
          decoration: const InputDecoration(
            labelText: '할 일 제목',
            hintText: '할 일을 입력하세요',
            prefixIcon: Icon(Icons.task_alt),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '할 일 제목을 입력해주세요';
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
            labelText: '설명 (선택사항)',
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
          onTap: () => _selectDeadline(context),
          onClear: () => setState(() => _selectedDeadline = null),
        ),
        TodoTagPicker(
          lockedGroupId: _isEditMode || _selectedTagGroupId.isEmpty
              ? null
              : _selectedTagGroupId,
          selectedTagIds: _selectedTagIds,
          onToggle: _toggleTag,
          onCreateTag: ({groupId}) =>
              _showCreateTagDialog(context, defaultGroupId: groupId),
          onFirstGroup: _isEditMode || _selectedTagGroupId.isNotEmpty
              ? null
              : _useFirstGroup,
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

  /// 새 할 일의 그룹을 정하지 않았으면 첫 그룹으로 한다
  void _useFirstGroup(String groupId) {
    if (mounted) setState(() => _selectedTagGroupId = groupId);
  }

  /// 마감일 선택
  Future<void> _selectDeadline(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  /// 새 태그 생성 다이얼로그 표시
  Future<void> _showCreateTagDialog(
    BuildContext context, {
    String? defaultGroupId,
  }) async {
    // Provider에서 태그 그룹 데이터 가져오기
    final tagGroupsAsync = ref.read(tag_providers.tagTreeProvider);
    final availableGroups = tagGroupsAsync.when(
      data: (groups) => groups,
      loading: () => <TagGroupWithTags>[],
      error: (_, _) => <TagGroupWithTags>[],
    );

    if (availableGroups.isEmpty) {
      // 태그 그룹이 없는 경우 안내
      showAppSnackBar(context, '먼저 태그 그룹을 생성해주세요. 태그 관리 페이지에서 그룹을 만들 수 있습니다.');
      return;
    }

    // 태그 생성 폼 시트 표시
    await showTagFormSheet(
      context,
      defaultGroupId:
          defaultGroupId ??
          (availableGroups.isNotEmpty ? availableGroups.first.group.id : null),
    );

    // 태그 생성 후 상태 새로고침
    if (mounted) {
      // TagTree Provider를 새로고침하여 새로 생성된 태그 반영
      ref.invalidate(tag_providers.tagTreeProvider);
    }
  }

  /// 폼 제출 처리
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 생성 모드에서 tagGroupId 검증 및 기본 그룹 생성
    if (!_isEditMode) {
      // 태그 그룹 데이터 확인
      final tagTreeAsync = ref.read(tag_providers.tagTreeProvider);
      var tagGroups = tagTreeAsync.when(
        data: (groups) => groups,
        loading: () => <TagGroupWithTags>[],
        error: (_, _) => <TagGroupWithTags>[],
      );

      // 태그 그룹이 없으면 기본 그룹 생성
      if (tagGroups.isEmpty) {
        try {
          final defaultGroup = const TagGroupCreate(
            name: '기본 그룹',
            color: '#2196F3', // 파란색
            description: '할 일을 위한 기본 태그 그룹입니다.',
          );

          await tag_providers.createTagGroupMutation.run(
            ref,
            (tsx) => tsx
                .get(tag_providers.tagGroupsRawProvider.notifier)
                .createGroup(defaultGroup),
          );

          // 생성 후 다시 태그 그룹 데이터 가져오기
          final updatedAsync = await ref.refresh(
            tag_providers.tagTreeProvider.future,
          );
          tagGroups = updatedAsync;

          if (tagGroups.isNotEmpty) {
            _selectedTagGroupId = tagGroups.first.group.id;
          }
        } catch (error) {
          if (mounted) {
            showAppSnackBar(
              context,
              '기본 태그 그룹 생성에 실패했습니다: $error',
              kind: AppNoticeKind.error,
            );
          }
          return;
        }
      } else {
        // 선택된 그룹 ID가 비어있거나 유효하지 않은 경우
        if (_selectedTagGroupId.isEmpty ||
            !tagGroups.any((group) => group.group.id == _selectedTagGroupId)) {
          // 첫 번째 유효한 그룹으로 설정
          _selectedTagGroupId = tagGroups.first.group.id;
        }
      }
    }

    try {
      if (_isEditMode) {
        // 수정 모드
        final description = _descriptionController.text.trim();
        final removesDeadline =
            widget.todo!.deadline != null && _selectedDeadline == null;

        // 마감일을 지우면 연결된 캘린더 일정 처리를 사용자가 정해야 한다
        // (SCHEDULED = 연결 일정이 있다는 서버 표시)
        LinkedSchedulePolicy? linkedSchedulePolicy;
        if (removesDeadline &&
            widget.todo!.status == TodoStatus.scheduled &&
            mounted) {
          linkedSchedulePolicy = await showLinkedSchedulePolicyDialog(
            context,
            todoTitle: widget.todo!.title,
          );
          if (linkedSchedulePolicy == null) return;
        }

        final updateData = TodoUpdate(
          title: _titleController.text.trim(),
          description: description.isEmpty ? null : description,
          status: todoStatusForRequest(_selectedStatus),
          tagIds: _selectedTagIds.toList(),
          deadline: _selectedDeadline,
          linkedSchedulePolicy: linkedSchedulePolicy,
        );
        final nullFields = [
          if (description.isEmpty) 'description',
          if (removesDeadline) 'deadline',
        ];

        await updateTodoMutation.run(
          ref,
          (tsx) => tsx
              .get(todoMutationsProvider.notifier)
              .update(
                widget.todo!.id,
                updateData,
                options: nullFields.isEmpty ? null : explicitNulls(nullFields),
              ),
        );

        if (mounted) {
          navigator.pop();
          scaffoldMessenger.showAppSnackBar(
            '할 일이 수정되었습니다',
            kind: AppNoticeKind.success,
          );
        }
      } else {
        // 생성 모드
        final createData = TodoCreate(
          title: _titleController.text.trim(),
          tagGroupId: _selectedTagGroupId,
          status: todoStatusForRequest(_selectedStatus),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          tagIds: _selectedTagIds.toList(),
          deadline: _selectedDeadline,
          parentId: widget.defaultParentId,
        );

        await createTodoMutation.run(
          ref,
          (tsx) => tsx.get(todoMutationsProvider.notifier).create(createData),
        );

        if (mounted) {
          navigator.pop();
          scaffoldMessenger.showAppSnackBar(
            '할 일이 생성되었습니다',
            kind: AppNoticeKind.success,
          );
        }
      }
    } catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          _isEditMode ? '할 일 수정에 실패했습니다: $error' : '할 일 생성에 실패했습니다: $error',
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
///   defaultTagGroupId: groupId,
/// );
/// ```
Future<void> showTodoFormSheet(
  BuildContext context, {
  TodoRead? todo,
  String? defaultParentId,
  String? defaultTagGroupId,
}) {
  return showAppSheet<void>(
    context,
    builder: (context) => TodoFormSheet(
      todo: todo,
      defaultParentId: defaultParentId,
      defaultTagGroupId: defaultTagGroupId,
    ),
  );
}
