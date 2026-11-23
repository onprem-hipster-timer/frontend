import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet_widgetbook/main.dart';
import 'package:widgetbook/widgetbook.dart';

/// [useCase] 하나를 카탈로그와 같은 appBuilder·애드온(기본 뷰포트 360x800, ko_KR, 글자 배율 1)으로
/// 미리보기 모드에서 그린다. 노브는 초기값을 쓴다.
///
/// 끝없이 도는 애니메이션이 있어도 멈추도록 pumpAndSettle 대신 정해진 프레임만 넘긴다.
Future<void> pumpUseCase(
  WidgetTester tester,
  WidgetbookUseCase useCase, {
  Brightness brightness = Brightness.light,
}) async {
  tester.view
    ..physicalSize = const Size(360, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final theme = widgetbookAddons
      .whereType<ThemeAddon<ThemeData>>()
      .single
      .themes
      .firstWhere((theme) => theme.data.brightness == brightness);
  final route = Uri(
    path: '/',
    queryParameters: {
      'path': 'use-case',
      'preview': '',
      'theme': FieldCodec.encodeQueryGroup({'name': theme.name}),
    },
  );

  await tester.pumpWidget(
    Widgetbook(
      initialRoute: route.toString(),
      // 생성 트리의 노드를 넘기면 부모가 바뀌므로 새 노드로 감싼다
      directories: [
        WidgetbookUseCase(name: 'use-case', builder: useCase.builder),
      ],
      appBuilder: widgetbookAppBuilder,
      addons: widgetbookAddons,
      // 경로를 읽기 전 첫 프레임에 뜨는 기본 홈은 폭 360에서 넘친다
      home: const SizedBox.shrink(),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
