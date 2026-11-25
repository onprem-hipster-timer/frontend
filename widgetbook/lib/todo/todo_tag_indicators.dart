import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_tag_indicators.dart';
import 'package:momeet_widgetbook/calendar/samples_plan.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '할 일 태그 표시', type: TodoTagIndicators, path: '[할 일]')
Widget todoTagIndicators(BuildContext context) {
  final knobs = context.knobs;
  final count = knobs.int.slider(
    label: '태그 수',
    description: '색 점은 두 개까지, 이름은 첫 태그만 보이고 나머지는 +N으로 센다. 0이면 아무것도 없다',
    initialValue: 3,
    min: 0,
    max: 6,
  );
  final long = knobs.boolean(label: '첫 태그 이름 길게');
  final tags = [
    if (long && count > 0) planLongTag,
    ...planTags.take(long ? count - 1 : count),
  ];
  // 할 일 줄의 제목 아래 줄처럼 남는 폭 안에서 줄인다
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Align(
      alignment: Alignment.centerLeft,
      child: TodoTagIndicators(tags: tags),
    ),
  );
}
