import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/tag/presentation/utils/tag_color_palette.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/features/tag/presentation/widgets/group_form_fields.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 태그 그룹 생성/수정 폼 시트. 칸은 [GroupFormFields]
///
/// 칸을 검사한 뒤 다듬은 이름·설명과 고른 색으로 [onSubmit]을 부르고, [busy]인 동안은 버튼에 진행 표시를 둔다.
class TagGroupFormSheetView extends StatefulWidget {
  const TagGroupFormSheetView({
    super.key,
    this.tagGroup,
    required this.busy,
    required this.onSubmit,
  });

  /// 수정할 태그 그룹 (null인 경우 생성 모드)
  final TagGroupReadWithTags? tagGroup;
  final bool busy;
  final void Function(String name, String description, Color color) onSubmit;

  @override
  State<TagGroupFormSheetView> createState() => _TagGroupFormSheetViewState();
}

class _TagGroupFormSheetViewState extends State<TagGroupFormSheetView> {
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

    return AppFormSheet(
      title: isEditMode ? '${Terms.tagGroup} 수정' : '새 ${Terms.tagGroup} 만들기',
      formKey: _formKey,
      actions: AppFormActionBar(
        submitLabel: isEditMode ? '수정' : '생성',
        onSubmit: _submit,
        busy: widget.busy,
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

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    widget.onSubmit(
      _nameController.text.trim(),
      _descriptionController.text.trim(),
      _selectedColor,
    );
  }
}
