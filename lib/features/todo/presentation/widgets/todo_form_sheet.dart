import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/network/explicit_null_interceptor.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/todo/presentation/utils/linked_schedule_policy_dialog.dart';
import 'package:momeet/shared/providers/tag_providers.dart' as tag_providers;
import 'package:momeet/features/tag/presentation/widgets/tag_form_sheet.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/shared/domain/tag_group_with_tags.dart';

/// 서버에 보낼 상태. UNSCHEDULED/SCHEDULED는 서버가 마감일 유무로 정하는 값이라
/// 보내지 않는다(보내서 실제와 다르면 422). 사용자가 고르는 상태는 완료·취소뿐이다.
@visibleForTesting
TodoStatus? todoStatusForRequest(TodoStatus selected) =>
    isActiveTodoStatus(selected) ? null : selected;

/// 완료·취소가 아닌 "진행 중" 상태인지 (미예정과 예정됨을 하나로 본다)
bool isActiveTodoStatus(TodoStatus status) =>
    status == TodoStatus.unscheduled || status == TodoStatus.scheduled;

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
    final theme = Theme.of(context);
    final isLoading = _isEditMode
        ? ref.watch(updateTodoMutation).isPending
        : ref.watch(createTodoMutation).isPending;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              _buildHeader(theme),

              const SizedBox(height: 24),

              // 할 일 제목 입력
              _buildTitleField(),

              const SizedBox(height: 20),

              // 설명 입력
              _buildDescriptionField(),

              const SizedBox(height: 20),

              // 상태 선택
              _buildStatusSelector(theme),

              const SizedBox(height: 20),

              // 마감일 선택
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

              const SizedBox(height: 24),

              // 태그 선택
              _buildTagSelector(theme),

              const SizedBox(height: 32),

              // 버튼 영역
              AppFormActionBar(
                submitLabel: _isEditMode ? '수정' : '생성',
                onSubmit: _handleSubmit,
                busy: isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 헤더 (제목과 핸들)
  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        // 제목
        Text(
          _isEditMode ? '할 일 수정' : '새 할 일 만들기',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 할 일 제목 입력 필드
  Widget _buildTitleField() {
    return TextFormField(
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
    );
  }

  /// 설명 입력 필드
  Widget _buildDescriptionField() {
    return TextFormField(
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
    );
  }

  /// 상태 선택기
  Widget _buildStatusSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader('상태'),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            // 미예정·예정됨은 서버가 마감일로 정하므로 "진행 중" 하나로 보여 준다
            children:
                const [
                  TodoStatus.unscheduled,
                  TodoStatus.done,
                  TodoStatus.cancelled,
                ].map((status) {
                  final isSelected = status == TodoStatus.unscheduled
                      ? isActiveTodoStatus(_selectedStatus)
                      : _selectedStatus == status;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_getStatusLabel(status)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedStatus = status;
                          });
                        }
                      },
                      avatar: Icon(
                        _getStatusIcon(status),
                        size: 18,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : _getStatusColor(status),
                      ),
                      selectedColor: _getStatusColor(status),
                      checkmarkColor: theme.colorScheme.onPrimary,
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  /// 태그 선택기
  Widget _buildTagSelector(ThemeData theme) {
    final tagTreeAsync = ref.watch(tag_providers.tagTreeProvider);

    return tagTreeAsync.when(
      data: (tagGroups) {
        // 생성 모드에서 tagGroupId가 비어있다면 첫 번째 그룹을 기본값으로 설정
        if (!_isEditMode &&
            _selectedTagGroupId.isEmpty &&
            tagGroups.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedTagGroupId = tagGroups.first.group.id;
            });
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 태그 섹션 헤더 (제목 + 새 태그 추가 버튼)
            AppSectionHeader(
              '태그',
              trailing: TextButton.icon(
                onPressed: () => _showCreateTagDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('새 태그'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 선택된 태그 그룹 표시 (생성 모드에서만)
            if (!_isEditMode && _selectedTagGroupId.isNotEmpty) ...[
              _buildSelectedTagGroup(theme, tagGroups),
              const SizedBox(height: 12),
            ],

            // 선택된 태그들 표시 (상단에 고정)
            if (_selectedTagIds.isNotEmpty) ...[
              _buildSelectedTags(theme, tagGroups),
              const SizedBox(height: 16),
            ],

            // 태그 그룹별로 태그 표시
            if (tagGroups.isNotEmpty)
              ...tagGroups.map(
                (tagGroup) => _buildTagGroupSection(theme, tagGroup),
              )
            else
              AppEmptyState(
                icon: Icons.label_outline,
                title: '아직 태그가 없습니다',
                message: '새 태그를 만들어 할 일을 분류해보세요',
                actionLabel: '첫 태그 만들기',
                onAction: () => _showCreateTagDialog(context),
              ),
          ],
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader('태그'),
          const SizedBox(height: 8),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      ),
      error: (error, stack) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            '태그',
            trailing: TextButton.icon(
              onPressed: () => _showCreateTagDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('새 태그'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '태그를 불러오지 못했습니다: $error',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 선택된 태그 그룹 표시 (생성 모드에서만)
  Widget _buildSelectedTagGroup(
    ThemeData theme,
    List<TagGroupWithTags> tagGroups,
  ) {
    // 현재 선택된 태그 그룹 찾기
    final selectedGroup = tagGroups.firstWhere(
      (group) => group.group.id == _selectedTagGroupId,
      orElse: () => tagGroups.isNotEmpty
          ? tagGroups.first
          : throw StateError('No tag groups available'),
    );

    final groupColor = HexColor.fromHex(selectedGroup.group.color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: groupColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: groupColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_rounded, size: 16, color: groupColor),
          const SizedBox(width: 6),
          Text(
            '${selectedGroup.group.name} 그룹',
            style: theme.textTheme.labelMedium?.copyWith(
              color: groupColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.lock_outline,
            size: 12,
            color: groupColor.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }

  /// 선택된 태그들을 상단에 표시
  Widget _buildSelectedTags(ThemeData theme, List<TagGroupWithTags> tagGroups) {
    // 선택된 태그들을 찾아서 표시
    final selectedTags = <TagRead>[];
    for (final group in tagGroups) {
      for (final tag in group.tags) {
        if (_selectedTagIds.contains(tag.id)) {
          selectedTags.add(tag);
        }
      }
    }

    if (selectedTags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '선택된 태그 (${selectedTags.length})',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: selectedTags.map((tag) {
            final tagColor = HexColor.fromHex(tag.color);

            return Chip(
              label: Text(tag.name),
              backgroundColor: tagColor.withValues(alpha: 0.2),
              side: BorderSide(color: tagColor, width: 1),
              deleteIcon: Icon(Icons.close, size: 16, color: tagColor),
              onDeleted: () {
                setState(() {
                  _selectedTagIds.remove(tag.id);
                });
              },
              labelStyle: TextStyle(
                color: tagColor,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 태그 그룹 섹션
  Widget _buildTagGroupSection(ThemeData theme, TagGroupWithTags tagGroup) {
    if (tagGroup.tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 그룹 헤더
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: HexColor.fromHex(tagGroup.group.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tagGroup.group.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // 이 그룹에 새 태그 추가 버튼
                TextButton.icon(
                  onPressed: () => _showCreateTagDialog(
                    context,
                    defaultGroupId: tagGroup.group.id,
                  ),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('추가'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    textStyle: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),

          // 태그 칩들
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...tagGroup.tags.map<Widget>((tag) {
                  final isSelected = _selectedTagIds.contains(tag.id);
                  final tagColor = HexColor.fromHex(tag.color);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(tag.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTagIds.add(tag.id);
                          } else {
                            _selectedTagIds.remove(tag.id);
                          }
                        });
                      },
                      selectedColor: tagColor.withValues(alpha: 0.2),
                      backgroundColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      checkmarkColor: tagColor,
                      side: BorderSide(
                        color: isSelected
                            ? tagColor
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                        width: isSelected ? 1.5 : 0.8,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? tagColor
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                }),

                // 이 그룹에 태그 추가하는 플러스 버튼
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: ActionChip(
                    avatar: Icon(
                      Icons.add,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(
                      '태그 추가',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: () => _showCreateTagDialog(
                      context,
                      defaultGroupId: tagGroup.group.id,
                    ),
                    backgroundColor: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Event Handlers
  // ============================================================

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('먼저 태그 그룹을 생성해주세요. 태그 관리 페이지에서 그룹을 만들 수 있습니다.'),
          duration: Duration(seconds: 3),
        ),
      );
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
    final theme = Theme.of(context);

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
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('기본 태그 그룹 생성에 실패했습니다: $error'),
              backgroundColor: Colors.red,
            ),
          );
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
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: theme.colorScheme.onPrimary),
                  const SizedBox(width: 12),
                  const Text('할 일이 수정되었습니다'),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
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
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: theme.colorScheme.onPrimary),
                  const SizedBox(width: 12),
                  const Text('할 일이 생성되었습니다'),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: theme.colorScheme.onError),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isEditMode
                        ? '할 일 수정에 실패했습니다: $error'
                        : '할 일 생성에 실패했습니다: $error',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ============================================================
  // Helper Methods
  // ============================================================

  String _getStatusLabel(TodoStatus status) {
    switch (status) {
      case TodoStatus.unscheduled:
      case TodoStatus.scheduled:
        return '진행 중';
      case TodoStatus.done:
        return '완료';
      case TodoStatus.cancelled:
        return '취소';
      case TodoStatus.$unknown:
        return '알 수 없음';
    }
  }

  IconData _getStatusIcon(TodoStatus status) {
    switch (status) {
      case TodoStatus.unscheduled:
        return Icons.radio_button_unchecked;
      case TodoStatus.scheduled:
        return Icons.schedule;
      case TodoStatus.done:
        return Icons.check_circle;
      case TodoStatus.cancelled:
        return Icons.cancel;
      case TodoStatus.$unknown:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(TodoStatus status) {
    final theme = Theme.of(context);
    switch (status) {
      case TodoStatus.unscheduled:
        return theme.colorScheme.onSurfaceVariant;
      case TodoStatus.scheduled:
        return theme.colorScheme.primary;
      case TodoStatus.done:
        return theme.colorScheme.tertiary;
      case TodoStatus.cancelled:
        return theme.colorScheme.error;
      case TodoStatus.$unknown:
        return theme.colorScheme.onSurfaceVariant;
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
