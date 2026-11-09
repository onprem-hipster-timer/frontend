import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/shared/api/kratos/kratos_client.dart';
import 'package:momeet/shared/api/kratos/kratos_models.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/features/auth/presentation/pages/verification_page.dart';
import 'package:momeet/features/auth/presentation/pages/login_page.dart';
import 'package:momeet/features/auth/presentation/pages/signup_page.dart';

import '../../../../helpers/auth_router.dart';
import '../../../../helpers/kratos_mocks.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  late KratosTestHarness harness;

  setUpAll(registerKratosFallbacks);

  setUp(() async {
    harness = await KratosTestHarness.create(authenticated: false);
  });

  Widget buildSignupPage({String? initialEmail}) {
    return pumpApp(
      SignupPage(initialEmail: initialEmail),
      overrides: harness.overrides,
    );
  }

  String fieldText(WidgetTester tester, int index) => tester
      .widget<EditableText>(find.byType(EditableText).at(index))
      .controller
      .text;

  // ============================================================
  // 폼 전환 시 이메일 이어받기 (initialEmail)
  // ============================================================
  group('이메일 이어받기 (initialEmail)', () {
    testWidgets('initialEmail이 주어지면 이메일 필드에 채워진다', (tester) async {
      await tester.pumpWidget(buildSignupPage(initialEmail: 'carry@over.com'));
      await tester.pumpAndSettle();

      expect(find.text('carry@over.com'), findsOneWidget);
      expect(fieldText(tester, 0), 'carry@over.com');
    });

    testWidgets('initialEmail이 없으면 이메일 필드가 비어 있다', (tester) async {
      await tester.pumpWidget(buildSignupPage());
      await tester.pumpAndSettle();

      expect(fieldText(tester, 0), '');
    });

    testWidgets('회원가입 → 로그인 전환 시 이메일만 넘어가고 비밀번호는 안 넘어간다', (tester) async {
      await tester.pumpWidget(
        pumpAuthFlow(initialLocation: '/signup', overrides: harness.overrides),
      );
      await tester.pumpAndSettle();

      // 회원가입 폼에 이메일 + 비밀번호 + 비밀번호 확인을 모두 입력
      await tester.enterText(find.byType(EditableText).at(0), 'carry@over.com');
      await tester.enterText(find.byType(EditableText).at(1), 'secret-pw');
      await tester.enterText(find.byType(EditableText).at(2), 'secret-pw');
      await tester.pumpAndSettle();

      // "로그인" 전환 버튼 → 로그인 폼으로 이동
      await tester.tap(find.widgetWithText(TextButton, '로그인'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);

      String loginField(int index) => tester
          .widget<EditableText>(
            find
                .descendant(
                  of: find.byType(LoginPage),
                  matching: find.byType(EditableText),
                )
                .at(index),
          )
          .controller
          .text;

      expect(loginField(0), 'carry@over.com'); // 이메일 이어받음
      expect(loginField(1), ''); // 비밀번호는 전달 안 됨
    });
  });

  // ============================================================
  // 가입 성공 뒤 이동
  // ============================================================
  testWidgets('가입하면 인증 플로우와 이메일을 들고 인증 화면으로 간다', (tester) async {
    harness.stubCreateFlow(KratosFlowType.registration, 'r1');
    harness.stubSubmit(
      KratosFlowType.registration,
      const KratosSubmitResult(
        sessionToken: 'ory_st_new',
        continueWith: [
          {
            'action': 'show_verification_ui',
            'flow': {'id': 'v1'},
          },
        ],
      ),
    );
    await tester.pumpWidget(
      pumpAuthFlow(initialLocation: '/signup', overrides: harness.overrides),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'new@example.com');
    await tester.enterText(find.byType(EditableText).at(1), 'secret-pw-123');
    await tester.enterText(find.byType(EditableText).at(2), 'secret-pw-123');
    await tester.tap(find.widgetWithText(FilledButton, '회원가입'));
    await tester.pumpAndSettle();

    final page = tester.widget<VerificationPage>(find.byType(VerificationPage));
    expect(page.flowId, 'v1');
    expect(page.email, 'new@example.com');
  });

  testWidgets('비밀번호가 8자보다 짧으면 가입을 보내지 않는다', (tester) async {
    await tester.pumpWidget(buildSignupPage());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'new@example.com');
    await tester.enterText(find.byType(EditableText).at(1), 'pw12345');
    await tester.enterText(find.byType(EditableText).at(2), 'pw12345');
    await tester.tap(find.widgetWithText(FilledButton, '회원가입'));
    await tester.pumpAndSettle();

    expect(find.text('비밀번호는 8자 이상이어야 합니다'), findsOneWidget);
    verifyNever(() => harness.kratos.createFlow(KratosFlowType.registration));
  });

  testWidgets('Google 버튼은 가입 플로우로 시작하고 로그인 화면으로 돌아오게 한다', (tester) async {
    final redirected = <Uri>[];
    harness.stubGoogleStart(KratosFlowType.registration);
    await tester.pumpWidget(
      pumpAuthFlow(
        initialLocation: '/signup',
        overrides: [
          ...harness.overrides,
          googleSignInAvailableProvider.overrideWith((ref) async => true),
          appOriginProvider.overrideWithValue('https://app.example.com'),
          browserRedirectProvider.overrideWithValue((url) async {
            redirected.add(url);
          }),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Google 계정으로 계속하기'));
    await tester.tap(find.text('Google 계정으로 계속하기'));
    // 브라우저가 Google로 떠나는 동안 진행 표시가 계속 돌므로 settle을 기다리지 않는다
    await tester.pump();
    await tester.pump();

    verify(
      () => harness.kratos.createFlow(
        KratosFlowType.registration,
        returnTo: 'https://app.example.com/login',
      ),
    ).called(1);
    expect(redirected, [KratosTestHarness.googleUrl]);
  });
}
