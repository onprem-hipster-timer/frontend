import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/export.dart';
import 'package:momeet/features/tag/domain/tag_group_with_tags.dart';
import 'package:momeet/features/tag/presentation/providers/tag_providers.dart';
import 'package:momeet/features/tag/presentation/utils/tag_color_palette.dart';
import 'package:momeet/core/utils/color_utils.dart';

/// 태그 생성/수정 폼 시트
///
/// Modal Bottom Sheet로 표시되며, 태그의 이름, 그룹, 색상을 편집할 수 있습니다.
class TagFormSheet extends ConsumerStatefulWidget {
  /// 수정할 태그 (null인 경우 생성 모드)
  final TagRead? tag;

  /// 사용 가능한 태그 그룹 목록
  final List<TagGroupWithTags> availableGroups;

  /// 기본 선택될 그룹 ID (생성 모드에서 사용)
  final String? defaultGroupId;

  const TagFormSheet({
    super.key,
    this.tag,
    required this.availableGroups,
    this.defaultGroupId,
  });

  @override
  ConsumerState<TagFormSheet> createState() => _TagFormSheetState();
}

class _TagFormSheetState extends ConsumerState<TagFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  late Color _selectedColor;
  late String _selectedGroupId;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();

    _isEditMode = widget.tag != null;

    if (_isEditMode) {
      // 수정 모드: 기존 데이터로 초기화
      final tag = widget.tag!;
      _nameController.text = tag.name;
      _selectedColor = HexColor.fromHex(tag.color);
      _selectedGroupId = tag.groupId;
    } else {
      // 생성 모드: 기본값으로 초기화
      _selectedColor = TagColorPalette.defaultColor;
      _selectedGroupId = widget.defaultGroupId ??
          (widget.availableGroups.isNotEmpty ? widget.availableGroups.first.groupId : '');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutations = ref.watch(tagMutationsProvider);
    final isLoading = mutations.isLoading;

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
                _buildHeader(theme),

                const SizedBox(height: 24),

                // 태그 이름 입력
                _buildNameField(),

                const SizedBox(height: 20),

                // 그룹 선택
                _buildGroupSelector(theme),

                const SizedBox(height: 24),

                // 색상 선택
                _buildColorPicker(theme),

                const SizedBox(height: 32),

                // 버튼 영역
                _buildButtonBar(isLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 헤더 (제목과 핸들)
  Widget _buildHeader(ThemeData theme) {
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
          _isEditMode ? '태그 수정' : '새 태그 만들기',
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
      textInputAction: TextInputAction.done,
    );
  }

  /// 그룹 선택 드롭다운
  Widget _buildGroupSelector(ThemeData theme) {
    // 수정 모드에서는 현재 그룹 정보만 표시 (변경 불가)
    if (_isEditMode) {
      final currentGroup = widget.availableGroups.firstWhere(
        (group) => group.groupId == _selectedGroupId,
        orElse: () => widget.availableGroups.first,
      );

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

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_outlined, color: Colors.grey),
                const SizedBox(width: 12),

                // 그룹 색상 점
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: HexColor.fromHex(currentGroup.groupColor),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),

                // 그룹 이름
                Expanded(
                  child: Text(
                    currentGroup.groupName,
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ),

                // 수정 불가 안내
                Text(
                  '(수정 불가)',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 생성 모드에서는 그룹 선택 가능
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
            prefixIcon: const Icon(Icons.folder_outlined),
          ),
          items: widget.availableGroups.map((group) {
            return DropdownMenuItem<String>(
              value: group.groupId,
              child: Row(
                children: [
                  // 그룹 색상 점
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: HexColor.fromHex(group.groupColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 그룹 이름
                  Expanded(
                    child: Text(group.groupName),
                  ),
                  // 태그 개수 배지
                  if (group.tagCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${group.tagCount}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
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

  /// 색상 선택기 (16가지 파스텔 팔레트)
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

        // 색상 팔레트 그리드 (4x4)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: TagColorPalette.colors.map((color) {
            final isSelected = color.toARGB32() == _selectedColor.toARGB32();

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: theme.colorScheme.primary,
                        size: 24,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 8),

        // 선택된 색상 미리보기
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _selectedColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '선택된 색상: ${_selectedColor.toHex()}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 버튼 영역 (취소/저장)
  Widget _buildButtonBar(bool isLoading) {
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
                : Text(_isEditMode ? '수정' : '생성'),
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
      if (_isEditMode) {
        // 수정 모드
        final updateData = TagUpdate(
          name: _nameController.text.trim(),
          color: _selectedColor.toHex(),
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
                    _isEditMode
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
  required List<TagGroupWithTags> availableGroups,
  String? defaultGroupId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TagFormSheet(
      tag: tag,
      availableGroups: availableGroups,
      defaultGroupId: defaultGroupId,
    ),
  );
}
