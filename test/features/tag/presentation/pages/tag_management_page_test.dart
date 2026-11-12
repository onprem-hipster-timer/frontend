import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/tag/presentation/pages/tag_management_page.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/schedule_fixtures.dart';
import '../../../../helpers/sheet_host.dart';

void main() {
  late FakeTagsClient tags;

  final focus = makeTag(id: 'tag-focus', name: '집중', groupId: 'group-work');
  final study = makeTag(id: 'tag-study', name: '공부', groupId: 'group-study');
  final read = makeTag(id: 'tag-read', name: '독서', groupId: 'group-study');

  setUp(() {
    tags = FakeTagsClient([
      makeTagGroup(id: 'group-work', name: '업무', tags: [focus]),
      makeTagGroup(
        id: 'group-study',
        name: '학습',
        description: '공부 기록',
        tags: [study, read],
      ),
    ]);
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(800, 1600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: appRetry,
        overrides: [tagsApiProvider.overrideWithValue(tags)],
        child: const MaterialApp(home: TagManagementPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('태그가 많은 그룹부터, 설명이 없으면 태그 수를 보이고 하위 태그를 펼쳐 둔다', (tester) async {
    await pumpPage(tester);

    expect(
      tester.getTopLeft(find.text('학습')).dy,
      lessThan(tester.getTopLeft(find.text('업무')).dy),
    );
    expect(find.text('공부 기록'), findsOneWidget);
    expect(find.text('1개의 태그'), findsOneWidget);
    for (final name in ['집중', '공부', '독서']) {
      expect(find.text(name), findsOneWidget);
    }
  });

  testWidgets('그룹이 없으면 안내를 보이고 첫 그룹 만들기를 연다', (tester) async {
    tags.groups.clear();
    await pumpPage(tester);

    expect(find.text('아직 태그가 없습니다'), findsOneWidget);
    await tapVisible(tester, find.text('첫 태그 그룹 만들기'));
    expect(find.text('새 태그 그룹 만들기'), findsOneWidget);
  });

  testWidgets('불러오지 못하면 오류를 보이고 다시 시도하면 목록을 그린다', (tester) async {
    tags.readError = Exception('끊김');
    await pumpPage(tester);

    expect(find.text('태그를 불러올 수 없습니다'), findsOneWidget);
    tags.readError = null;
    await tapVisible(tester, find.text('다시 시도'));
    expect(find.text('학습'), findsOneWidget);
  });

  testWidgets('새 그룹 버튼은 그룹 생성 시트를 열고, 만든 그룹이 목록에 나타난다', (tester) async {
    await pumpPage(tester);
    await tapVisible(tester, find.text('새 그룹'));
    expect(find.text('새 태그 그룹 만들기'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, '태그 그룹 이름'),
      '운동',
    );
    await tapVisible(tester, find.text('생성'));
    expect(find.text('운동'), findsOneWidget);
  });

  testWidgets('그룹의 태그 추가는 그 그룹에 태그를 만든다', (tester) async {
    await pumpPage(tester);
    await tapVisible(tester, find.bySemanticsLabel('업무 그룹에 태그 추가'));
    expect(find.text('새 태그 만들기'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, '태그 이름'), '회의');
    await tapVisible(tester, find.text('생성'));
    expect(tags.createdTags.single.groupId, 'group-work');
    expect(find.text('회의'), findsOneWidget);
  });

  testWidgets('그룹 수정은 그 그룹 값으로 채운 시트를 연다', (tester) async {
    await pumpPage(tester);
    await tapVisible(tester, find.bySemanticsLabel('학습 그룹 수정'));

    expect(find.widgetWithText(TextFormField, '학습'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '공부 기록'), findsOneWidget);
  });

  testWidgets('태그의 수정 버튼과 태그 줄 누르기 모두 태그 수정 시트를 연다', (tester) async {
    await pumpPage(tester);
    await tapVisible(tester, find.bySemanticsLabel('공부 태그 수정'));
    expect(find.text('태그 수정'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '공부'), findsOneWidget);
    await tapVisible(tester, find.text('취소'));

    await tapVisible(tester, find.text('독서'));
    expect(find.widgetWithText(TextFormField, '독서'), findsOneWidget);
  });

  group('그룹 삭제', () {
    testWidgets('확인하면 지우고 알린 뒤 목록에서 뺀다', (tester) async {
      await pumpPage(tester);
      await tapVisible(tester, find.bySemanticsLabel('업무 그룹 삭제'));
      expect(find.textContaining('업무 그룹을 삭제하시겠습니까?'), findsOneWidget);
      await tapVisible(tester, find.widgetWithText(FilledButton, '삭제'));

      expect(tags.deletedGroups, ['group-work']);
      expect(find.text('업무 그룹이 삭제되었습니다'), findsOneWidget);
      expect(find.text('집중'), findsNothing);
    });

    testWidgets('취소하면 지우지 않는다', (tester) async {
      await pumpPage(tester);
      await tapVisible(tester, find.bySemanticsLabel('업무 그룹 삭제'));
      await tapVisible(tester, find.widgetWithText(TextButton, '취소'));

      expect(tags.deletedGroups, isEmpty);
      expect(find.text('업무'), findsOneWidget);
    });

    testWidgets('실패하면 오류를 알린다', (tester) async {
      tags.writeError = Exception('서버 오류');
      await pumpPage(tester);
      await tapVisible(tester, find.bySemanticsLabel('업무 그룹 삭제'));
      await tapVisible(tester, find.widgetWithText(FilledButton, '삭제'));

      expect(find.textContaining('그룹 삭제에 실패했습니다'), findsOneWidget);
    });
  });

  group('태그 삭제', () {
    testWidgets('확인하면 지우고 알린 뒤 목록에서 뺀다', (tester) async {
      await pumpPage(tester);
      await tapVisible(tester, find.bySemanticsLabel('공부 태그 삭제'));
      expect(find.textContaining('공부 태그를 삭제하시겠습니까?'), findsOneWidget);
      await tapVisible(tester, find.widgetWithText(FilledButton, '삭제'));

      expect(tags.deletedTags, ['tag-study']);
      expect(find.text('공부 태그가 삭제되었습니다'), findsOneWidget);
      expect(find.bySemanticsLabel('공부 태그 삭제'), findsNothing);
    });

    testWidgets('실패하면 오류를 알린다', (tester) async {
      tags.writeError = Exception('서버 오류');
      await pumpPage(tester);
      await tapVisible(tester, find.bySemanticsLabel('공부 태그 삭제'));
      await tapVisible(tester, find.widgetWithText(FilledButton, '삭제'));

      expect(find.textContaining('태그 삭제에 실패했습니다'), findsOneWidget);
    });
  });

  testWidgets('넓은 줄은 태그 수정·삭제를 이름 오른쪽에, 좁은 줄은 이름 아래에 둔다', (tester) async {
    await pumpPage(tester);
    var name = tester.getRect(find.text('공부'));
    var edit = tester.getRect(find.bySemanticsLabel('공부 태그 수정'));
    expect(edit.top, lessThan(name.bottom));

    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpPage(tester, size: const Size(320, 1600));

    expect(tester.takeException(), isNull);
    name = tester.getRect(find.text('공부'));
    edit = tester.getRect(find.bySemanticsLabel('공부 태그 수정'));
    expect(edit.top, greaterThanOrEqualTo(name.bottom));
  });
}
