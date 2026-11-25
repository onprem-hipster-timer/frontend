import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet_widgetbook/main.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookUseCase _useCase(String name) =>
    WidgetbookUseCase(name: name, builder: (_) => const SizedBox());

void main() {
  test('use case가 하나인 컴포넌트는 use case 이름 뒤에 클래스 이름을 붙인다', () {
    final nodes = labelSingleUseCases([
      WidgetbookCategory(
        name: '모임',
        children: [
          WidgetbookFolder(
            name: '추천 시간',
            children: [
              WidgetbookComponent(
                name: 'MeetingSlotCard',
                useCases: [_useCase('추천 시간 카드')],
              ),
              WidgetbookComponent(
                name: 'MeetingPanel',
                useCases: [_useCase('패널'), _useCase('도움말 있는 패널')],
              ),
            ],
          ),
        ],
      ),
    ]);

    final root = WidgetbookRoot(children: nodes);
    final components = root
        .findAll((node) => node is WidgetbookComponent)
        .map((node) => node.name);
    expect(components, ['추천 시간 카드 (MeetingSlotCard)', 'MeetingPanel']);
    expect(
      root.leaves.map(
        (node) => node.nodesPath.skip(1).map((node) => node.name).join('/'),
      ),
      [
        '모임/추천 시간/추천 시간 카드 (MeetingSlotCard)/추천 시간 카드',
        '모임/추천 시간/MeetingPanel/패널',
        '모임/추천 시간/MeetingPanel/도움말 있는 패널',
      ],
    );
  });
}
