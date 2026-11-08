import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_share_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/friend_providers.dart';

import '../../../../helpers/fake_timer_repository.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/timer_fixtures.dart';

void main() {
  final timer = makeTimer(id: 'timer-1', status: TimerStatus.running);
  final younghee = makeFriend('friend-1', displayName: '영희');
  final unnamed = makeFriend('friend-2');

  late FakeTimerRepository repository;
  late Future<List<FriendRead>> Function() friends;

  setUp(() {
    repository = FakeTimerRepository()..getOne = (timerId) async => timer;
    friends = () async => [younghee, unnamed];
  });

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

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.text('열기')));

  Finder sheet() => find.byType(BottomSheet);
  Finder radios() => find.byType(RadioGroup<VisibilityLevel>);
  Finder saveButton() => find.widgetWithText(FilledButton, '저장');
  Finder emailField() => find.widgetWithText(TextField, '이메일');
  Finder domainField() => find.widgetWithText(TextField, '도메인');
  Finder chip(String label) => find.widgetWithText(InputChip, label);

  VisibilityLevel? chosen(WidgetTester tester) =>
      tester.widget<RadioGroup<VisibilityLevel>>(radios()).groupValue;

  bool canSave(WidgetTester tester) =>
      tester.widget<FilledButton>(saveButton()).onPressed != null;

  bool checked(WidgetTester tester, String name) =>
      tester
          .widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, name))
          .value ??
      false;

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
    await tester.enterText(field, text);
    await tapInSheet(tester, find.byTooltip(tooltip));
  }

  group('지금 설정', () {
    testWidgets('읽는 동안 진행 표시를 두고, 설정이 없으면 비공개를 고른다', (tester) async {
      final loaded = Completer<VisibilityRead?>();
      repository.visibilityOf = (_) => loaded.future;

      await open(tester, settle: false);

      expect(
        find.descendant(
          of: sheet(),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(radios(), findsNothing);

      loaded.complete(null);
      await tester.pumpAndSettle();

      expect(chosen(tester), VisibilityLevel.private);
      for (final (label, description) in [
        ('비공개', '나만 봄'),
        ('친구 공개', '모든 친구'),
        ('선택한 친구', '고른 친구만'),
        ('이메일·도메인 지정', '인증된 이메일이 맞는 사용자만'),
        ('전체 공개', '로그인한 모든 사용자'),
      ]) {
        final option = find.widgetWithText(
          RadioListTile<VisibilityLevel>,
          label,
        );
        expect(
          find.descendant(of: option, matching: find.text(description)),
          findsOneWidget,
          reason: label,
        );
      }
      expect(repository.calls, ['visibility:timer-1']);
    });

    testWidgets('저장된 범위를 고른 상태로 연다', (tester) async {
      repository.visibilityOf = (_) async =>
          makeVisibility(level: VisibilityLevel.public);

      await open(tester);

      expect(chosen(tester), VisibilityLevel.public);
    });

    testWidgets('선택한 친구는 저장된 친구에 체크한 채 연다', (tester) async {
      repository.visibilityOf = (_) async => makeVisibility(
        level: VisibilityLevel.selected,
        allowedUserIds: ['friend-2'],
      );

      await open(tester);

      expect(chosen(tester), VisibilityLevel.selected);
      expect(checked(tester, '영희'), isFalse);
      expect(checked(tester, '이름 없는 친구'), isTrue);
      expect(canSave(tester), isTrue);
    });

    testWidgets('이메일·도메인 지정은 저장된 항목을 칩으로 연다', (tester) async {
      repository.visibilityOf = (_) async => makeVisibility(
        level: VisibilityLevel.allowedEmails,
        allowedEmails: ['kim@example.com'],
        allowedDomains: ['example.org'],
      );

      await open(tester);

      expect(chosen(tester), VisibilityLevel.allowedEmails);
      expect(chip('kim@example.com'), findsOneWidget);
      expect(chip('example.org'), findsOneWidget);
    });

    testWidgets('읽지 못하면 알리고 다시 시도로 읽는다', (tester) async {
      var reads = 0;
      repository.visibilityOf = (_) async {
        reads++;
        if (reads == 1) throw Exception('네트워크 오류');
        return makeVisibility(level: VisibilityLevel.friends);
      };

      await open(tester);

      expect(find.text('공유 설정을 불러오지 못했습니다'), findsOneWidget);
      expect(radios(), findsNothing);
      expect(saveButton(), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, '다시 시도'));
      await tester.pumpAndSettle();

      expect(reads, 2);
      expect(find.text('공유 설정을 불러오지 못했습니다'), findsNothing);
      expect(chosen(tester), VisibilityLevel.friends);
    });
  });

  group('저장', () {
    for (final (label, level) in [
      ('친구 공개', VisibilityLevel.friends),
      ('전체 공개', VisibilityLevel.public),
    ]) {
      testWidgets('$label는 목록 없이 PUT으로 보내고 시트를 닫는다', (tester) async {
        await open(tester);
        await choose(tester, label);
        expect(canSave(tester), isTrue);

        await save(tester);

        expect(repository.visibilityUpdate, VisibilityUpdate(level: level));
        expect(repository.calls, [
          'visibility:timer-1',
          'setVisibility:timer-1',
          'get:timer-1',
        ]);
        expect(sheet(), findsNothing);
        expect(find.text('공유 설정을 저장했습니다'), findsOneWidget);
      });
    }

    testWidgets('비공개는 설정을 지운다', (tester) async {
      repository.visibilityOf = (_) async =>
          makeVisibility(level: VisibilityLevel.friends);

      await open(tester);
      await choose(tester, '비공개');
      await save(tester);

      expect(repository.calls, [
        'visibility:timer-1',
        'clearVisibility:timer-1',
        'get:timer-1',
      ]);
      expect(repository.visibilityUpdate, isNull);
      expect(sheet(), findsNothing);
      expect(find.text('공유 설정을 저장했습니다'), findsOneWidget);
    });

    testWidgets('저장한 뒤 다시 읽은 타이머를 목록보다 먼저 보일 값으로 둔다', (tester) async {
      repository.getOne = (timerId) async =>
          timer.copyWith(visibilityLevel: VisibilityLevel.friends);

      await open(tester);
      await choose(tester, '친구 공개');
      await save(tester);

      expect(
        container(tester).read(timerViewsProvider)['timer-1']?.visibilityLevel,
        VisibilityLevel.friends,
      );
    });

    testWidgets('실패하면 알리고 고른 값을 둔 채 머문다', (tester) async {
      repository.error = Exception('서버 오류');

      await open(tester);
      await choose(tester, '이메일·도메인 지정');
      await addEntry(tester, domainField(), 'example.org', '도메인 추가');
      await save(tester);

      expect(find.text('공유 설정 저장 실패: Exception: 서버 오류'), findsOneWidget);
      expect(sheet(), findsOneWidget);
      expect(chosen(tester), VisibilityLevel.allowedEmails);
      expect(chip('example.org'), findsOneWidget);
      expect(canSave(tester), isTrue);
      expect(repository.calls, isNot(contains('get:timer-1')));
    });

    testWidgets('저장하는 동안 진행 표시를 두고, 그사이 시트를 닫아도 결과를 알리고 반영한다', (tester) async {
      final saved = Completer<void>();
      repository
        ..gate = saved.future
        ..getOne = (timerId) async =>
            timer.copyWith(visibilityLevel: VisibilityLevel.public);

      await open(tester);
      await choose(tester, '전체 공개');
      await tester.tap(saveButton());
      await tester.pump();

      final button = find.byType(FilledButton);
      expect(
        find.descendant(
          of: button,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      // 시트 밖을 눌러 닫는다
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(sheet(), findsNothing);

      saved.complete();
      await tester.pumpAndSettle();

      expect(find.text('공유 설정을 저장했습니다'), findsOneWidget);
      expect(
        container(tester).read(timerViewsProvider)['timer-1']?.visibilityLevel,
        VisibilityLevel.public,
      );
    });
  });

  group('선택한 친구', () {
    testWidgets('친구를 하나 이상 골라야 저장하고 고른 친구만 보낸다', (tester) async {
      await open(tester);
      await choose(tester, '선택한 친구');

      expect(find.text('영희'), findsOneWidget);
      expect(find.text('이름 없는 친구'), findsOneWidget);
      expect(canSave(tester), isFalse);

      await tapInSheet(tester, find.widgetWithText(CheckboxListTile, '영희'));
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

    testWidgets('고른 친구를 모두 풀면 저장할 수 없다', (tester) async {
      await open(tester);
      await choose(tester, '선택한 친구');
      await tapInSheet(tester, find.widgetWithText(CheckboxListTile, '영희'));
      await tapInSheet(tester, find.widgetWithText(CheckboxListTile, '영희'));

      expect(checked(tester, '영희'), isFalse);
      expect(canSave(tester), isFalse);
    });

    testWidgets('친구가 없으면 알리고 저장할 수 없다', (tester) async {
      friends = () async => [];

      await open(tester);
      await choose(tester, '선택한 친구');

      expect(find.text('친구가 없습니다'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(canSave(tester), isFalse);
    });

    testWidgets('지금 친구가 아닌 사용자는 보내지 않는다', (tester) async {
      repository.visibilityOf = (_) async => makeVisibility(
        level: VisibilityLevel.selected,
        allowedUserIds: ['friend-1', 'former-friend'],
      );

      await open(tester);
      await save(tester);

      expect(
        repository.visibilityUpdate,
        const VisibilityUpdate(
          level: VisibilityLevel.selected,
          allowedUserIds: ['friend-1'],
        ),
      );
    });

    testWidgets('친구 목록을 끝내 읽지 못하면 알리고 다시 시도로 읽는다', (tester) async {
      var failing = true;
      friends = () async {
        if (failing) throw Exception('네트워크 오류');
        return [younghee];
      };

      await open(tester);
      await tester.tap(
        find.widgetWithText(RadioListTile<VisibilityLevel>, '선택한 친구'),
      );
      // 다시 읽는 동안은 진행 표시, 자동 재시도가 끝나면 오류를 보인다
      await tester.pump();
      expect(
        find.descendant(
          of: sheet(),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(seconds: 7));
      }
      await tester.pumpAndSettle();

      expect(find.text('친구 목록을 불러오지 못했습니다'), findsOneWidget);
      expect(canSave(tester), isFalse);

      failing = false;
      await tapInSheet(tester, find.widgetWithText(TextButton, '다시 시도'));

      expect(find.text('친구 목록을 불러오지 못했습니다'), findsNothing);
      expect(find.text('영희'), findsOneWidget);
    });
  });

  group('이메일·도메인 지정', () {
    testWidgets('형식에 맞는 이메일만 칩으로 더하고 대소문자만 다른 같은 이메일은 무시한다', (tester) async {
      await open(tester);
      await choose(tester, '이메일·도메인 지정');
      expect(canSave(tester), isFalse);

      for (final invalid in [
        'kim',
        'kim@example',
        '@example.com',
        'k m@a.com',
      ]) {
        await addEntry(tester, emailField(), invalid, '이메일 추가');

        expect(find.text('이메일 형식이 아닙니다'), findsOneWidget, reason: invalid);
        expect(find.byType(InputChip), findsNothing, reason: invalid);
        expect(canSave(tester), isFalse, reason: invalid);
      }

      await addEntry(tester, emailField(), ' Kim@Example.com ', '이메일 추가');

      expect(find.text('이메일 형식이 아닙니다'), findsNothing);
      expect(chip('Kim@Example.com'), findsOneWidget);
      expect(canSave(tester), isTrue);

      // 키보드의 완료로도 더한다
      await tester.enterText(emailField(), 'kim@example.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(emailField()).controller!.text, isEmpty);
      expect(find.byType(InputChip), findsOneWidget);
    });

    testWidgets('도메인은 @ 없이 점이 있어야 더한다', (tester) async {
      await open(tester);
      await choose(tester, '이메일·도메인 지정');

      for (final invalid in ['example', '@example.com', 'kim@example.com']) {
        await addEntry(tester, domainField(), invalid, '도메인 추가');

        expect(
          find.text('도메인 형식이 아닙니다 (예: example.com)'),
          findsOneWidget,
          reason: invalid,
        );
        expect(find.byType(InputChip), findsNothing, reason: invalid);
      }

      await addEntry(tester, domainField(), 'example.org', '도메인 추가');
      await addEntry(tester, domainField(), 'EXAMPLE.ORG', '도메인 추가');

      expect(chip('example.org'), findsOneWidget);
      expect(find.byType(InputChip), findsOneWidget);
    });

    testWidgets('고치기 시작하면 형식 오류를 지운다', (tester) async {
      await open(tester);
      await choose(tester, '이메일·도메인 지정');
      await addEntry(tester, emailField(), 'kim', '이메일 추가');
      expect(find.text('이메일 형식이 아닙니다'), findsOneWidget);

      await tester.enterText(emailField(), 'kim@');
      await tester.pump();

      expect(find.text('이메일 형식이 아닙니다'), findsNothing);
    });

    testWidgets('이메일과 도메인을 보내고 다른 범위의 목록은 보내지 않는다', (tester) async {
      repository.visibilityOf = (_) async => makeVisibility(
        level: VisibilityLevel.selected,
        allowedUserIds: ['friend-1'],
      );

      await open(tester);
      await choose(tester, '이메일·도메인 지정');
      await addEntry(tester, emailField(), 'kim@example.com', '이메일 추가');
      await addEntry(tester, emailField(), 'lee@example.com', '이메일 추가');
      await addEntry(tester, domainField(), 'example.org', '도메인 추가');
      // 칩을 지우면 보내지 않는다
      await tapInSheet(
        tester,
        find.descendant(
          of: chip('lee@example.com'),
          matching: find.byIcon(Icons.clear),
        ),
      );
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

    testWidgets('도메인만 있어도 저장한다', (tester) async {
      await open(tester);
      await choose(tester, '이메일·도메인 지정');
      await addEntry(tester, domainField(), 'example.org', '도메인 추가');
      await save(tester);

      expect(
        repository.visibilityUpdate,
        const VisibilityUpdate(
          level: VisibilityLevel.allowedEmails,
          allowedEmails: [],
          allowedDomains: ['example.org'],
        ),
      );
    });
  });

  group('공유 범위 아이콘', () {
    test('범위마다 아이콘이 다르고 설정이 없으면 비공개 아이콘이다', () {
      expect(visibilityLevelIcon(null), Icons.lock_outline);
      expect(visibilityLevelIcon(VisibilityLevel.private), Icons.lock_outline);
      expect(
        visibilityLevelIcon(VisibilityLevel.friends),
        Icons.group_outlined,
      );
      expect(
        visibilityLevelIcon(VisibilityLevel.selected),
        Icons.how_to_reg_outlined,
      );
      expect(
        visibilityLevelIcon(VisibilityLevel.allowedEmails),
        Icons.alternate_email,
      );
      expect(visibilityLevelIcon(VisibilityLevel.public), Icons.public);
    });
  });
}
