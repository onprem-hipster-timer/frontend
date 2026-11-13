import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/visibility/data/rest_resource_visibility.dart';
import 'package:momeet/features/visibility/presentation/widgets/visibility_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/friend_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/sheet_host.dart';
import '../../../../helpers/timer_fixtures.dart';

/// 일정·할 일이 쓰는 공유 설정 시트. 타이머 쪽 기본 동작은 timer_share_sheet_test.dart
void main() {
  final younghee = makeFriend('friend-1', displayName: '영희');
  final chulsoo = makeFriend('friend-2', displayName: '철수');

  const allLevels = [
    VisibilityLevel.private,
    VisibilityLevel.friends,
    VisibilityLevel.selected,
  ];

  late FakeVisibilityClient client;
  late Future<List<FriendRead>> Function() friends;
  late int savedCount;

  setUp(() {
    client = FakeVisibilityClient();
    friends = () async => [younghee, chulsoo];
    savedCount = 0;
  });

  Future<void> open(
    WidgetTester tester, {
    List<VisibilityLevel> levels = allLevels,
  }) async {
    await pumpSheetHost(
      tester,
      open: (context) => showVisibilitySheet(
        context,
        target: RestResourceVisibility(client, ResourceType.schedule, 's-1'),
        levels: levels,
        onSaved: (_) async => savedCount++,
      ),
      overrides: [friendsProvider.overrideWith((ref) => friends())],
    );
    await tester.pumpAndSettle();
  }

  Finder sheet() => find.byType(BottomSheet);
  Finder saveButton() => find.widgetWithText(FilledButton, '저장');

  bool canSave(WidgetTester tester) =>
      tester.widget<FilledButton>(saveButton()).onPressed != null;

  Future<void> tapInSheet(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String label) => tapInSheet(
    tester,
    find.widgetWithText(RadioListTile<VisibilityLevel>, label),
  );

  group('저장하기 전에 볼 수 있는 사람을 알린다', () {
    testWidgets('비공개는 나만 본다', (tester) async {
      await open(tester);

      expect(find.text('저장하면 나만 볼 수 있습니다'), findsOneWidget);
    });

    testWidgets('친구 공개는 친구 모두가 본다', (tester) async {
      await open(tester);
      await choose(tester, '친구 공개');

      expect(find.text('저장하면 내 친구 모두가 볼 수 있습니다'), findsOneWidget);
      expect(find.text('저장하면 나만 볼 수 있습니다'), findsNothing);
    });

    testWidgets('친구가 없으면 친구 공개도 나만 본다고 알리고 저장은 할 수 있다', (tester) async {
      friends = () async => [];

      await open(tester);
      await choose(tester, '친구 공개');

      expect(find.text('아직 친구가 없어 저장해도 나만 볼 수 있습니다'), findsOneWidget);
      expect(canSave(tester), isTrue);
    });

    testWidgets('친구 목록을 읽는 중이거나 못 읽어도 친구 공개는 고를 수 있다', (tester) async {
      final pending = Completer<List<FriendRead>>();
      friends = () => pending.future;

      await open(tester);
      await choose(tester, '친구 공개');

      expect(find.text('저장하면 내 친구 모두가 볼 수 있습니다'), findsOneWidget);
      expect(canSave(tester), isTrue);
    });

    testWidgets('선택한 친구는 고른 친구 수를 세고, 고르기 전에는 고르라고 알린다', (tester) async {
      await open(tester);
      await choose(tester, '선택한 친구');

      expect(find.text('친구를 한 명 이상 고르면 저장할 수 있습니다'), findsOneWidget);

      await tapInSheet(tester, find.widgetWithText(CheckboxListTile, '영희'));
      expect(find.text('저장하면 고른 친구 1명만 볼 수 있습니다'), findsOneWidget);

      await tapInSheet(tester, find.widgetWithText(CheckboxListTile, '철수'));
      expect(find.text('저장하면 고른 친구 2명만 볼 수 있습니다'), findsOneWidget);
    });

    testWidgets('지금 친구가 아닌 사용자는 세지 않는다', (tester) async {
      client.put(
        ResourceType.schedule,
        's-1',
        const VisibilityUpdate(
          level: VisibilityLevel.selected,
          allowedUserIds: ['friend-1', 'former-friend'],
        ),
      );

      await open(tester);

      expect(find.text('저장하면 고른 친구 1명만 볼 수 있습니다'), findsOneWidget);
    });
  });

  group('친구가 없을 때', () {
    testWidgets('선택한 친구는 친구가 아직 없다고 설명하고 저장할 수 없다', (tester) async {
      friends = () async => [];

      await open(tester);
      await choose(tester, '선택한 친구');

      expect(find.text('친구가 없습니다'), findsOneWidget);
      expect(find.text('친구를 맺으면 여기서 고를 수 있습니다'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(canSave(tester), isFalse);

      // 다른 범위로 돌아갈 수 있다
      await choose(tester, '비공개');
      expect(canSave(tester), isTrue);
    });
  });

  group('저장', () {
    testWidgets('받은 선택지만 이 순서로 보인다', (tester) async {
      await open(
        tester,
        levels: const [VisibilityLevel.friends, VisibilityLevel.private],
      );

      expect(
        tester
            .widgetList<RadioListTile<VisibilityLevel>>(
              find.byType(RadioListTile<VisibilityLevel>),
            )
            .map((tile) => tile.value),
        [VisibilityLevel.friends, VisibilityLevel.private],
      );
    });

    testWidgets('저장하면 닫고 알린 뒤 반영한다', (tester) async {
      await open(tester);
      await choose(tester, '친구 공개');
      await tapInSheet(tester, saveButton());

      expect(client.calls, ['get:schedule/s-1', 'put:schedule/s-1']);
      expect(client.saved, [
        const VisibilityUpdate(level: VisibilityLevel.friends),
      ]);
      expect(sheet(), findsNothing);
      expect(find.text('공유 설정을 저장했습니다'), findsOneWidget);
      expect(savedCount, 1);
    });

    testWidgets('실패하면 반영하지 않고 고른 값을 둔 채 머문다', (tester) async {
      client.writeError = Exception('서버 오류');

      await open(tester);
      await choose(tester, '친구 공개');
      await tapInSheet(tester, saveButton());

      expect(sheet(), findsOneWidget);
      expect(find.text('저장하면 내 친구 모두가 볼 수 있습니다'), findsOneWidget);
      expect(savedCount, 0);
    });
  });
}
