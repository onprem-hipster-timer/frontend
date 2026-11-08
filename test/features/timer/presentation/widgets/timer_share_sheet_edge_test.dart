import 'dart:async';

import 'package:flutter/material.dart';
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
  Finder emailField() => find.widgetWithText(TextField, '이메일');
  Finder domainField() => find.widgetWithText(TextField, '도메인');
  Finder chip(String label) => find.widgetWithText(InputChip, label);
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

  /// [field]에 [text]를 적고 [tooltip] 버튼으로 더한다
  Future<void> addEntry(
    WidgetTester tester,
    Finder field,
    String text,
    String tooltip,
  ) async {
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, text);
    await tapInSheet(tester, find.byTooltip(tooltip));
  }

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
      await choose(tester, '전체 공개');
      await save(tester);
      expect(sheet(), findsOneWidget);

      repository.error = null;
      await save(tester);
      // 앞서 띄운 실패 알림이 사라질 때까지 기다린다
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(saves(), ['setVisibility:timer-1', 'setVisibility:timer-1']);
      expect(
        repository.visibilityUpdate,
        const VisibilityUpdate(level: VisibilityLevel.public),
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

      third.complete(makeVisibility(level: VisibilityLevel.public));
      await tester.pumpAndSettle();

      expect(chosen(tester), VisibilityLevel.public);
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

    testWidgets('이메일을 더한 뒤 전체 공개로 바꾸면 목록 없이 보낸다', (tester) async {
      await open(tester);
      await choose(tester, '이메일·도메인 지정');
      await addEntry(tester, emailField(), 'kim@example.com', '이메일 추가');
      await addEntry(tester, domainField(), 'example.org', '도메인 추가');
      await choose(tester, '전체 공개');
      await save(tester);

      expect(
        repository.visibilityUpdate,
        const VisibilityUpdate(level: VisibilityLevel.public),
      );
    });

    testWidgets('저장된 이메일 지정에서 선택한 친구로 바꾸면 고른 친구만 보낸다', (tester) async {
      repository.visibilityOf = (_) async => makeVisibility(
        level: VisibilityLevel.allowedEmails,
        allowedEmails: ['kim@example.com'],
        allowedDomains: ['example.org'],
      );

      await open(tester);
      await choose(tester, '선택한 친구');
      expect(canSave(tester), isFalse);
      await tapInSheet(tester, friendTile('철수'));
      await save(tester);

      expect(
        repository.visibilityUpdate,
        const VisibilityUpdate(
          level: VisibilityLevel.selected,
          allowedUserIds: ['friend-2'],
        ),
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

  group('입력 경계', () {
    testWidgets('빈 칸이나 공백만 넣고 더하면 칩을 만들지 않는다', (tester) async {
      await open(tester);
      await choose(tester, '이메일·도메인 지정');

      for (final (field, tooltip) in [
        (emailField(), '이메일 추가'),
        (domainField(), '도메인 추가'),
      ]) {
        for (final blank in ['', '   ']) {
          await addEntry(tester, field, blank, tooltip);

          expect(find.byType(InputChip), findsNothing, reason: tooltip);
          expect(canSave(tester), isFalse, reason: tooltip);
        }
      }
    });

    testWidgets('도메인 앞뒤 공백은 지우고 더하고, 가운데 공백은 형식 오류다', (tester) async {
      await open(tester);
      await choose(tester, '이메일·도메인 지정');

      await addEntry(tester, domainField(), 'exa mple.com', '도메인 추가');
      expect(find.text('도메인 형식이 아닙니다 (예: example.com)'), findsOneWidget);
      expect(find.byType(InputChip), findsNothing);

      await addEntry(tester, domainField(), '  example.org  ', '도메인 추가');
      expect(chip('example.org'), findsOneWidget);
      expect(find.text('도메인 형식이 아닙니다 (예: example.com)'), findsNothing);
    });

    testWidgets('불러온 항목과 대소문자만 다른 이메일·도메인은 더하지 않는다', (tester) async {
      repository.visibilityOf = (_) async => makeVisibility(
        level: VisibilityLevel.allowedEmails,
        allowedEmails: ['kim@example.com'],
        allowedDomains: ['example.org'],
      );

      await open(tester);
      await addEntry(tester, emailField(), 'KIM@EXAMPLE.COM', '이메일 추가');
      await addEntry(tester, domainField(), 'Example.Org', '도메인 추가');

      expect(find.byType(InputChip), findsNWidgets(2));
      await save(tester);
      expect(
        repository.visibilityUpdate,
        const VisibilityUpdate(
          level: VisibilityLevel.allowedEmails,
          allowedEmails: ['kim@example.com'],
          allowedDomains: ['example.org'],
        ),
      );
    });

    testWidgets('도메인 칸도 키보드의 완료로 더하고 칸을 비운다', (tester) async {
      await open(tester);
      await choose(tester, '이메일·도메인 지정');
      await tester.ensureVisible(domainField());
      await tester.pumpAndSettle();
      await tester.enterText(domainField(), 'example.org');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(chip('example.org'), findsOneWidget);
      expect(tester.widget<TextField>(domainField()).controller!.text, isEmpty);
      expect(canSave(tester), isTrue);
    });

    testWidgets('칩을 모두 지우면 다시 저장할 수 없다', (tester) async {
      repository.visibilityOf = (_) async => makeVisibility(
        level: VisibilityLevel.allowedEmails,
        allowedDomains: ['example.org'],
      );

      await open(tester);
      expect(canSave(tester), isTrue);
      await tapInSheet(
        tester,
        find.descendant(
          of: chip('example.org'),
          matching: find.byIcon(Icons.clear),
        ),
      );

      expect(find.byType(InputChip), findsNothing);
      expect(canSave(tester), isFalse);
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

          for (final label in [
            '친구 공개',
            '선택한 친구',
            '전체 공개',
            '비공개',
            '이메일·도메인 지정',
          ]) {
            await choose(tester, label);
            expect(tester.takeException(), isNull, reason: label);
          }
          await addEntry(
            tester,
            emailField(),
            'a-very-long-address-for-sharing@example-company.co.kr',
            '이메일 추가',
          );
          await addEntry(tester, domainField(), 'example.org', '도메인 추가');
          expect(tester.takeException(), isNull);

          await save(tester);

          expect(tester.takeException(), isNull);
          expect(sheet(), findsNothing);
          expect(
            repository.visibilityUpdate,
            const VisibilityUpdate(
              level: VisibilityLevel.allowedEmails,
              allowedEmails: [
                'a-very-long-address-for-sharing@example-company.co.kr',
              ],
              allowedDomains: ['example.org'],
            ),
          );
        },
      );
    }
  });
}
