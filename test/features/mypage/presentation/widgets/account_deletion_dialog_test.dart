import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/my_profile_provider.dart';
import 'package:momeet/features/mypage/presentation/widgets/account_deletion_dialog.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/kratos_mocks.dart';
import '../../../../helpers/pump_app.dart';

const _acknowledge = '위 내용을 확인했습니다';
const _submit = '탈퇴 신청';

void main() {
  late KratosTestHarness harness;
  late FakeUsersClient users;

  setUpAll(registerKratosFallbacks);

  setUp(() async {
    harness = await KratosTestHarness.create();
    users = FakeUsersClient(consentRequired: false);
    when(() => harness.kratos.logout(any())).thenAnswer((_) async {});
  });

  /// 다이얼로그를 열고 컨테이너를 돌려준다.
  Future<ProviderContainer> open(WidgetTester tester) async {
    await tester.pumpWidget(
      pumpApp(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAccountDeletionDialog(context),
              child: const Text('열기'),
            ),
          ),
        ),
        overrides: [
          ...harness.overrides,
          usersApiProvider.overrideWithValue(users),
        ],
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.text('열기')),
    );
    // 마이페이지에서 열 때처럼 프로필을 받아 둔다
    await container.read(myProfileProvider.future);
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  bool submitEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed != null;

  testWidgets('지워지는 것과 취소할 수 있는 기간, 백업 보관 기간을 알린다', (tester) async {
    await open(tester);

    expect(find.textContaining('바로 로그아웃'), findsOneWidget);
    expect(find.textContaining('다른 사람에게 내 정보가 보이지 않습니다'), findsOneWidget);
    expect(find.textContaining('3일 안에 다시 로그인하면'), findsOneWidget);
    expect(find.textContaining('일정·할 일·타이머·태그·친구·약속'), findsOneWidget);
    expect(find.textContaining('되돌릴 수 없습니다'), findsOneWidget);
    expect(find.textContaining('최대 70일'), findsOneWidget);
  });

  group('확인', () {
    testWidgets('확인했다고 체크해야 신청할 수 있고, 풀면 다시 막힌다', (tester) async {
      await open(tester);
      expect(submitEnabled(tester), isFalse);

      await tester.tap(find.text(_submit));
      await tester.pumpAndSettle();
      expect(users.deletionRequests, 0);

      await tapText(tester, _acknowledge);
      expect(submitEnabled(tester), isTrue);

      await tapText(tester, _acknowledge);
      expect(submitEnabled(tester), isFalse);
    });

    testWidgets('취소하면 신청하지 않고 닫는다', (tester) async {
      final container = await open(tester);
      await tapText(tester, _acknowledge);

      await tapText(tester, '취소');

      expect(find.byType(AccountDeletionDialog), findsNothing);
      expect(users.deletionRequests, 0);
      expect(container.read(isAuthenticatedProvider), isTrue);
    });
  });

  group('신청', () {
    testWidgets('신청하면 로그아웃하고 취소할 수 있는 기간을 알린다', (tester) async {
      final container = await open(tester);
      await tapText(tester, _acknowledge);

      await tapText(tester, _submit);

      expect(users.deletionRequests, 1);
      verify(() => harness.kratos.logout(KratosTestHarness.sessionToken));
      expect(container.read(isAuthenticatedProvider), isFalse);
      expect(find.byType(AccountDeletionDialog), findsNothing);
      expect(find.textContaining('탈퇴를 신청했습니다'), findsOneWidget);
    });

    testWidgets('보내는 중에는 다시 보내거나 닫거나 체크를 풀 수 없다', (tester) async {
      final gate = Completer<void>();
      users.deletionGate = gate.future;
      await open(tester);
      await tapText(tester, _acknowledge);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(submitEnabled(tester), isFalse);
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.tap(find.text('취소'), warnIfMissed: false);
      await tester.tap(find.text(_acknowledge), warnIfMissed: false);
      await tester.pump();
      expect(find.byType(AccountDeletionDialog), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();

      expect(users.deletionRequests, 1);
      verify(() => harness.kratos.logout(any())).called(1);
    });

    testWidgets('이미 신청한 계정이어도 그대로 로그아웃한다', (tester) async {
      users = FakeUsersClient(consentRequired: false, deletionPending: true);
      final requestedAt = users.profile.deletionRequestedAt;
      final container = await open(tester);
      await tapText(tester, _acknowledge);

      await tapText(tester, _submit);

      expect(users.profile.deletionRequestedAt, requestedAt);
      expect(container.read(isAuthenticatedProvider), isFalse);
    });
  });

  group('실패', () {
    testWidgets('신청이 실패하면 알리고 로그인한 채로 다시 시도할 수 있다', (tester) async {
      users.deletionError = httpError('/v1/users/me/deletion', 500);
      final container = await open(tester);
      await tapText(tester, _acknowledge);

      await tapText(tester, _submit);

      expect(find.textContaining('탈퇴 신청에 실패했습니다'), findsOneWidget);
      expect(find.byType(AccountDeletionDialog), findsOneWidget);
      expect(container.read(isAuthenticatedProvider), isTrue);
      expect(container.read(deletionPendingProvider), isFalse);
      verifyNever(() => harness.kratos.logout(any()));
      expect(submitEnabled(tester), isTrue);

      users.deletionError = null;
      await tapText(tester, _submit);
      expect(users.deletionRequests, 2);
      expect(container.read(isAuthenticatedProvider), isFalse);
    });

    testWidgets('신청한 뒤 로그아웃하지 못하면 알리고 탈퇴 대기 상태가 된다', (tester) async {
      when(
        () => harness.kratos.logout(any()),
      ).thenThrow(httpError('/self-service/logout/api', 500));
      final container = await open(tester);
      await tapText(tester, _acknowledge);

      await tapText(tester, _submit);

      expect(find.textContaining('로그아웃하지 못했습니다'), findsOneWidget);
      expect(container.read(isAuthenticatedProvider), isTrue);
      expect(container.read(deletionPendingProvider), isTrue);
      expect(find.byType(AccountDeletionDialog), findsNothing);
    });
  });
}
