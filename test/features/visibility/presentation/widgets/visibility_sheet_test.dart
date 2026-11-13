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
    VisibilityLevel.allowedEmails,
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

    testWidgets('비공개로 바꾸면 설정을 지운다(DELETE)', (tester) async {
      client.put(
        ResourceType.schedule,
        's-1',
        const VisibilityUpdate(
          level: VisibilityLevel.allowedEmails,
          allowedEmails: ['a@x.com'],
        ),
      );

      await open(tester);
      await choose(tester, '비공개');
      await tapInSheet(tester, saveButton());

      expect(client.calls, ['get:schedule/s-1', 'delete:schedule/s-1']);
      expect(client.saved, isEmpty);
      expect(savedCount, 1);
    });

    testWidgets('지금 설정을 읽지 못하면 알리고 다시 시도로 읽는다', (tester) async {
      client.readError = Exception('네트워크 오류');

      await open(tester);
      expect(find.text('공유 설정을 불러오지 못했습니다'), findsOneWidget);
      expect(saveButton(), findsNothing);

      client.readError = null;
      await tapInSheet(tester, find.widgetWithText(FilledButton, '다시 시도'));

      expect(find.text('저장하면 나만 볼 수 있습니다'), findsOneWidget);
      expect(client.calls, ['get:schedule/s-1', 'get:schedule/s-1']);
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

  group('이메일·도메인 허용', () {
    Finder field() => find.widgetWithText(TextField, '이메일 또는 도메인');

    Future<void> enter(WidgetTester tester, String text) async {
      await choose(tester, '이메일·도메인 허용');
      await tester.ensureVisible(field());
      await tester.enterText(field(), text);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    testWidgets('고르면 입력 칸을 보이고, 비어 있으면 나만 본다고 알리되 저장은 할 수 있다', (tester) async {
      await open(tester);
      expect(field(), findsNothing);
      expect(
        find.descendant(
          of: find.widgetWithText(RadioListTile<VisibilityLevel>, '이메일·도메인 허용'),
          matching: find.text('친구가 아니어도 적은 이메일·도메인의 사용자'),
        ),
        findsOneWidget,
      );

      await choose(tester, '이메일·도메인 허용');

      expect(field(), findsOneWidget);
      expect(find.text('허용할 이메일이나 도메인이 없어 저장해도 나만 볼 수 있습니다'), findsOneWidget);
      expect(canSave(tester), isTrue);

      await tapInSheet(tester, saveButton());
      expect(client.saved, [
        const VisibilityUpdate(
          level: VisibilityLevel.allowedEmails,
          allowedEmails: [],
          allowedDomains: [],
        ),
      ]);
    });

    testWidgets('넣은 이메일·도메인을 정리해 보이고 그 목록만 보낸다', (tester) async {
      await open(tester);
      await enter(tester, ' Kim@Partner.com, @Company.com ');

      expect(find.text('kim@partner.com'), findsOneWidget);
      expect(find.text('company.com'), findsOneWidget);
      expect(tester.widget<TextField>(field()).controller!.text, isEmpty);
      expect(
        find.text('저장하면 이메일 인증을 마친 사용자 중 이메일 1개·도메인 1개에 해당하는 사람이 볼 수 있습니다'),
        findsOneWidget,
      );

      await tapInSheet(tester, saveButton());

      expect(client.saved, [
        const VisibilityUpdate(
          level: VisibilityLevel.allowedEmails,
          allowedEmails: ['kim@partner.com'],
          allowedDomains: ['company.com'],
        ),
      ]);
      expect(sheet(), findsNothing);
    });

    testWidgets('추가 버튼으로도 넣는다', (tester) async {
      await open(tester);
      await choose(tester, '이메일·도메인 허용');
      await tester.enterText(field(), 'a@x.com');
      await tapInSheet(tester, find.byTooltip('추가'));

      expect(find.text('a@x.com'), findsOneWidget);
      expect(
        find.text('저장하면 이메일 인증을 마친 사용자 중 이메일 1개에 해당하는 사람이 볼 수 있습니다'),
        findsOneWidget,
      );
    });

    testWidgets('형식이 틀린 것은 알리고 칸에 남기며, 맞는 것은 넣는다', (tester) async {
      await open(tester);
      await enter(tester, 'ok@x.com, nope, 김철수');

      expect(find.text('ok@x.com'), findsOneWidget);
      expect(find.text('이메일이나 도메인 형식이 아닙니다: nope, 김철수'), findsOneWidget);
      expect(tester.widget<TextField>(field()).controller!.text, 'nope, 김철수');

      // 고치면 알림을 지운다
      await tester.enterText(field(), 'x.org');
      await tester.pumpAndSettle();
      expect(find.textContaining('형식이 아닙니다'), findsNothing);
    });

    testWidgets('이미 넣은 것은 알리고 다시 넣지 않는다', (tester) async {
      await open(tester);
      await enter(tester, 'a@x.com');
      await tester.enterText(field(), 'A@X.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('이미 넣었습니다: A@X.com'), findsOneWidget);
      expect(find.text('a@x.com'), findsOneWidget);
    });

    testWidgets('뺄 수 있다', (tester) async {
      await open(tester);
      await enter(tester, 'a@x.com x.com');
      await tapInSheet(tester, find.byTooltip('a@x.com 빼기'));

      expect(find.text('a@x.com'), findsNothing);
      expect(find.text('x.com'), findsOneWidget);
    });

    testWidgets('저장된 목록을 읽어 보인다', (tester) async {
      client.put(
        ResourceType.schedule,
        's-1',
        const VisibilityUpdate(
          level: VisibilityLevel.allowedEmails,
          allowedEmails: ['kim@partner.com'],
          allowedDomains: ['company.com'],
        ),
      );

      await open(tester);

      expect(field(), findsOneWidget);
      expect(find.text('kim@partner.com'), findsOneWidget);
      expect(find.text('company.com'), findsOneWidget);
    });

    testWidgets('칸에 남은 맞는 입력은 저장할 때 함께 넣는다', (tester) async {
      await open(tester);
      await enter(tester, 'a@x.com');
      await tester.enterText(field(), 'b.com');
      await tapInSheet(tester, saveButton());

      expect(client.saved.single.allowedEmails, ['a@x.com']);
      expect(client.saved.single.allowedDomains, ['b.com']);
    });

    testWidgets('칸에 틀린 입력이 남아 있으면 저장하지 않고 알린다', (tester) async {
      await open(tester);
      await enter(tester, 'a@x.com');
      await tester.enterText(field(), 'nope');
      await tapInSheet(tester, saveButton());

      expect(client.saved, isEmpty);
      expect(sheet(), findsOneWidget);
      expect(find.text('이메일이나 도메인 형식이 아닙니다: nope'), findsOneWidget);
    });

    testWidgets('다른 범위로 바꿔 저장하면 이메일 목록은 보내지 않는다', (tester) async {
      await open(tester);
      await enter(tester, 'a@x.com');
      await choose(tester, '선택한 친구');
      await tapInSheet(tester, find.widgetWithText(CheckboxListTile, '영희'));
      await tapInSheet(tester, saveButton());

      expect(client.saved, [
        const VisibilityUpdate(
          level: VisibilityLevel.selected,
          allowedUserIds: ['friend-1'],
        ),
      ]);
    });

    testWidgets('저장에 실패해도 넣은 목록을 둔 채 머문다', (tester) async {
      client.writeError = Exception('서버 오류');

      await open(tester);
      await enter(tester, 'a@x.com');
      await tapInSheet(tester, saveButton());

      expect(sheet(), findsOneWidget);
      expect(find.text('a@x.com'), findsOneWidget);
    });
  });
}
