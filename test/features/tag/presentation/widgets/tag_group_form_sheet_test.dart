import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_group_form_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/sheet_host.dart';

void main() {
  late FakeTagsClient tags;

  setUp(() {
    tags = FakeTagsClient([
      makeTagGroup(
        id: 'group-work',
        name: '업무',
        color: '#B3D4FF',
        description: '회사 일',
      ),
    ]);
  });

  Future<void> open(WidgetTester tester, {TagGroupReadWithTags? group}) =>
      pumpSheetHost(
        tester,
        overrides: [tagsApiProvider.overrideWithValue(tags)],
        open: (context) => showTagGroupFormSheet(context, tagGroup: group),
      );

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Finder swatch(int argb) => find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration! as BoxDecoration).color?.toARGB32() == argb,
  );

  group('새 그룹', () {
    testWidgets('이름이 비거나 50자, 설명이 200자를 넘으면 오류를 보이고 보내지 않는다', (tester) async {
      await open(tester);
      expect(find.text('새 그룹 만들기'), findsOneWidget);

      await tapVisible(tester, find.text('생성'));
      expect(find.text('그룹 이름을 입력해주세요'), findsOneWidget);

      await tester.enterText(field('그룹 이름'), 'a' * 51);
      await tester.enterText(field('설명 (선택사항)'), 'b' * 201);
      await tapVisible(tester, find.text('생성'));
      expect(find.text('그룹 이름은 50자 이하로 입력해주세요'), findsOneWidget);
      expect(find.text('설명은 200자 이하로 입력해주세요'), findsOneWidget);
      expect(tags.createdGroups, isEmpty);
    });

    testWidgets('이름·설명·색을 다듬어 보내고 닫는다', (tester) async {
      await open(tester);
      await tester.enterText(field('그룹 이름'), '  학습  ');
      await tester.enterText(field('설명 (선택사항)'), '  공부 기록  ');
      await tapVisible(tester, swatch(0xFFCCB3FF));
      await tapVisible(tester, find.text('생성'));

      final body = tags.createdGroups.single;
      expect(body.name, '학습');
      expect(body.description, '공부 기록');
      expect(body.color, '#CCB3FF');
      expect(find.text('새 그룹 만들기'), findsNothing);
      expect(find.text('태그 그룹이 생성되었습니다'), findsOneWidget);
    });

    testWidgets('설명이 비면 null, 색은 기본 색으로 보낸다', (tester) async {
      await open(tester);
      await tester.enterText(field('그룹 이름'), '학습');
      await tapVisible(tester, find.text('생성'));

      final body = tags.createdGroups.single;
      expect(body.description, isNull);
      expect(body.color, '#FFB3B3');
    });

    testWidgets('보내기에 실패하면 시트를 두고 오류를 알린다', (tester) async {
      tags.writeError = Exception('서버 오류');
      await open(tester);
      await tester.enterText(field('그룹 이름'), '학습');
      await tapVisible(tester, find.text('생성'));

      expect(find.text('새 그룹 만들기'), findsOneWidget);
      expect(find.textContaining('태그 그룹 생성에 실패했습니다'), findsOneWidget);
    });

    testWidgets('취소는 보내지 않고 닫는다', (tester) async {
      await open(tester);
      await tester.enterText(field('그룹 이름'), '학습');
      await tapVisible(tester, find.text('취소'));

      expect(find.text('새 그룹 만들기'), findsNothing);
      expect(tags.createdGroups, isEmpty);
    });
  });

  group('그룹 수정', () {
    testWidgets('기존 값을 채우고 바꾼 값을 보낸다', (tester) async {
      await open(tester, group: tags.groups.single);

      expect(find.text('그룹 수정'), findsOneWidget);
      expect(find.text('업무'), findsOneWidget);
      expect(find.text('회사 일'), findsOneWidget);

      await tester.enterText(field('그룹 이름'), '업무 2');
      await tapVisible(tester, find.text('수정'));

      final (id, body, options) = tags.updatedGroups.single;
      expect(id, 'group-work');
      expect(body.name, '업무 2');
      expect(body.description, '회사 일');
      expect(body.color, '#B3D4FF');
      expect(explicitNullFields(options), isEmpty);
      expect(find.text('그룹 수정'), findsNothing);
      expect(find.text('태그 그룹이 수정되었습니다'), findsOneWidget);
    });

    testWidgets('설명을 비우면 description을 null로 보내라고 표시한다', (tester) async {
      await open(tester, group: tags.groups.single);
      await tester.enterText(field('설명 (선택사항)'), '');
      await tapVisible(tester, find.text('수정'));

      final (_, body, options) = tags.updatedGroups.single;
      expect(body.description, isNull);
      expect(explicitNullFields(options), ['description']);
    });

    testWidgets('수정에 실패하면 시트를 두고 오류를 알린다', (tester) async {
      tags.writeError = Exception('서버 오류');
      await open(tester, group: tags.groups.single);
      await tapVisible(tester, find.text('수정'));

      expect(find.text('그룹 수정'), findsOneWidget);
      expect(find.textContaining('태그 그룹 수정에 실패했습니다'), findsOneWidget);
    });
  });
}
