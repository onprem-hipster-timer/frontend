import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/features/tag/presentation/utils/tag_color_palette.dart';
import 'package:momeet/features/tag/presentation/widgets/group_form_fields.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 할 일 그룹 생성/수정 폼 시트. 칸은 [GroupFormFields]
///
/// 칸을 검사한 뒤 다듬은 이름·설명과 고른 색으로 [onSubmit]을 부르고, [busy]인 동안은 버튼에 진행 표시를 둔다.
class TodoGroupFormSheetView extends StatefulWidget {
  const TodoGroupFormSheetView({
    super.key,
    this.group,
    required this.busy,
    required this.onSubmit,
  });

  /// 수정할 할 일 그룹 (null이면 생성)
  final TodoGroupRead? group;
  final bool busy;
  final void Function(String name, String description, Color color) onSubmit;

  @override
  State<TodoGroupFormSheetView> createState() => _TodoGroupFormSheetViewState();
}

class _TodoGroupFormSheetViewState extends State<TodoGroupFormSheetView> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.group?.name);
  late final _descriptionController = TextEditingController(
    text: widget.group?.description,
  );
  late var _color = widget.group == null
      ? TagColorPalette.defaultColor
      : HexColor.fromHex(widget.group!.color);

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.group != null;
    return AppFormSheet(
      title: isEditMode ? '${Terms.todoGroup} 수정' : '새 ${Terms.todoGroup} 만들기',
      formKey: _formKey,
      actions: AppFormActionBar(
        submitLabel: isEditMode ? '수정' : '생성',
        onSubmit: _submit,
        busy: widget.busy,
      ),
      children: [
        GroupFormFields(
          noun: Terms.todoGroup,
          nameController: _nameController,
          descriptionController: _descriptionController,
          color: _color,
          onColorChanged: (color) => setState(() => _color = color),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      _nameController.text.trim(),
      _descriptionController.text.trim(),
      _color,
    );
  }
}
