import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/core/auth/kratos_client.dart';
import 'package:momeet/core/auth/kratos_models.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/auth/domain/auth_error_type.dart';
import 'package:momeet/features/auth/presentation/pages/login_page.dart';
import 'package:momeet/features/auth/presentation/pages/verification_page.dart';

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

  /// 가입 직후 상황: 앱은 이미 미인증으로 떠 있고 세션 토큰만 저장된다.
  /// (실제 앱은 시작할 때 라우터가 인증 상태를 먼저 만든다)
  Future<void> storeSignUpSession(WidgetTester tester) async {
    ProviderScope.containerOf(
      tester.element(find.byType(VerificationPage)),
    ).read(authProvider);
    await harness.prefs.setString(sessionTokenKey, 'ory_st_new');
  }

  testWidgets('코드를 확인하면 가입 세션으로 로그인해 홈으로 간다', (tester) async {
    harness.stubSubmit(
      KratosFlowType.verification,
      const KratosSubmitResult(
        flow: KratosFlow(id: 'v1', state: 'passed_challenge'),
      ),
    );
    await openVerification(tester, flow: 'v1', email: 'new@example.com');
    await storeSignUpSession(tester);

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
    verify(() => harness.kratos.whoami('ory_st_new')).called(1);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('세션이 없으면 인증 뒤 로그인 화면으로 간다', (tester) async {
    harness.stubSubmit(KratosFlowType.verification, const KratosSubmitResult());
    await openVerification(tester, flow: 'v1');

    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.text('인증하기'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
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

  testWidgets('나중에 하기는 가입 세션으로 로그인해 홈으로 간다', (tester) async {
    await openVerification(tester, flow: 'v1', email: 'new@example.com');
    await storeSignUpSession(tester);

    await tester.tap(find.text('나중에 하기'));
    await tester.pumpAndSettle();

    verify(() => harness.kratos.whoami('ory_st_new')).called(1);
    expect(find.text('home'), findsOneWidget);
  });
}
