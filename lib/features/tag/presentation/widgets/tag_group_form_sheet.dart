import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/export.dart';
import 'package:momeet/features/tag/presentation/providers/tag_providers.dart';
import 'package:momeet/features/tag/presentation/utils/color_utils.dart';

/// 태그 그룹 생성/수정 폼 시트
class TagGroupFormSheet extends ConsumerStatefulWidget {
  /// 수정할 태그 그룹 (null인 경우 생성 모드)
  final TagGroupReadWithTags? tagGroup;

  const TagGroupFormSheet({
    super.key,
    this.tagGroup,
  });

  @override
  ConsumerState<TagGroupFormSheet> createState() => _TagGroupFormSheetState();
}

class _TagGroupFormSheetState extends ConsumerState<TagGroupFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  late Color _selectedColor;
  bool _isTodoGroup = false;

  @override
  void initState() {
    super.initState();

    // 수정 모드인 경우 기존 값으로 초기화
    if (widget.tagGroup != null) {
      _nameController.text = widget.tagGroup!.name;
      _descriptionController.text = widget.tagGroup!.description ?? '';
      _selectedColor = ColorExt.fromHex(widget.tagGroup!.color);
      _isTodoGroup = widget.tagGroup!.isTodoGroup;
    } else {
      // 생성 모드인 경우 기본값 설정
      _selectedColor = TagColors.defaultColor;
      _isTodoGroup = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutations = ref.watch(tagMutationsProvider);
    final isLoading = mutations.isLoading;
    final isEditMode = widget.tagGroup != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                _buildHeader(theme, isEditMode),

                const SizedBox(height: 24),

                // 그룹 이름 입력
                _buildNameField(),

                const SizedBox(height: 20),

                // 설명 입력
                _buildDescriptionField(),

                const SizedBox(height: 24),

                // 색상 선택
                _buildColorPicker(theme),

                const SizedBox(height: 24),

                // Todo 그룹 여부
                _buildTodoGroupSwitch(theme),

                const SizedBox(height: 32),

                // 버튼 영역
                _buildButtonBar(isEditMode, isLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 헤더 (제목과 핸들)
  Widget _buildHeader(ThemeData theme, bool isEditMode) {
    return Column(
      children: [
        // 핸들
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        const SizedBox(height: 16),

        // 제목
        Text(
          isEditMode ? '태그 그룹 수정' : '새 태그 그룹 만들기',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 그룹 이름 입력 필드
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      autofocus: true,
      decoration: InputDecoration(
        labelText: '그룹 이름',
        hintText: '태그 그룹 이름을 입력하세요',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: _selectedColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '그룹 이름을 입력해주세요';
        }
        if (value.trim().length > 50) {
          return '그룹 이름은 50자 이하로 입력해주세요';
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
      decoration: InputDecoration(
        labelText: '설명 (선택사항)',
        hintText: '그룹에 대한 간단한 설명을 입력하세요',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.notes),
        alignLabelWithHint: true,
      ),
      maxLines: 3,
      validator: (value) {
        if (value != null && value.length > 200) {
          return '설명은 200자 이하로 입력해주세요';
        }
        return null;
      },
      textInputAction: TextInputAction.done,
    );
  }

  /// 색상 선택기
  Widget _buildColorPicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '색상 선택',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        // 색상 팔레트 그리드
        Wrap(
          spacing: 12,
          runSpacing: 12,
        children: TagColors.palette.map((color) {
            final isSelected = color.toARGB32() == _selectedColor.toARGB32();

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: theme.colorScheme.primary,
                        size: 20,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Todo 그룹 여부 스위치
  Widget _buildTodoGroupSwitch(ThemeData theme) {
    return SwitchListTile(
      title: const Text('할 일 그룹'),
      subtitle: const Text('이 그룹의 태그를 할 일에도 사용합니다'),
      value: _isTodoGroup,
      onChanged: (value) {
        setState(() {
          _isTodoGroup = value;
        });
      },
      contentPadding: EdgeInsets.zero,
      secondary: Icon(
        _isTodoGroup ? Icons.check_box : Icons.label,
        color: theme.colorScheme.primary,
      ),
    );
  }

  /// 버튼 영역
  Widget _buildButtonBar(bool isEditMode, bool isLoading) {
    return Row(
      children: [
        // 취소 버튼
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('취소'),
          ),
        ),

        const SizedBox(width: 16),

        // 저장 버튼
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: isLoading ? null : _handleSubmit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(isEditMode ? '수정' : '생성'),
          ),
        ),
      ],
    );
  }

  /// 폼 제출 처리
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (widget.tagGroup != null) {
        // 수정 모드
        final updateData = TagGroupUpdate(
          name: _nameController.text.trim(),
          color: _selectedColor.toHex(),
          isTodoGroup: _isTodoGroup,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );

        await ref.read(tagMutationsProvider.notifier)
            .updateGroup(widget.tagGroup!.id, updateData);

        if (mounted) {
          navigator.pop();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('태그 그룹이 수정되었습니다'),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // 생성 모드
        final createData = TagGroupCreate(
          name: _nameController.text.trim(),
          color: _selectedColor.toHex(),
          isTodoGroup: _isTodoGroup,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );

        await ref.read(tagMutationsProvider.notifier).createGroup(createData);

        if (mounted) {
          navigator.pop();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('태그 그룹이 생성되었습니다'),
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
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.tagGroup != null
                        ? '태그 그룹 수정에 실패했습니다: $error'
                        : '태그 그룹 생성에 실패했습니다: $error',
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
}

/// 태그 그룹 폼 시트를 표시하는 헬퍼 함수
Future<void> showTagGroupFormSheet(
  BuildContext context, {
  TagGroupReadWithTags? tagGroup,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TagGroupFormSheet(tagGroup: tagGroup),
  );
}
