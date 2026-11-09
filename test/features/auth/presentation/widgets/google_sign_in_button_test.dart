// Google 브랜딩 가이드라인의 버튼 규격을 지키는지 확인한다
// https://developers.google.com/identity/branding-guidelines

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/auth/presentation/widgets/google_sign_in_button.dart';

void main() {
  Future<void> pumpButton(WidgetTester tester, Brightness brightness) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleSignInAvailableProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(body: GoogleSignInButton(onError: (_) {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ButtonStyle styleOf(WidgetTester tester) =>
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).style!;

  for (final (brightness, fill, stroke, text) in [
    (Brightness.light, 0xFFFFFFFF, 0xFF747775, 0xFF1F1F1F),
    (Brightness.dark, 0xFF131314, 0xFF8E918F, 0xFFE3E3E3),
  ]) {
    testWidgets('${brightness.name} 테마 색을 쓴다', (tester) async {
      await pumpButton(tester, brightness);
      final style = styleOf(tester);

      expect(style.backgroundColor!.resolve({}), Color(fill));
      expect(style.side!.resolve({})!.color, Color(stroke));
      expect(style.foregroundColor!.resolve({}), Color(text));
    });
  }

  testWidgets('앱 테마의 버튼 색을 덮어쓰지 않는다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          googleSignInAvailableProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
          ),
          home: Scaffold(body: GoogleSignInButton(onError: (_) {})),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 터치 영역은 48로 넓어져도 보이는 버튼 면은 40이다
    final surface = find.descendant(
      of: find.byType(OutlinedButton),
      matching: find.byType(Material),
    );
    expect(tester.getSize(surface).height, 40);
    expect(styleOf(tester).backgroundColor!.resolve({}), Colors.white);
    expect(styleOf(tester).shape!.resolve({}), isA<StadiumBorder>());
  });

  testWidgets('공식 G 로고를 20×20으로, 왼쪽 12·로고 뒤 10 간격으로 그린다', (tester) async {
    await pumpButton(tester, Brightness.light);

    final logo = find.byType(Image);
    final image = tester.widget<Image>(logo);
    expect((image.image as AssetImage).assetName, 'assets/google_g_logo.webp');
    expect(tester.getSize(logo), const Size(20, 20));

    final label = find.text('Google 계정으로 계속하기');
    expect(tester.getTopLeft(label).dx - tester.getTopRight(logo).dx, 10);
    expect(
      styleOf(tester).padding!.resolve({}),
      const EdgeInsets.symmetric(horizontal: 12),
    );
  });

  testWidgets('글꼴은 Google Sans Medium 14/20이다', (tester) async {
    await pumpButton(tester, Brightness.light);

    final style = styleOf(tester).textStyle!.resolve({})!;
    expect(style.fontFamily, 'Google Sans');
    expect(style.fontWeight, FontWeight.w500);
    expect(style.fontSize, 14);
    expect(style.fontSize! * style.height!, 20);
  });
}
