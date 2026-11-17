import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_color_picker.dart';

/// 그룹 폼의 칸: 이름(앞에 고른 색 점), 설명, 색. 태그 그룹 폼과 할 일 그룹 폼이 함께 쓴다.
///
/// [noun]은 문구에 들어가는 그룹 이름이다(예: Terms.todoGroup).
class GroupFormFields extends StatelessWidget {
  const GroupFormFields({
    super.key,
    required this.noun,
    required this.nameController,
    required this.descriptionController,
    required this.color,
    required this.onColorChanged,
  });

  final String noun;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final Color color;
  final ValueChanged<Color> onColorChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        TextFormField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            label: Text('$noun 이름', maxLines: 2),
            hintText: '$noun 이름을 입력하세요',
            hintMaxLines: 3,
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '$noun 이름을 입력해주세요';
            }
            if (value.trim().length > 50) {
              return '$noun 이름은 50자 이하로 입력해주세요';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),
        TextFormField(
          controller: descriptionController,
          decoration: InputDecoration(
            label: const Text('설명 (선택사항)', maxLines: 2),
            hintText: '$noun에 대한 간단한 설명을 입력하세요',
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
        ),
        TagColorPicker(selected: color, onChanged: onColorChanged),
      ],
    );
  }
}
