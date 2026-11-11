import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

void main() {
  test('밝은·어두운 테마는 밝기에 맞는 앱 색을 싣는다', () {
    expect(AppTheme.light().extension<AppColors>(), AppColors.light);
    expect(AppTheme.dark().extension<AppColors>(), AppColors.dark);
    expect(AppTheme.dark().colorScheme.brightness, Brightness.dark);
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
