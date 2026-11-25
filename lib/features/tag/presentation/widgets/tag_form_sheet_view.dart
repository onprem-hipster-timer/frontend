import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/tag_group_with_tags.dart';
import 'package:momeet/features/tag/presentation/utils/tag_color_palette.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_color_picker.dart';

/// 태그 생성/수정 폼 시트. 이름, 넣을 태그 그룹([groups] 중에서), 색을 고른다.
///
/// [tag]가 있으면 그 값으로 채운 수정 폼이고, 태그 그룹은 바꿀 수 없다. 칸을 검사한 뒤 다듬은 이름과 고른 색·그룹
/// id로 [onSubmit]을 부르고, [busy]인 동안은 버튼에 진행 표시를 둔다.
class TagFormSheetView extends StatefulWidget {
  const TagFormSheetView({
    super.key,
    this.tag,
    this.defaultGroupId,
    required this.groups,
    required this.busy,
    required this.onSubmit,
  });

  final TagRead? tag;
  final String? defaultGroupId;
  final AsyncValue<List<TagGroupWithTags>> groups;
  final bool busy;
  final void Function(String name, Color color, String groupId) onSubmit;

  @override
  State<TagFormSheetView> createState() => _TagFormSheetViewState();
}

class _TagFormSheetViewState extends State<TagFormSheetView> {
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
      final tag = widget.tag!;
      _nameController.text = tag.name;
      _selectedColor = HexColor.fromHex(tag.color);
      _selectedGroupId = tag.groupId;
    } else {
      _selectedColor = TagColorPalette.defaultColor;
      _selectedGroupId = widget.defaultGroupId ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableGroupsAsync = widget.groups;

    return availableGroupsAsync.when(
      loading: () => const SafeArea(child: AppLoading()),
      error: (error, stack) => SafeArea(
        child: AppErrorState(
          title: '${Terms.tagGroup.withJosa('을', '를')} 불러올 수 없습니다',
          error: error,
        ),
      ),
      data: (availableGroups) {
        // 첫 로드 시 기본 그룹 ID 설정
        if (_selectedGroupId.isEmpty && availableGroups.isNotEmpty) {
          _selectedGroupId =
              widget.defaultGroupId ?? availableGroups.first.groupId;
        }

        return AppFormSheet(
          title: _isEditMode ? '태그 수정' : '새 태그 만들기',
          formKey: _formKey,
          actions: AppFormActionBar(
            submitLabel: _isEditMode ? '수정' : '생성',
            onSubmit: _submit,
            busy: widget.busy,
          ),
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '태그 이름',
                hintText: '태그 이름을 입력하세요',
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
            ),
            if (_isEditMode)
              _FixedGroupField(
                group: availableGroups.firstWhere(
                  (group) => group.groupId == _selectedGroupId,
                  orElse: () => availableGroups.first,
                ),
              )
            else
              _GroupDropdown(
                groups: availableGroups,
                selectedId: _selectedGroupId,
                onChanged: (id) => setState(() => _selectedGroupId = id),
              ),
            TagColorPicker(
              selected: _selectedColor,
              onChanged: (color) => setState(() => _selectedColor = color),
            ),
          ],
        );
      },
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      _nameController.text.trim(),
      _selectedColor,
      _selectedGroupId,
    );
  }
}

/// 수정할 때 바꿀 수 없는 태그 그룹 표시
class _FixedGroupField extends StatelessWidget {
  const _FixedGroupField({required this.group});

  final TagGroupWithTags group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(Terms.tagGroup),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            borderRadius: AppRadius.lgAll,
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.folder_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: HexColor.fromHex(group.groupColor),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.groupName,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Icon(
                Icons.lock_outline,
                size: 16,
                semanticLabel: '수정 불가',
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 태그를 넣을 그룹 고르기
class _GroupDropdown extends StatelessWidget {
  const _GroupDropdown({
    required this.groups,
    required this.selectedId,
    required this.onChanged,
  });

  final List<TagGroupWithTags> groups;
  final String selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(Terms.tagGroup),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          // ⭐️ 핵심 Fix: 드롭다운이 넓이를 안전하게 잡도록 보장
          isExpanded: true,
          initialValue: selectedId.isNotEmpty ? selectedId : null,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.folder_outlined),
          ),
          items: groups.map((group) {
            return DropdownMenuItem<String>(
              value: group.groupId,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: HexColor.fromHex(group.groupColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ⭐️ 핵심 Fix: Expanded를 제거하고 글자가 길면 잘리도록 처리
                  Flexible(
                    child: Text(
                      group.groupName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (group.tagCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: AppRadius.mdAll,
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
            if (value != null) onChanged(value);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '${Terms.tagGroup.withJosa('을', '를')} 선택해주세요';
            }
            return null;
          },
        ),
      ],
    );
  }
}
