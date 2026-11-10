import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_email_field.dart';
import 'package:momeet/features/auth/presentation/widgets/auth_password_field.dart';

Future<GlobalKey<FormState>> _pump(WidgetTester tester, Widget field) async {
  final formKey = GlobalKey<FormState>();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Form(key: formKey, child: field),
      ),
    ),
  );
  return formKey;
}

void main() {
  testWidgets('이메일 칸은 비었거나 @가 없으면 오류를 보인다', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final form = await _pump(tester, AuthEmailField(controller: controller));

    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('이메일을 입력해주세요'), findsOneWidget);

    controller.text = 'user.example.com';
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('올바른 이메일 형식이 아닙니다'), findsOneWidget);

    controller.text = 'user@example.com';
    expect(form.currentState!.validate(), isTrue);
  });

  testWidgets('비밀번호 칸은 가린 채 시작하고 버튼으로 보였다 다시 가린다', (tester) async {
    final controller = TextEditingController(text: 'secret');
    addTearDown(controller.dispose);
    await _pump(
      tester,
      AuthPasswordField(
        controller: controller,
        label: '비밀번호',
        validator: (_) => null,
      ),
    );
    bool obscured() =>
        tester.widget<EditableText>(find.byType(EditableText)).obscureText;

    expect(obscured(), isTrue);
    await tester.tap(find.byTooltip('비밀번호 보기'));
    await tester.pump();
    expect(obscured(), isFalse);
    await tester.tap(find.byTooltip('비밀번호 숨기기'));
    await tester.pump();
    expect(obscured(), isTrue);
  });
}
