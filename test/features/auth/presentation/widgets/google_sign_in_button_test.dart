// Google 브랜딩 가이드라인의 버튼 규격을 지키는지 확인한다
// https://developers.google.com/identity/branding-guidelines

import 'dart:async';

import 'package:momeet/core/providers/retry_policy.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/auth/presentation/widgets/google_sign_in_button.dart';

void main() {
  Future<void> pumpButton(WidgetTester tester, Brightness brightness) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: appRetry,
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
        retry: appRetry,
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

  group('서버에 묻는 동안·그 뒤', () {
    /// [available]이 끝나기 전(로딩)과 끝난 뒤를 차례로 보도록 버튼을 띄운다
    Future<Completer<bool>> pumpPending(
      WidgetTester tester, {
      Brightness brightness = Brightness.light,
    }) async {
      final answer = Completer<bool>();
      await tester.pumpWidget(
        ProviderScope(
          retry: appRetry,
          overrides: [
            googleSignInAvailableProvider.overrideWith((ref) => answer.future),
          ],
          child: MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Scaffold(
              body: Column(
                children: [
                  GoogleSignInButton(onError: (_) {}),
                  const Text('아래 내용'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return answer;
    }

    testWidgets('묻는 동안에는 구분선과 로고를 둔 채 잠시만 기다려 달라는 막힌 버튼이다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpPending(tester);

      expect(find.text('또는'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('잠시만 기다려 주세요'), findsOneWidget);
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
      expect(
        tester.getSemantics(find.byType(OutlinedButton)),
        isSemantics(
          label: '잠시만 기다려 주세요',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          isFocusable: false,
        ),
      );
      semantics.dispose();
    });

    testWidgets('켜져 있으면 같은 자리·크기에서 누를 수 있는 버튼이 되어 아래 내용이 움직이지 않는다', (
      tester,
    ) async {
      final answer = await pumpPending(tester);
      final loading = tester.getRect(find.byType(OutlinedButton));
      final below = tester.getTopLeft(find.text('아래 내용'));

      answer.complete(true);
      await tester.pumpAndSettle();

      expect(find.text('Google 계정으로 계속하기'), findsOneWidget);
      expect(tester.getRect(find.byType(OutlinedButton)), loading);
      expect(tester.getTopLeft(find.text('아래 내용')), below);
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('꺼져 있거나 묻지 못하면 구분선과 버튼을 치운다', (tester) async {
      final off = await pumpPending(tester);
      off.complete(false);
      await tester.pumpAndSettle();
      expect(find.text('또는'), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);

      await tester.pumpWidget(const SizedBox());
      final failed = await pumpPending(tester);
      failed.completeError(StateError('끊김'));
      await tester.pumpAndSettle();
      expect(find.text('또는'), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    for (final brightness in Brightness.values) {
      testWidgets('${brightness.name} 테마의 막힌 버튼은 가이드라인의 비활성 색이다', (
        tester,
      ) async {
        await pumpPending(tester, brightness: brightness);
        final style = styleOf(tester);
        const disabled = {WidgetState.disabled};

        final text = style.foregroundColor!.resolve(disabled)!;
        expect(text.a, closeTo(0.38, 0.01));
        expect(style.side!.resolve(disabled)!.color.a, closeTo(0.12, 0.01));
        expect(
          style.backgroundColor!.resolve(disabled)!.a,
          closeTo(0.61, 0.01),
        );
        expect(style.shape!.resolve(disabled), isA<StadiumBorder>());
      });
    }
  });
}
