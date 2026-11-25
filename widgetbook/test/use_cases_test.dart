import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet_widgetbook/main.directories.g.dart';
import 'package:momeet_widgetbook/shared/app_error_state.dart';
import 'package:widgetbook/widgetbook.dart';

import 'support/pump_use_case.dart';

void main() {
  final useCases = WidgetbookRoot(
    children: directories,
  ).leaves.whereType<WidgetbookUseCase>().toList();

  test('카탈로그에 use case가 하나 이상 있다', () {
    expect(useCases, isNotEmpty);
  });

  testWidgets('노브는 초기값으로 그려진다', (tester) async {
    await pumpUseCase(
      tester,
      WidgetbookUseCase(name: '불러오기 실패 안내', builder: appErrorState),
    );

    expect(find.text('일정을 불러올 수 없습니다'), findsOneWidget);
  });

  for (final useCase in useCases) {
    final path = useCase.nodesPath.skip(1).map((node) => node.name).join('/');
    for (final brightness in Brightness.values) {
      testWidgets('$path (${brightness.name}) 예외 없이 그려진다', (tester) async {
        await pumpUseCase(tester, useCase, brightness: brightness);

        expect(tester.takeException(), isNull);
      });
    }
  }
}
