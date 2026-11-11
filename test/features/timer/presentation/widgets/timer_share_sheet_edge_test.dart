import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_share_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/friend_providers.dart';

import '../../../../helpers/fake_timer_repository.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/timer_fixtures.dart';

/// 타이머 공유 설정 시트의 경계. 기본 동작은 timer_share_sheet_test.dart
void main() {
  final timer = makeTimer(id: 'timer-1', status: TimerStatus.running);
  final younghee = makeFriend('friend-1', displayName: '영희');
  final chulsoo = makeFriend('friend-2', displayName: '철수');

  late FakeTimerRepository repository;
  late Future<List<FriendRead>> Function() friends;

  setUp(() {
    repository = FakeTimerRepository()..getOne = (timerId) async => timer;
    friends = () async => [younghee, chulsoo];
  });

  void setSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// 버튼으로 [timer]의 공유 설정 시트를 연다. [settle]이 false면 여는 애니메이션만 기다린다
  Future<void> open(WidgetTester tester, {bool settle = true}) async {
    await tester.pumpWidget(
      pumpApp(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showTimerShareSheet(context, timer: timer),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
        overrides: [
          timerRepositoryProvider.overrideWithValue(repository),
          friendsProvider.overrideWith((ref) => friends()),
        ],
      ),
    );
    await tester.tap(find.text('열기'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }
  }

  Finder sheet() => find.byType(BottomSheet);
  Finder radios() => find.byType(RadioGroup<VisibilityLevel>);
  Finder saveButton() => find.widgetWithText(FilledButton, '저장');
  Finder friendTile(String name) => find.widgetWithText(CheckboxListTile, name);
  Finder progress() => find.descendant(
    of: sheet(),
    matching: find.byType(CircularProgressIndicator),
  );

  VisibilityLevel? chosen(WidgetTester tester) =>
      tester.widget<RadioGroup<VisibilityLevel>>(radios()).groupValue;

  bool canSave(WidgetTester tester) =>
      tester.widget<FilledButton>(saveButton()).onPressed != null;

  bool checked(WidgetTester tester, String name) =>
      tester.widget<CheckboxListTile>(friendTile(name)).value ?? false;

  Iterable<String> saves() => repository.calls.where(
    (call) =>
        call.startsWith('setVisibility') || call.startsWith('clearVisibility'),
  );

  /// 시트를 스크롤해 [finder]가 보이게 한 뒤 누른다
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

  Future<void> save(WidgetTester tester) => tapInSheet(tester, saveButton());

  group('저장하는 동안', () {
    testWidgets('저장을 연달아 눌러도 한 번만 보낸다', (tester) async {
      final saved = Completer<void>();
      repository.gate = saved.future;

      await open(tester);
      await choose(tester, '친구 공개');
      await tester.ensureVisible(saveButton());
      await tester.pumpAndSettle();
      // 다시 그리기 전에 두 번 누른다
      await tester.tap(saveButton());
      await tester.tap(saveButton(), warnIfMissed: false);
      await tester.pump();
      // 진행 표시 중에도 한 번 더 누른다
      await tester.tap(
        find.descendant(of: sheet(), matching: find.byType(FilledButton)),
        warnIfMissed: false,
      );
      await tester.pump();
      saved.complete();
      await tester.pumpAndSettle();

      expect(saves(), ['setVisibility:timer-1']);
      expect(sheet(), findsNothing);
      expect(find.text('열기'), findsOneWidget);
      expect(find.text('공유 설정을 저장했습니다'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('시트가 닫히는 중에 저장 응답이 와도 시트 아래 화면은 닫지 않는다', (tester) async {
      final saved = Completer<void>();
      repository.gate = saved.future;

      await open(tester);
      await choose(tester, '친구 공개');
      await tester.ensureVisible(saveButton());
      await tester.pumpAndSettle();
      await tester.tap(saveButton());
      await tester.pump();
      await tester.binding.handlePopRoute();
      // 닫는 애니메이션이 끝나기 전에 응답이 온다
      await tester.pump(const Duration(milliseconds: 50));
      expect(sheet(), findsOneWidget);
      saved.complete();
      await tester.pumpAndSettle();

      expect(sheet(), findsNothing);
      expect(find.text('열기'), findsOneWidget);
      expect(find.text('공유 설정을 저장했습니다'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('실패와 회복', () {
    // 할 일·태그·일정 폼 시트와 같이 실패 SnackBar는 시트 안이 아니라 화면 Scaffold에 띄운다.
    // 시트가 화면 아래를 덮는 좁은 화면에서는 SnackBar가 시트에 가린다
    testWidgets('저장에 실패하면 다른 폼 시트처럼 화면의 SnackBar로 알리고 시트는 연 채 둔다', (
      tester,
    ) async {
      setSize(tester, const Size(360, 800));
      repository.error = Exception('서버 오류');

      await open(tester);
      await choose(tester, '친구 공개');
      await save(tester);

      final failure = find.text('공유 설정 저장 실패: Exception: 서버 오류');
      expect(failure, findsOneWidget);
      expect(sheet(), findsOneWidget);
      expect(find.descendant(of: sheet(), matching: failure), findsNothing);
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('열기'),
            matching: find.byType(Scaffold),
          ),
          matching: find.byType(SnackBar),
        ),
        findsOneWidget,
      );
    });

    testWidgets('실패한 뒤 다시 저장하면 보내고 시트를 닫는다', (tester) async {
      repository.error = Exception('서버 오류');

      await open(tester);
      await choose(tester, '친구 공개');
      await save(tester);
      expect(sheet(), findsOneWidget);

      repository.error = null;
      await save(tester);

      expect(saves(), ['setVisibility:timer-1', 'setVisibility:timer-1']);
      expect(
        repository.visibilityUpdate,
        const VisibilityUpdate(level: VisibilityLevel.friends),
      );
      expect(sheet(), findsNothing);
      expect(find.text('공유 설정을 저장했습니다'), findsOneWidget);
    });

    testWidgets('저장하는 동안 뒤로 가기로 닫고 실패하면 실패를 알린다', (tester) async {
      final saved = Completer<void>();
      repository
        ..gate = saved.future
        ..error = Exception('서버 오류');

      await open(tester);
      await choose(tester, '친구 공개');
      await tester.ensureVisible(saveButton());
      await tester.pumpAndSettle();
      await tester.tap(saveButton());
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(sheet(), findsNothing);

      saved.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('열기'), findsOneWidget);
      expect(find.text('공유 설정 저장 실패: Exception: 서버 오류'), findsOneWidget);
      expect(find.text('공유 설정을 저장했습니다'), findsNothing);
      expect(repository.calls, isNot(contains('get:timer-1')));
    });

    testWidgets('저장은 됐는데 타이머를 다시 읽지 못해도 저장했다고 알리고 시트를 닫는다', (tester) async {
      repository.getOne = (timerId) async => throw Exception('네트워크 오류');

      await open(tester);
      await choose(tester, '친구 공개');
      await save(tester);

      expect(repository.calls, [
        'visibility:timer-1',
        'setVisibility:timer-1',
        'get:timer-1',
      ]);
      expect(sheet(), findsNothing);
      expect(find.text('공유 설정을 저장했습니다'), findsOneWidget);
      expect(find.textContaining('공유 설정 저장 실패'), findsNothing);
    });

    testWidgets('다시 시도를 연달아 눌러도 한 번만 읽고 항목을 겹쳐 두지 않는다', (tester) async {
      var reads = 0;
      repository.visibilityOf = (_) async {
        reads++;
        if (reads == 1) throw Exception('네트워크 오류');
        return makeVisibility(
          level: VisibilityLevel.selected,
          allowedUserIds: ['friend-1'],
        );
      };

      await open(tester);
      final retry = find.widgetWithText(FilledButton, '다시 시도');
      // 다시 그리기 전에 두 번 누른다
      await tester.tap(retry);
      await tester.tap(retry, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(reads, 2);
      expect(checked(tester, '영희'), isTrue);
      await save(tester);
      expect(
        repository.visibilityUpdate,
        const VisibilityUpdate(
          level: VisibilityLevel.selected,
          allowedUserIds: ['friend-1'],
        ),
      );
    });

    testWidgets('다시 시도도 실패하면 다시 알리고, 그다음 시도로 읽는다', (tester) async {
      var reads = 0;
      final third = Completer<VisibilityRead?>();
      repository.visibilityOf = (_) {
        reads++;
        if (reads <= 2) return Future.error(Exception('네트워크 오류'));
        return third.future;
      };

      await open(tester);
      expect(find.text('공유 설정을 불러오지 못했습니다'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '다시 시도'));
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(find.text('공유 설정을 불러오지 못했습니다'), findsOneWidget);
      expect(radios(), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, '다시 시도'));
      await tester.pump();
      // 다시 읽는 동안은 오류 대신 진행 표시
      expect(reads, 3);
      expect(progress(), findsOneWidget);
      expect(find.text('공유 설정을 불러오지 못했습니다'), findsNothing);

      third.complete(makeVisibility(level: VisibilityLevel.friends));
      await tester.pumpAndSettle();

      expect(chosen(tester), VisibilityLevel.friends);
      expect(canSave(tester), isTrue);
    });

    for (final fail in [false, true]) {
      testWidgets('불러오는 중에 닫고 나서 ${fail ? '실패해도' : '응답이 와도'} 오류 없이 끝난다', (
        tester,
      ) async {
        final loaded = Completer<VisibilityRead?>();
        repository.visibilityOf = (_) => loaded.future;

        await open(tester, settle: false);
        expect(progress(), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(sheet(), findsNothing);

        if (fail) {
          loaded.completeError(Exception('네트워크 오류'));
        } else {
          loaded.complete(makeVisibility(level: VisibilityLevel.friends));
        }
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('열기'), findsOneWidget);
        expect(repository.calls, ['visibility:timer-1']);
      });
    }
  });

  group('범위 바꾸기', () {
    testWidgets('친구를 고른 뒤 친구 공개로 바꾸면 친구 목록 없이 보낸다', (tester) async {
      await open(tester);
      await choose(tester, '선택한 친구');
      await tapInSheet(tester, friendTile('영희'));
      await choose(tester, '친구 공개');
      await save(tester);

      expect(
        repository.visibilityUpdate,
        const VisibilityUpdate(level: VisibilityLevel.friends),
      );
    });

    testWidgets('설정이 없던 타이머도 비공개로 저장하면 설정을 지운다', (tester) async {
      await open(tester);
      expect(chosen(tester), VisibilityLevel.private);

      await save(tester);

      expect(repository.calls, [
        'visibility:timer-1',
        'clearVisibility:timer-1',
        'get:timer-1',
      ]);
      expect(find.text('공유 설정을 저장했습니다'), findsOneWidget);
    });

    testWidgets('저장한 뒤 다시 열면 다시 읽어 저장한 범위로 연다', (tester) async {
      VisibilityRead? stored;
      repository.visibilityOf = (_) async => stored;

      await open(tester);
      await choose(tester, '선택한 친구');
      await tapInSheet(tester, friendTile('철수'));
      await save(tester);
      stored = makeVisibility(
        level: repository.visibilityUpdate!.level,
        allowedUserIds: repository.visibilityUpdate!.allowedUserIds!,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      expect(
        repository.calls.where((call) => call == 'visibility:timer-1'),
        hasLength(2),
      );
      expect(chosen(tester), VisibilityLevel.selected);
      expect(checked(tester, '철수'), isTrue);
      expect(checked(tester, '영희'), isFalse);
    });
  });

  group('선택한 친구 경계', () {
    testWidgets('친구 목록을 읽는 동안은 저장된 친구가 있어도 저장할 수 없고, 다 읽으면 체크한 채 저장한다', (
      tester,
    ) async {
      final loaded = Completer<List<FriendRead>>();
      friends = () => loaded.future;
      repository.visibilityOf = (_) async => makeVisibility(
        level: VisibilityLevel.selected,
        allowedUserIds: ['friend-1'],
      );

      await open(tester, settle: false);
      await tester.pump();

      expect(chosen(tester), VisibilityLevel.selected);
      expect(canSave(tester), isFalse);
      await tester.tap(saveButton(), warnIfMissed: false);
      await tester.pump();
      expect(saves(), isEmpty);

      loaded.complete([younghee, chulsoo]);
      await tester.pumpAndSettle();

      expect(checked(tester, '영희'), isTrue);
      expect(canSave(tester), isTrue);
      await save(tester);
      expect(
        repository.visibilityUpdate,
        const VisibilityUpdate(
          level: VisibilityLevel.selected,
          allowedUserIds: ['friend-1'],
        ),
      );
    });

    testWidgets('저장된 친구가 모두 지금 친구가 아니면 아무도 고르지 않은 채 열고 저장할 수 없다', (
      tester,
    ) async {
      repository.visibilityOf = (_) async => makeVisibility(
        level: VisibilityLevel.selected,
        allowedUserIds: ['former-friend'],
      );

      await open(tester);

      expect(chosen(tester), VisibilityLevel.selected);
      expect(checked(tester, '영희'), isFalse);
      expect(checked(tester, '철수'), isFalse);
      expect(canSave(tester), isFalse);
    });

    testWidgets('친구가 많아도 낮은 화면에서 마지막 친구까지 굴려 골라 저장한다', (tester) async {
      setSize(tester, const Size(360, 560));
      friends = () async => [
        for (var i = 0; i < 30; i++)
          makeFriend('friend-$i', displayName: '친구 $i'),
      ];

      await open(tester);
      await choose(tester, '선택한 친구');
      await tapInSheet(tester, friendTile('친구 29'));
      await save(tester);

      expect(tester.takeException(), isNull);
      expect(
        repository.visibilityUpdate,
        const VisibilityUpdate(
          level: VisibilityLevel.selected,
          allowedUserIds: ['friend-29'],
        ),
      );
    });
  });

  group('화면 크기', () {
    for (final size in const [
      Size(360, 800),
      Size(360, 560),
      Size(844, 390),
      Size(800, 1280),
      Size(1280, 800),
    ]) {
      testWidgets(
        '${size.width.toInt()}x${size.height.toInt()}에서 모든 범위를 골라도 넘치지 않고 저장한다',
        (tester) async {
          setSize(tester, size);

          await open(tester);
          expect(tester.takeException(), isNull);

          for (final label in ['친구 공개', '비공개', '선택한 친구']) {
            await choose(tester, label);
            expect(tester.takeException(), isNull, reason: label);
          }
          await tapInSheet(tester, friendTile('철수'));
          expect(tester.takeException(), isNull);

          await save(tester);

          expect(tester.takeException(), isNull);
          expect(sheet(), findsNothing);
          expect(
            repository.visibilityUpdate,
            const VisibilityUpdate(
              level: VisibilityLevel.selected,
              allowedUserIds: ['friend-2'],
            ),
          );
        },
      );
    }
  });
}
