import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/shared/api/kratos/kratos_client.dart';
import 'package:momeet/shared/api/kratos/kratos_models.dart';
import 'package:momeet/features/auth/domain/auth_error_type.dart';
import 'package:momeet/features/auth/presentation/pages/login_page.dart';

import '../../../../helpers/auth_router.dart';
import '../../../../helpers/kratos_mocks.dart';

void main() {
  late KratosTestHarness harness;

  setUpAll(registerKratosFallbacks);

  setUp(() async {
    harness = await KratosTestHarness.create(authenticated: false);
  });

  Future<void> openVerification(
    WidgetTester tester, {
    String? flow,
    String? email,
  }) async {
    await tester.pumpWidget(
      pumpAuthFlow(
        initialLocation: flow == null
            ? '/verification'
            : '/verification?flow=$flow',
        initialExtra: email,
        overrides: harness.overrides,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('인증하면 이메일을 채운 로그인 화면으로 간다 (인증 전엔 세션 없음)', (tester) async {
    harness.stubSubmit(
      KratosFlowType.verification,
      const KratosSubmitResult(
        flow: KratosFlow(id: 'v1', state: 'passed_challenge'),
      ),
    );
    await openVerification(tester, flow: 'v1', email: 'new@example.com');

    expect(find.textContaining('new@example.com'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.text('인증하기'));
    await tester.pumpAndSettle();

    verify(
      () => harness.kratos.submit(KratosFlowType.verification, 'v1', {
        'method': 'code',
        'code': '123456',
      }),
    ).called(1);
    verifyNever(() => harness.kratos.whoami(any()));
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('new@example.com'), findsOneWidget);
    expect(find.text('이메일이 인증되었습니다. 로그인해주세요.'), findsOneWidget);
  });

  testWidgets('로그인 상태에서 인증하면 JWT를 다시 받아 홈으로 간다', (tester) async {
    harness = await KratosTestHarness.create();
    harness.stubSubmit(KratosFlowType.verification, const KratosSubmitResult());
    // 이메일 없이 열면 화면이 시작할 때 인증 상태를 읽어 세션을 먼저 복원한다 (실제 앱과 같은 순서)
    await openVerification(tester, flow: 'v1');
    clearInteractions(harness.kratos);

    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.text('인증하기'));
    await tester.pumpAndSettle();

    verify(
      () => harness.kratos.whoami(KratosTestHarness.sessionToken),
    ).called(1);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('코드가 틀리면 오류 배너를 보여준다', (tester) async {
    harness.stubSubmitError(KratosFlowType.verification, kratosError(4070006));
    await openVerification(tester, flow: 'v1');

    await tester.enterText(find.byType(TextFormField), '000000');
    await tester.tap(find.text('인증하기'));
    await tester.pumpAndSettle();

    expect(find.text(AuthErrorType.invalidCode.localized), findsOneWidget);
  });

  testWidgets('flow가 없으면 이메일을 받아 코드를 보낸다', (tester) async {
    harness.stubCreateFlow(KratosFlowType.verification, 'v2');
    harness.stubSubmit(KratosFlowType.verification, const KratosSubmitResult());
    await openVerification(tester);

    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await tester.tap(find.text('코드 받기'));
    await tester.pumpAndSettle();

    verify(
      () => harness.kratos.submit(KratosFlowType.verification, 'v2', {
        'method': 'code',
        'email': 'user@example.com',
      }),
    ).called(1);
    expect(find.text('인증하기'), findsOneWidget);
  });

  testWidgets('코드 다시 받기는 이메일 입력으로 돌아간다', (tester) async {
    await openVerification(tester, flow: 'v1', email: 'new@example.com');

    await tester.tap(find.text('코드 다시 받기'));
    await tester.pumpAndSettle();

    expect(find.text('코드 받기'), findsOneWidget);
    expect(find.text('new@example.com'), findsOneWidget);
  });
}
