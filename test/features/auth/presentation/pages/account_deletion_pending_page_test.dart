import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/my_profile_provider.dart';
import 'package:momeet/features/auth/presentation/pages/account_deletion_pending_page.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/kratos_mocks.dart';
import '../../../../helpers/pump_app.dart';

const _cancel = '탈퇴 취소하고 계속 이용';
const _logout = '로그아웃';

void main() {
  late KratosTestHarness harness;
  late FakeUsersClient users;

  setUpAll(() async {
    registerKratosFallbacks();
    await initializeDateFormatting('ko_KR');
  });

  setUp(() async {
    harness = await KratosTestHarness.create();
    users = FakeUsersClient(consentRequired: false, deletionPending: true);
  });

  Future<ProviderContainer> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      pumpApp(
        const AccountDeletionPendingPage(),
        overrides: [
          ...harness.overrides,
          usersApiProvider.overrideWithValue(users),
        ],
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(AccountDeletionPendingPage)),
    );
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  /// 취소에 성공하면 라우터가 이 화면을 떠나므로 여기서는 불러오기 표시만 남는다
  Future<void> cancelAndLeave(WidgetTester tester) async {
    await tester.tap(find.text(_cancel));
    await tester.pump();
    await tester.pump();
  }

  bool enabled(WidgetTester tester, String text) {
    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text(text),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    return button.onPressed != null;
  }

  testWidgets('취소할 수 있는 기한과, 그 뒤 지워져 되돌릴 수 없다는 것을 알린다', (tester) async {
    await pumpPage(tester);

    // 신청 시각(UTC 11월 11일 03:00)에서 3일 뒤. 어느 시간대에서도 같은 날이다
    expect(find.textContaining('2026년 11월 14일'), findsOneWidget);
    expect(find.textContaining('까지 탈퇴를 취소할 수 있습니다'), findsOneWidget);
    expect(find.textContaining('계정과 모든 데이터가 지워지며'), findsOneWidget);
    expect(find.textContaining('되돌릴 수 없습니다'), findsOneWidget);
    expect(enabled(tester, _cancel), isTrue);
    expect(enabled(tester, _logout), isTrue);
  });

  group('탈퇴 취소', () {
    testWidgets('취소하면 프로필이 탈퇴 대기가 아니게 된다', (tester) async {
      final container = await pumpPage(tester);
      expect(container.read(deletionPendingProvider), isTrue);

      await cancelAndLeave(tester);

      expect(users.deletionCancels, 1);
      expect(container.read(deletionPendingProvider), isFalse);
      expect(container.read(isAuthenticatedProvider), isTrue);
    });

    testWidgets('보내는 중에는 다시 보내거나 로그아웃할 수 없다', (tester) async {
      final gate = Completer<void>();
      users.deletionGate = gate.future;
      await pumpPage(tester);

      await tester.tap(find.text(_cancel));
      await tester.pump();
      expect(enabled(tester, _logout), isFalse);
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();
      gate.complete();
      await tester.pump();

      expect(users.deletionCancels, 1);
    });

    testWidgets('실패하면 알리고 탈퇴 대기 그대로 다시 시도할 수 있다', (tester) async {
      users.deletionError = httpError('/v1/users/me/deletion', 500);
      final container = await pumpPage(tester);

      await tapText(tester, _cancel);

      expect(find.textContaining('탈퇴 취소에 실패했습니다'), findsOneWidget);
      expect(container.read(deletionPendingProvider), isTrue);
      expect(enabled(tester, _cancel), isTrue);

      users.deletionError = null;
      await cancelAndLeave(tester);
      expect(users.deletionCancels, 2);
      expect(container.read(deletionPendingProvider), isFalse);
    });
  });

  group('로그아웃', () {
    testWidgets('누르면 탈퇴를 취소하지 않고 로그아웃한다', (tester) async {
      when(() => harness.kratos.logout(any())).thenAnswer((_) async {});
      final container = await pumpPage(tester);

      await tester.tap(find.text(_logout));
      await tester.pump();
      await tester.pump();

      verify(() => harness.kratos.logout(KratosTestHarness.sessionToken));
      expect(container.read(isAuthenticatedProvider), isFalse);
      expect(users.deletionCancels, 0);
    });

    testWidgets('로그아웃하지 못하면 알리고 로그인 상태로 남는다', (tester) async {
      when(
        () => harness.kratos.logout(any()),
      ).thenThrow(httpError('/self-service/logout/api', 500));
      final container = await pumpPage(tester);

      await tapText(tester, _logout);

      expect(find.textContaining('로그아웃 실패'), findsOneWidget);
      expect(container.read(isAuthenticatedProvider), isTrue);
      expect(enabled(tester, _logout), isTrue);
    });
  });

  group('프로필을 불러오지 못하면', () {
    testWidgets('알리고, 다시 시도하면 탈퇴 대기 화면을 연다', (tester) async {
      users.readError = httpError('/v1/users/me', 500);
      await pumpPage(tester);

      expect(find.text('계정 정보를 불러오지 못했습니다'), findsOneWidget);
      expect(find.text(_cancel), findsNothing);

      users.readError = null;
      await tapText(tester, '다시 시도');

      expect(find.text(_cancel), findsOneWidget);
    });

    testWidgets('로그아웃할 수 있다', (tester) async {
      when(() => harness.kratos.logout(any())).thenAnswer((_) async {});
      users.readError = httpError('/v1/users/me', 500);
      final container = await pumpPage(tester);

      await tester.tap(find.text(_logout));
      await tester.pump();
      await tester.pump();

      expect(container.read(isAuthenticatedProvider), isFalse);
    });
  });
}
