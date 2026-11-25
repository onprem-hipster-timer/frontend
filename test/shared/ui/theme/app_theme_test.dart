import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

void main() {
  test('밝은·어두운 테마는 밝기에 맞는 앱 색을 싣는다', () {
    expect(AppTheme.light().extension<AppColors>(), AppColors.light);
    expect(AppTheme.dark().extension<AppColors>(), AppColors.dark);
    expect(AppTheme.dark().colorScheme.brightness, Brightness.dark);
  });

  test('밝은·어두운 테마의 글자는 앱의 기본 글꼴로 그린다', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      expect(theme.textTheme.bodyMedium!.fontFamily, AppTheme.fontFamily);
      expect(theme.textTheme.titleLarge!.fontFamily, AppTheme.fontFamily);
      expect(theme.textTheme.labelSmall!.fontFamily, AppTheme.fontFamily);
    }
  });

  group('앱 글꼴 파일', () {
    final lines = File('pubspec.yaml').readAsLinesSync();

    test('pubspec.yaml의 fonts에는 앱 글꼴의 보통(400) 하나만 있고 그 파일이 있다', () {
      final start = lines.indexOf('    - family: ${AppTheme.fontFamily}');
      expect(start, isNot(-1));
      final entries = lines
          .skip(start + 1)
          .takeWhile(
            (line) =>
                line.trim().isNotEmpty && !line.startsWith('    - family:'),
          )
          .map((line) => line.trim())
          .where((line) => !line.startsWith('#'))
          .toList();

      expect(entries, [
        'fonts:',
        '- asset: assets/fonts/Pretendard-Regular.subset.woff2',
        'weight: 400',
      ]);
      expect(
        File('assets/fonts/Pretendard-Regular.subset.woff2').existsSync(),
        isTrue,
      );
    });

    test('첫 화면 뒤에 불러오는 500·600·700 파일은 pubspec.yaml의 assets에 있고 파일이 있다', () {
      final assets = {
        for (final line in lines)
          if (line.trim().startsWith('- assets/')) line.trim().substring(2),
      };

      expect(appFontLateAssets, hasLength(3));
      for (final asset in appFontLateAssets) {
        expect(assets, contains(asset), reason: asset);
        expect(File(asset).existsSync(), isTrue, reason: asset);
        expect(asset, isNot(contains('Regular')), reason: asset);
      }
    });
  });

  testWidgets('나머지 굵기를 받지 못해도 글꼴 불러오기는 오류 없이 끝난다', (tester) async {
    final bundle = _FailingBundle();

    await tester.runAsync(() => loadAppFontWeights(bundle: bundle));
    await tester.runAsync(
      () => loadAppFontWeights(bundle: bundle, package: 'momeet'),
    );

    expect(bundle.requested, [
      ...appFontLateAssets,
      for (final asset in appFontLateAssets) 'packages/momeet/$asset',
    ]);
  });

  testWidgets('나머지 굵기를 여러 번 불러도 처음 시작한 불러오기 하나를 같이 기다린다', (tester) async {
    final first = appFontWeights();

    expect(appFontWeights(), same(first));
    await tester.runAsync(() => first);
    expect(appFontWeights(), same(first));
  });

  test('테마를 거치지 않는 글자의 바탕 스타일은 앱 글꼴이다', () {
    expect(AppTheme.font.fontFamily, AppTheme.fontFamily);
    expect(AppTheme.font.fontFamilyFallback, AppTheme.fontFamilyFallback);
    expect(
      AppTheme.light().textTheme.bodyMedium!.fontFamilyFallback,
      AppTheme.fontFamilyFallback,
    );
  });

  test('입력 칸은 모서리 12의 외곽선, 시트는 윗모서리 20으로 그린다', () {
    final theme = AppTheme.light();
    final border = theme.inputDecorationTheme.border! as OutlineInputBorder;
    expect(border.borderRadius, AppRadius.lgAll);

    final sheet = theme.bottomSheetTheme.shape! as RoundedRectangleBorder;
    expect(sheet.borderRadius, AppRadius.sheetTop);
    expect(theme.bottomSheetTheme.backgroundColor, theme.colorScheme.surface);
  });

  testWidgets('테마에 앱 색이 없으면 밝기에 맞는 기본값을 쓴다', (tester) async {
    late AppColors colors;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Builder(
          builder: (context) {
            colors = AppColors.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(colors, AppColors.dark);
  });

  test('lerp는 끝값에서 각 테마의 색과 같다', () {
    expect(
      AppColors.light.lerp(AppColors.dark, 1).success,
      AppColors.dark.success,
    );
    expect(
      AppColors.light.lerp(AppColors.dark, 0).holiday,
      AppColors.light.holiday,
    );
  });
}

/// 어떤 파일도 내주지 못하는 에셋 묶음. 달라고 한 경로를 적는다
class _FailingBundle extends CachingAssetBundle {
  final requested = <String>[];

  @override
  Future<ByteData> load(String key) {
    requested.add(key);
    return Future.error(FlutterError('$key 없음'));
  }
}
