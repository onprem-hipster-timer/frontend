import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/auth/presentation/pages/signup_page.dart';

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

    testWidgets('비밀번호·비밀번호 확인 필드는 이어받지 않아 비어 있다', (tester) async {
      await tester.pumpWidget(buildSignupPage(initialEmail: 'carry@over.com'));
      await tester.pumpAndSettle();

      expect(fieldText(tester, 1), '');
      expect(fieldText(tester, 2), '');
    });

    testWidgets('initialEmail이 없으면 이메일 필드가 비어 있다', (tester) async {
      await tester.pumpWidget(buildSignupPage());
      await tester.pumpAndSettle();

      expect(fieldText(tester, 0), '');
    });
  });
}
