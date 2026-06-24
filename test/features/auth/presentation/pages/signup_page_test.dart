import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/auth/presentation/pages/login_page.dart';
import 'package:momeet/features/auth/presentation/pages/signup_page.dart';

import '../../../../helpers/auth_router.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/supabase_mocks.dart';

void main() {
  late SupabaseTestHarness harness;

  setUp(() {
    harness = SupabaseTestHarness()..init(authenticated: false);
  });

  tearDown(() {
    harness.dispose();
  });

  Widget buildSignupPage({String? initialEmail}) {
    return pumpApp(
      SignupPage(initialEmail: initialEmail),
      overrides: [
        supabaseClientProvider.overrideWithValue(harness.mockSupabase),
      ],
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
        pumpAuthFlow(
          initialLocation: '/signup',
          overrides: [
            supabaseClientProvider.overrideWithValue(harness.mockSupabase),
          ],
        ),
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
}
