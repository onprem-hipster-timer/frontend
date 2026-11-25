import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/tag/presentation/utils/tag_color_palette.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_color_picker.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '색상 선택', type: TagColorPicker, path: '[태그 관리]')
Widget tagColorPicker(BuildContext context) => const _Picker();

/// 동그라미를 누르면 고른 색이 바뀐다
class _Picker extends StatefulWidget {
  const _Picker();

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  Color _selected = TagColorPalette.defaultColor;

  @override
  Widget build(BuildContext context) {
    // 앱에서는 태그·태그 그룹 시트 안, 좌우 24 여백에 둔다
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: TagColorPicker(
        selected: _selected,
        onChanged: (color) => setState(() => _selected = color),
      ),
    );
  }
}
