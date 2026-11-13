import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/visibility/presentation/widgets/shared_by_text.dart';
import 'package:momeet/shared/providers/friend_providers.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/timer_fixtures.dart';

void main() {
  final friends = [
    makeFriend('friend-1', displayName: '영희'),
    makeFriend('friend-2'),
    makeFriend('friend-3', displayName: ''),
  ];

  test('친구 목록에서 공유한 사람의 이름을 찾는다', () {
    expect(sharedByLabel(friends, 'friend-1'), '영희님이 공유');
  });

  test('이름이 없는 친구면 친구가 공유했다고 한다', () {
    expect(sharedByLabel(friends, 'friend-2'), '친구가 공유');
    expect(sharedByLabel(friends, 'friend-3'), '친구가 공유');
  });

  test('친구가 아니거나 친구 목록을 모르면 공유받았다고만 한다', () {
    expect(sharedByLabel(friends, 'stranger'), '공유받음');
    expect(sharedByLabel(friends, null), '공유받음');
    expect(sharedByLabel(null, 'friend-1'), '공유받음');
  });

  testWidgets('친구 목록을 읽으면 이름을 보인다', (tester) async {
    await tester.pumpWidget(
      pumpApp(
        const SharedByText(ownerId: 'friend-1'),
        overrides: [friendsProvider.overrideWith((ref) async => friends)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('영희님이 공유'), findsOneWidget);
  });

  testWidgets('친구 목록을 읽지 못하면 공유받았다고 보인다', (tester) async {
    await tester.pumpWidget(
      pumpApp(
        const SharedByText(ownerId: 'friend-1'),
        overrides: [
          friendsProvider.overrideWith(
            (ref) => Future.error(Exception('네트워크 오류')),
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('공유받음'), findsOneWidget);
  });
}
