import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_group_card.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet_widgetbook/calendar/samples_plan.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _colors = {
  '파랑': '#3F51B5',
  '초록': '#2E7D32',
  '주황': '#E64A19',
  '보라': '#8E24AA',
};

@widgetbook.UseCase(name: '해야 할 일 목록 카드', type: TodoGroupCard, path: '[할 일]')
Widget todoGroupCard(BuildContext context) {
  final knobs = context.knobs;
  final name = knobs.string(label: '목록 이름', initialValue: '졸업 프로젝트');
  final description = knobs.stringOrNull(
    label: '설명',
    initialValue: '4월 중간 발표 전까지 끝낼 일',
  );
  final color = knobs.object.dropdown(
    label: '색',
    options: _colors.keys.toList(),
  );
  final group = TodoGroupRead(
    id: 'todo-group-1',
    name: name,
    color: _colors[color]!,
    isDefault: false,
    createdAt: planStamp,
    updatedAt: planStamp,
    description: description,
  );
  // 할 일 탭 첫 화면처럼 격자 한 칸에 둔다. 칸 높이는 격자가 글자 크기로 잰다
  return GridView(
    padding: const EdgeInsets.all(16),
    gridDelegate: TodoGroupCard.gridDelegate(context),
    children: [TodoGroupCard(group: group, onTap: () {})],
  );
}
