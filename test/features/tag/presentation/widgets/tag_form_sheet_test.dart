import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_form_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/schedule_fixtures.dart';
import '../../../../helpers/sheet_host.dart';

void main() {
  late FakeTagsClient tags;

  final study = makeTag(id: 'tag-study', name: '공부', groupId: 'group-study');

  setUp(() {
    tags = FakeTagsClient([
      makeTagGroup(id: 'group-work', name: '업무'),
      makeTagGroup(id: 'group-study', name: '학습', tags: [study]),
    ]);
  });

  Future<void> open(
    WidgetTester tester, {
    TagRead? tag,
    String? defaultGroupId,
  }) => pumpSheetHost(
    tester,
    overrides: [tagsApiProvider.overrideWithValue(tags)],
    open: (context) =>
        showTagFormSheet(context, tag: tag, defaultGroupId: defaultGroupId),
  );

  Finder nameField() => find.widgetWithText(TextFormField, '태그 이름');

  Finder swatch(int argb) => find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration! as BoxDecoration).color?.toARGB32() == argb,
  );

  group('새 태그', () {
    testWidgets('이름이 비거나 50자를 넘으면 오류를 보이고 보내지 않는다', (tester) async {
      await open(tester);
      expect(find.text('새 태그 만들기'), findsOneWidget);

      await tapVisible(tester, find.text('생성'));
      expect(find.text('태그 이름을 입력해주세요'), findsOneWidget);

      await tester.enterText(nameField(), 'a' * 51);
      await tapVisible(tester, find.text('생성'));
      expect(find.text('태그 이름은 50자 이하로 입력해주세요'), findsOneWidget);
      expect(tags.createdTags, isEmpty);
    });

    testWidgets('그룹을 안 정하면 태그가 가장 많은 그룹, 기본 색으로 만든 뒤 닫는다', (tester) async {
      await open(tester);
      await tester.enterText(nameField(), '  독서  ');
      await tapVisible(tester, find.text('생성'));

      final body = tags.createdTags.single;
      expect(body.name, '독서');
      expect(body.groupId, 'group-study');
      expect(body.color, '#FFB3B3');
      expect(find.text('새 태그 만들기'), findsNothing);
      expect(find.text('태그가 생성되었습니다'), findsOneWidget);
    });

    testWidgets('받은 기본 그룹과 고른 색으로 만든다', (tester) async {
      await open(tester, defaultGroupId: 'group-work');
      await tester.enterText(nameField(), '회의');
      await tapVisible(tester, swatch(0xFFB3D4FF));
      await tapVisible(tester, find.text('생성'));

      final body = tags.createdTags.single;
      expect(body.groupId, 'group-work');
      expect(body.color, '#B3D4FF');
    });

    testWidgets('드롭다운에서 다른 그룹을 고를 수 있다', (tester) async {
      await open(tester);
      await tapVisible(tester, find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.text('업무').last);
      await tester.pumpAndSettle();
      await tester.enterText(nameField(), '회의');
      await tapVisible(tester, find.text('생성'));

      expect(tags.createdTags.single.groupId, 'group-work');
    });

    testWidgets('보내기에 실패하면 시트를 두고 오류를 알린다', (tester) async {
      tags.writeError = Exception('서버 오류');
      await open(tester);
      await tester.enterText(nameField(), '회의');
      await tapVisible(tester, find.text('생성'));

      expect(find.text('새 태그 만들기'), findsOneWidget);
      expect(find.textContaining('태그 생성 실패'), findsOneWidget);
    });

    testWidgets('취소는 보내지 않고 닫는다', (tester) async {
      await open(tester);
      await tester.enterText(nameField(), '회의');
      await tapVisible(tester, find.text('취소'));

      expect(find.text('새 태그 만들기'), findsNothing);
      expect(tags.createdTags, isEmpty);
    });

    testWidgets('태그 그룹을 불러오지 못하면 오류만 보인다', (tester) async {
      tags.readError = Exception('끊김');
      await open(tester);

      expect(find.textContaining('태그 그룹을 불러올 수 없습니다'), findsOneWidget);
      expect(nameField(), findsNothing);
    });
  });

  group('태그 수정', () {
    testWidgets('기존 이름·그룹을 보이고 그룹은 바꿀 수 없으며, 이름·색을 보낸다', (tester) async {
      await open(tester, tag: study);

      expect(find.text('태그 수정'), findsOneWidget);
      expect(find.text('공부'), findsOneWidget);
      expect(find.text('학습'), findsOneWidget);
      expect(find.text('(수정 불가)'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);

      await tester.enterText(nameField(), '공부 2');
      await tapVisible(tester, swatch(0xFFB3D4FF));
      await tapVisible(tester, find.text('수정'));

      final (id, body, _) = tags.updatedTags.single;
      expect(id, 'tag-study');
      expect(body.name, '공부 2');
      expect(body.color, '#B3D4FF');
      expect(find.text('태그 수정'), findsNothing);
      expect(find.text('태그가 수정되었습니다'), findsOneWidget);
    });

    testWidgets('수정에 실패하면 시트를 두고 오류를 알린다', (tester) async {
      tags.writeError = Exception('서버 오류');
      await open(tester, tag: study);
      await tapVisible(tester, find.text('수정'));

      expect(find.text('태그 수정'), findsOneWidget);
      expect(find.textContaining('태그 수정 실패'), findsOneWidget);
    });
  });
}
