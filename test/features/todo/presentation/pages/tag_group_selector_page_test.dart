import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/pages/tag_group_selector_page.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/sheet_host.dart';

void main() {
  late FakeTagsClient tags;
  late List<TagGroupRead?> results;

  setUp(() {
    results = [];
    tags = FakeTagsClient([
      makeTagGroup(id: 'group-work', name: '업무', description: '회사 일'),
      makeTagGroup(id: 'group-study', name: '학습'),
    ]);
  });

  Future<void> open(WidgetTester tester) => pumpSheetHost(
    tester,
    overrides: [tagsApiProvider.overrideWithValue(tags)],
    open: (context) async {
      results.add(
        await Navigator.of(context).push<TagGroupRead>(
          MaterialPageRoute(builder: (_) => const TagGroupSelectorPage()),
        ),
      );
    },
  );

  testWidgets('그룹 카드와 새 그룹 카드를 보이고, 고른 그룹을 돌려주며 닫는다', (tester) async {
    await open(tester);

    expect(find.text('어떤 그룹에 만들까요?'), findsOneWidget);
    expect(find.text('업무'), findsOneWidget);
    expect(find.text('회사 일'), findsOneWidget);
    expect(find.text('학습'), findsOneWidget);
    expect(find.text('새 그룹 만들기'), findsOneWidget);

    await tapVisible(tester, find.text('학습'));
    expect(find.text('어떤 그룹에 만들까요?'), findsNothing);
    expect(results.single?.id, 'group-study');
  });

  testWidgets('새 그룹 카드는 그룹 생성 시트를 열고, 만든 그룹이 카드로 나타난다', (tester) async {
    await open(tester);
    await tapVisible(tester, find.text('새 그룹 만들기'));
    await tester.enterText(find.widgetWithText(TextFormField, '그룹 이름'), '운동');
    await tapVisible(tester, find.text('생성'));

    expect(find.text('운동'), findsOneWidget);
    expect(results, isEmpty);
  });

  testWidgets('그룹이 없으면 안내와 새 그룹 만들기 버튼을 보인다', (tester) async {
    tags.groups.clear();
    await open(tester);

    expect(find.text('태그 그룹이 없습니다'), findsOneWidget);
    await tapVisible(tester, find.widgetWithText(FilledButton, '새 그룹 만들기'));
    expect(find.widgetWithText(TextFormField, '그룹 이름'), findsOneWidget);
  });

  testWidgets('불러오지 못하면 오류를 보이고 돌아가기는 아무 그룹도 돌려주지 않는다', (tester) async {
    tags.readError = Exception('끊김');
    await open(tester);

    expect(find.text('태그 그룹을 불러오지 못했습니다'), findsOneWidget);
    await tapVisible(tester, find.text('돌아가기'));
    expect(find.text('어떤 그룹에 만들까요?'), findsNothing);
    expect(results, [null]);
  });
}
