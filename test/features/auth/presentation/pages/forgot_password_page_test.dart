import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/shared/api/kratos/kratos_client.dart';
import 'package:momeet/shared/api/kratos/kratos_models.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/auth/domain/auth_error_type.dart';

import '../../../../helpers/auth_router.dart';
import '../../../../helpers/kratos_mocks.dart';

void main() {
  late KratosTestHarness harness;

  setUpAll(registerKratosFallbacks);

  setUp(() async {
    harness = await KratosTestHarness.create(authenticated: false);
    harness.stubCreateFlow(KratosFlowType.recovery, 'rec1');
  });

  Future<void> openPage(WidgetTester tester) async {
    await tester.pumpWidget(
      pumpAuthFlow(
        initialLocation: '/forgot-password',
        overrides: harness.overrides,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester, String buttonText) async {
    await tester.tap(find.widgetWithText(FilledButton, buttonText));
    await tester.pumpAndSettle();
  }

  const recovered = KratosSubmitResult(
    continueWith: [
      {'action': 'set_ory_session_token', 'ory_session_token': 'ory_st_rec'},
      {
        'action': 'show_settings_ui',
        'flow': {'id': 's1'},
      },
    ],
  );

  testWidgets('이메일, 코드, 새 비밀번호 순서로 재설정하고 로그인해 홈으로 간다', (tester) async {
    harness.stubSubmit(KratosFlowType.recovery, recovered);
    harness.stubSubmit(KratosFlowType.settings, const KratosSubmitResult());
    await openPage(tester);

    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await submit(tester, '코드 받기');
    expect(find.textContaining('user@example.com'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '123456');
    await submit(tester, '확인');

    await tester.enterText(find.byType(TextFormField).at(0), 'new-pw-123');
    await tester.enterText(find.byType(TextFormField).at(1), 'new-pw-123');
    await submit(tester, '비밀번호 변경');

    verifyInOrder([
      () => harness.kratos.submit(KratosFlowType.recovery, 'rec1', {
        'method': 'code',
        'email': 'user@example.com',
      }),
      () => harness.kratos.submit(KratosFlowType.recovery, 'rec1', {
        'method': 'code',
        'code': '123456',
      }),
      () => harness.kratos.submit(KratosFlowType.settings, 's1', {
        'method': 'password',
        'password': 'new-pw-123',
      }, sessionToken: 'ory_st_rec'),
    ]);
    expect(harness.prefs.getString(sessionTokenKey), 'ory_st_rec');
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('로그인 상태의 비밀번호 변경은 계정 이메일로 받은 코드로만 한다', (tester) async {
    harness = await KratosTestHarness.create();
    harness.stubCreateFlow(KratosFlowType.recovery, 'rec1');
    harness.stubSubmit(KratosFlowType.recovery, recovered);
    harness.stubSubmit(KratosFlowType.settings, const KratosSubmitResult());
    await openPage(tester);

    // 이메일을 고를 수 없고, 로그인한 계정 이메일로 코드를 보낸다
    expect(find.text('비밀번호 변경'), findsWidgets);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.textContaining(testUser.email), findsOneWidget);
    await submit(tester, '코드 받기');

    await tester.enterText(find.byType(TextFormField), '123456');
    await submit(tester, '확인');
    await tester.enterText(find.byType(TextFormField).at(0), 'new-pw-123');
    await tester.enterText(find.byType(TextFormField).at(1), 'new-pw-123');
    await submit(tester, '비밀번호 변경');

    verify(
      () => harness.kratos.submit(KratosFlowType.recovery, 'rec1', {
        'method': 'code',
        'email': testUser.email,
      }),
    ).called(1);
    expect(harness.prefs.getString(sessionTokenKey), 'ory_st_rec');
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('코드가 틀리면 오류를 보여주고 코드 단계에 머문다', (tester) async {
    await openPage(tester);
    harness.stubSubmit(KratosFlowType.recovery, const KratosSubmitResult());
    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await submit(tester, '코드 받기');

    harness.stubSubmitError(KratosFlowType.recovery, kratosError(4060006));
    await tester.enterText(find.byType(TextFormField), '000000');
    await submit(tester, '확인');

    expect(find.text(AuthErrorType.invalidCode.localized), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '확인'), findsOneWidget);
  });

  testWidgets('코드 다시 받기는 이메일 단계로 돌아간다', (tester) async {
    harness.stubSubmit(KratosFlowType.recovery, const KratosSubmitResult());
    await openPage(tester);
    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await submit(tester, '코드 받기');

    await tester.tap(find.text('코드 다시 받기'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, '코드 받기'), findsOneWidget);
  });

  testWidgets('새 비밀번호 확인이 다르면 저장하지 않는다', (tester) async {
    harness.stubSubmit(KratosFlowType.recovery, recovered);
    await openPage(tester);
    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await submit(tester, '코드 받기');
    await tester.enterText(find.byType(TextFormField), '123456');
    await submit(tester, '확인');

    await tester.enterText(find.byType(TextFormField).at(0), 'new-pw-123');
    await tester.enterText(find.byType(TextFormField).at(1), 'other-pw-123');
    await submit(tester, '비밀번호 변경');

    expect(find.text('비밀번호가 일치하지 않습니다'), findsOneWidget);
    verifyNever(
      () => harness.kratos.submit(
        KratosFlowType.settings,
        any(),
        any(),
        sessionToken: any(named: 'sessionToken'),
      ),
    );
  });
}
