import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/tag/presentation/utils/tag_color_palette.dart';
import 'package:momeet/features/tag/presentation/widgets/group_form_fields.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../auth/samples_account.dart';

@widgetbook.UseCase(
  name: '그룹 이름·설명·색 칸',
  type: GroupFormFields,
  path: '[태그 관리]',
)
Widget groupFormFields(BuildContext context) {
  final knobs = context.knobs;
  final noun = knobs.object.dropdown(
    label: '그룹 종류',
    description: '태그 관리의 태그 그룹과 할 일의 목록 만들기가 같은 칸을 쓴다',
    options: const [Terms.tagGroup, Terms.todoGroup],
  );
  final name = knobs.string(label: '이름', initialValue: '');
  final description = knobs.string(label: '설명', initialValue: '');
  final showErrors = knobs.boolean(
    label: '오류 표시',
    description: '생성을 누른 뒤. 이름이 비었거나 50자를 넘으면, 설명이 200자를 넘으면 칸 아래에 문구가 뜬다',
  );
  // 앱에서는 아래에서 올라오는 시트(새 … 만들기) 안이다
  return ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: AppFormSheet(
      title: '새 $noun 만들기',
      actions: AppFormActionBar(
        submitLabel: '생성',
        onSubmit: () {},
        onCancel: () {},
      ),
      children: [
        FormStage(
          texts: [name, description],
          showErrors: showErrors,
          builder: (controllers) => _Fields(
            noun: noun,
            name: controllers[0],
            description: controllers[1],
          ),
        ),
      ],
    ),
  );
}

/// 색을 누르면 이름 앞의 점과 고른 동그라미가 바뀐다
class _Fields extends StatefulWidget {
  const _Fields({
    required this.noun,
    required this.name,
    required this.description,
  });

  final String noun;
  final TextEditingController name;
  final TextEditingController description;

  @override
  State<_Fields> createState() => _FieldsState();
}

class _FieldsState extends State<_Fields> {
  Color _color = TagColorPalette.defaultColor;

  @override
  Widget build(BuildContext context) {
    return GroupFormFields(
      noun: widget.noun,
      nameController: widget.name,
      descriptionController: widget.description,
      color: _color,
      onColorChanged: (color) => setState(() => _color = color),
    );
  }
}
