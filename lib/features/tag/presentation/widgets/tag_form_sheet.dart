import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/export.dart';
import 'package:momeet/features/tag/presentation/providers/tag_providers.dart';
import 'package:momeet/features/tag/presentation/utils/color_utils.dart';

/// 태그 생성/수정 폼 시트
///
/// Modal Bottom Sheet로 표시되며, 태그의 이름과 색상을 편집할 수 있습니다.
class TagFormSheet extends ConsumerStatefulWidget {
  /// 수정할 태그 (null인 경우 생성 모드)
  final TagRead? tag;

  /// 기본 그룹 ID (생성 시 사용)
  final String? defaultGroupId;

  /// 사용 가능한 태그 그룹 목록
  final List<TagGroupReadWithTags> availableGroups;

  const TagFormSheet({
    super.key,
    this.tag,
    this.defaultGroupId,
    required this.availableGroups,
  });

  @override
  ConsumerState<TagFormSheet> createState() => _TagFormSheetState();
}

class _TagFormSheetState extends ConsumerState<TagFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  late Color _selectedColor;
  late String _selectedGroupId;

  @override
  void initState() {
    super.initState();

    // 수정 모드인 경우 기존 값으로 초기화
    if (widget.tag != null) {
      _nameController.text = widget.tag!.name;
      _descriptionController.text = widget.tag!.description ?? '';
      _selectedColor = ColorExt.fromHex(widget.tag!.color);
      _selectedGroupId = widget.tag!.groupId;
    } else {
      // 생성 모드인 경우 기본값 설정
      _selectedColor = TagColors.defaultColor;
      _selectedGroupId = widget.defaultGroupId ??
          (widget.availableGroups.isNotEmpty ? widget.availableGroups.first.id : '');
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
    final isEditMode = widget.tag != null;

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

                // 태그 이름 입력
                _buildNameField(),

                const SizedBox(height: 20),

                // 설명 입력 (선택사항)
                _buildDescriptionField(),

                const SizedBox(height: 24),

                // 색상 선택
                _buildColorPicker(theme),

                const SizedBox(height: 24),

                // 그룹 선택 (생성 시에만)
                if (!isEditMode && widget.availableGroups.isNotEmpty)
                  ...[
                    _buildGroupSelector(theme),
                    const SizedBox(height: 32),
                  ]
                else
                  const SizedBox(height: 8),

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
          isEditMode ? '태그 수정' : '새 태그 만들기',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 태그 이름 입력 필드
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      autofocus: true,
      decoration: InputDecoration(
        labelText: '태그 이름',
        hintText: '태그 이름을 입력하세요',
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
          return '태그 이름을 입력해주세요';
        }
        if (value.trim().length > 50) {
          return '태그 이름은 50자 이하로 입력해주세요';
        }
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  /// 설명 입력 필드 (선택사항)
  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: '설명 (선택사항)',
        hintText: '태그에 대한 간단한 설명을 입력하세요',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.notes),
        alignLabelWithHint: true,
      ),
      maxLines: 2,
      validator: (value) {
        if (value != null && value.length > 200) {
          return '설명은 200자 이하로 입력해주세요';
        }
        return null;
      },
      textInputAction: TextInputAction.done,
    );
  }

  /// 색상 선택기 (팔레트 그리드)
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

  /// 그룹 선택기 (드롭다운)
  Widget _buildGroupSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '태그 그룹',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        DropdownButtonFormField<String>(
          initialValue: _selectedGroupId.isNotEmpty ? _selectedGroupId : null,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.folder),
          ),
          items: widget.availableGroups.map((group) {
            return DropdownMenuItem<String>(
              value: group.id,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: ColorExt.fromHex(group.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(group.name),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedGroupId = value;
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '태그 그룹을 선택해주세요';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// 버튼 영역 (취소/저장)
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
      if (widget.tag != null) {
        // 수정 모드
        final updateData = TagUpdate(
          name: _nameController.text.trim(),
          color: _selectedColor.toHex(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );

        await ref.read(tagMutationsProvider.notifier)
            .updateTag(widget.tag!.id, updateData);

        if (mounted) {
          navigator.pop();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('태그가 수정되었습니다'),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // 생성 모드
        final createData = TagCreate(
          name: _nameController.text.trim(),
          color: _selectedColor.toHex(),
          groupId: _selectedGroupId,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );

        await ref.read(tagMutationsProvider.notifier).createTag(createData);

        if (mounted) {
          navigator.pop();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('태그가 생성되었습니다'),
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
                    widget.tag != null
                        ? '태그 수정에 실패했습니다: $error'
                        : '태그 생성에 실패했습니다: $error',
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

/// 태그 폼 시트를 표시하는 헬퍼 함수
///
/// 사용 예:
/// ```dart
/// showTagFormSheet(
///   context,
///   availableGroups: groups,
///   defaultGroupId: groupId,
/// );
/// ```
Future<void> showTagFormSheet(
  BuildContext context, {
  TagRead? tag,
  String? defaultGroupId,
  required List<TagGroupReadWithTags> availableGroups,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TagFormSheet(
      tag: tag,
      defaultGroupId: defaultGroupId,
      availableGroups: availableGroups,
    ),
  );
}
