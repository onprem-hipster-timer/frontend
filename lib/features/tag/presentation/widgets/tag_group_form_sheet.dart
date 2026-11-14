import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/network/explicit_null_interceptor.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/tag_providers.dart';
import 'package:momeet/features/tag/presentation/utils/tag_color_palette.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/features/tag/presentation/widgets/group_form_fields.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 태그 그룹 생성/수정 폼 시트. 칸은 [GroupFormFields]
class TagGroupFormSheet extends ConsumerStatefulWidget {
  /// 수정할 태그 그룹 (null인 경우 생성 모드)
  final TagGroupReadWithTags? tagGroup;

  const TagGroupFormSheet({super.key, this.tagGroup});

  @override
  ConsumerState<TagGroupFormSheet> createState() => _TagGroupFormSheetState();
}

class _TagGroupFormSheetState extends ConsumerState<TagGroupFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  late Color _selectedColor;

  @override
  void initState() {
    super.initState();

    // 수정 모드인 경우 기존 값으로 초기화
    if (widget.tagGroup != null) {
      _nameController.text = widget.tagGroup!.name;
      _descriptionController.text = widget.tagGroup!.description ?? '';
      _selectedColor = HexColor.fromHex(widget.tagGroup!.color);
    } else {
      // 생성 모드인 경우 기본값 설정
      _selectedColor = TagColorPalette.defaultColor;
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
    final isEditMode = widget.tagGroup != null;
    final isLoading = isEditMode
        ? ref.watch(updateTagGroupMutation).isPending
        : ref.watch(createTagGroupMutation).isPending;

    return AppFormSheet(
      title: isEditMode ? '${Terms.tagGroup} 수정' : '새 ${Terms.tagGroup} 만들기',
      formKey: _formKey,
      actions: AppFormActionBar(
        submitLabel: isEditMode ? '수정' : '생성',
        onSubmit: _handleSubmit,
        busy: isLoading,
      ),
      children: [
        GroupFormFields(
          noun: Terms.tagGroup,
          nameController: _nameController,
          descriptionController: _descriptionController,
          color: _selectedColor,
          onColorChanged: (color) => setState(() => _selectedColor = color),
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
        final description = _descriptionController.text.trim();
        final updateData = TagGroupUpdate(
          name: _nameController.text.trim(),
          color: _selectedColor.toHex(),
          description: description.isEmpty ? null : description,
        );

        await updateTagGroupMutation.run(
          ref,
          (tsx) => tsx
              .get(tagGroupsRawProvider.notifier)
              .updateGroup(
                widget.tagGroup!.id,
                updateData,
                options: description.isEmpty
                    ? explicitNulls(['description'])
                    : null,
              ),
        );

        if (mounted) {
          navigator.pop();
          scaffoldMessenger.showAppSnackBar(
            '${Terms.tagGroup.withJosa('이', '가')} 수정되었습니다',
            kind: AppNoticeKind.success,
          );
        }
      } else {
        // 생성 모드
        final createData = TagGroupCreate(
          name: _nameController.text.trim(),
          color: _selectedColor.toHex(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );

        await createTagGroupMutation.run(
          ref,
          (tsx) =>
              tsx.get(tagGroupsRawProvider.notifier).createGroup(createData),
        );

        if (mounted) {
          navigator.pop();
          scaffoldMessenger.showAppSnackBar(
            '${Terms.tagGroup.withJosa('이', '가')} 생성되었습니다',
            kind: AppNoticeKind.success,
          );
        }
      }
    } catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          widget.tagGroup != null
              ? '${Terms.tagGroup} 수정에 실패했습니다: $error'
              : '${Terms.tagGroup} 생성에 실패했습니다: $error',
          kind: AppNoticeKind.error,
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
  return showAppSheet<void>(
    context,
    builder: (context) => TagGroupFormSheet(tagGroup: tagGroup),
  );
}
