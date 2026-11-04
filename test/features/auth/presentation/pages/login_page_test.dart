import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/core/auth/kratos_client.dart';
import 'package:momeet/core/auth/kratos_models.dart';
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
    harness.stubCreateFlow(KratosFlowType.login, 'f1');
  });

  Widget buildLoginPage() {
    return pumpApp(const LoginPage(), overrides: harness.overrides);
  }

  /// 이메일 + 비밀번호를 입력하고 로그인 버튼을 누르는 헬퍼
  Future<void> enterCredentialsAndLogin(
    WidgetTester tester, {
    String email = 'test@test.com',
    String password = 'wrong-password',
  }) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();
  }

  // ============================================================
  // 로그인 실패 시 에러 배너
  // ============================================================
  group('로그인 실패 시 에러 배너', () {
    testWidgets('잘못된 비밀번호 입력 시 에러 배너가 표시된다', (tester) async {
      harness.stubSubmitError(KratosFlowType.login, kratosError(4000006));

      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      await enterCredentialsAndLogin(tester);

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('네트워크 오류 시 에러 배너가 표시된다', (tester) async {
      harness.stubSubmitError(
        KratosFlowType.login,
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );

      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      await enterCredentialsAndLogin(tester);

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });

  // ============================================================
  // 에러 해제 동작
  // ============================================================
  group('에러 해제', () {
    setUp(() {
      harness.stubSubmitError(KratosFlowType.login, kratosError(4000006));
    });

    testWidgets('이메일 필드 수정 시 에러가 사라진다', (tester) async {
      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      await enterCredentialsAndLogin(tester);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'new@email.com');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });

    testWidgets('비밀번호 필드 수정 시 에러가 사라진다', (tester) async {
      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      await enterCredentialsAndLogin(tester);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(1), 'new-password');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });

    testWidgets('X 버튼을 누르면 에러가 사라진다', (tester) async {
      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      await enterCredentialsAndLogin(tester);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });
  });

  // ============================================================
  // 폼 유효성 검증
  // ============================================================
  group('폼 유효성 검증', () {
    testWidgets('빈 이메일로 로그인 시 유효성 에러가 표시된다', (tester) async {
      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.tap(find.text('로그인'));
      await tester.pumpAndSettle();

      expect(find.text('이메일을 입력해주세요'), findsOneWidget);
      verifyNever(() => harness.kratos.createFlow(KratosFlowType.login));
    });

    testWidgets('@ 없는 이메일로 로그인 시 형식 에러가 표시된다', (tester) async {
      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'invalid');
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.tap(find.text('로그인'));
      await tester.pumpAndSettle();

      expect(find.text('올바른 이메일 형식이 아닙니다'), findsOneWidget);
    });

    testWidgets('빈 비밀번호로 로그인 시 유효성 에러가 표시된다', (tester) async {
      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
      await tester.tap(find.text('로그인'));
      await tester.pumpAndSettle();

      expect(find.text('비밀번호를 입력해주세요'), findsOneWidget);
    });
  });

  // ============================================================
  // 폼 전환 시 이메일 이어받기 (initialEmail)
  // ============================================================
  group('이메일 이어받기 (initialEmail)', () {
    String fieldText(WidgetTester tester, int index) => tester
        .widget<EditableText>(find.byType(EditableText).at(index))
        .controller
        .text;

    testWidgets('initialEmail이 주어지면 이메일 필드에 채워진다', (tester) async {
      await tester.pumpWidget(
        pumpApp(
          const LoginPage(initialEmail: 'carry@over.com'),
          overrides: harness.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('carry@over.com'), findsOneWidget);
      expect(fieldText(tester, 0), 'carry@over.com');
    });

    testWidgets('initialEmail이 없으면 이메일 필드가 비어 있다', (tester) async {
      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      expect(fieldText(tester, 0), '');
    });

    testWidgets('로그인 → 회원가입 전환 시 이메일만 넘어가고 비밀번호는 안 넘어간다', (tester) async {
      await tester.pumpWidget(
        pumpAuthFlow(initialLocation: '/login', overrides: harness.overrides),
      );
      await tester.pumpAndSettle();

      // 로그인 폼에 이메일 + 비밀번호를 모두 입력
      await tester.enterText(find.byType(EditableText).at(0), 'carry@over.com');
      await tester.enterText(find.byType(EditableText).at(1), 'secret-pw');
      await tester.pumpAndSettle();

      // "회원가입" 전환 버튼 → 회원가입 폼으로 이동
      await tester.tap(find.widgetWithText(TextButton, '회원가입'));
      await tester.pumpAndSettle();

      expect(find.byType(SignupPage), findsOneWidget);

      String signupField(int index) => tester
          .widget<EditableText>(
            find
                .descendant(
                  of: find.byType(SignupPage),
                  matching: find.byType(EditableText),
                )
                .at(index),
          )
          .controller
          .text;

      expect(signupField(0), 'carry@over.com'); // 이메일 이어받음
      expect(signupField(1), ''); // 비밀번호는 전달 안 됨
      expect(signupField(2), ''); // 비밀번호 확인도 전달 안 됨
    });
  });

  testWidgets('인증 전 로그인은 서버가 준 플로우와 이메일로 인증 화면을 연다', (tester) async {
    harness.stubSubmitError(
      KratosFlowType.login,
      const KratosException(
        statusCode: 403,
        errorId: 'session_verified_address_required',
        verificationFlowId: 'v9',
      ),
    );
    await tester.pumpWidget(
      pumpAuthFlow(initialLocation: '/login', overrides: harness.overrides),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'new@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'pw-12345678');
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle();

    final page = tester.widget<VerificationPage>(find.byType(VerificationPage));
    expect(page.flowId, 'v9');
    expect(page.email, 'new@example.com');
  });
}
