import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/theme/app_colors.dart';
import 'package:momeet/shared/ui/theme/app_radius.dart';
import 'package:momeet/shared/ui/theme/app_fonts.dart';

/// 앱 테마. 컴포넌트 기본 모양은 여기서 정하고 화면에서는 덮어쓰지 않는다.
abstract final class AppTheme {
  static const _seed = Colors.blue;

  /// 앱의 기본 글꼴. 보통(400)은 pubspec.yaml의 fonts로, 나머지 굵기는 첫 화면 뒤에 불러온다([loadAppFontWeights]).
  /// 타이머 숫자처럼 글꼴을 따로 정한 글자만 다른 글꼴로 그린다
  static const fontFamily = 'Pretendard';

  /// 이 패키지를 가져다 쓰는 앱(위젯 카탈로그)에는 글꼴이 패키지 이름을 붙인 이름으로 등록된다
  static const fontFamilyFallback = ['packages/momeet/$fontFamily'];

  /// 테마를 거치지 않고 그리는 글자(달력 패키지에 넘기는 스타일, 버튼의 글자 스타일처럼 통째로 바꾸는 것)에
  /// 앱 글꼴을 입히는 바탕. `copyWith`로 크기·색을 더한다
  static const font = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
  );

  static ThemeData light() => _build(Brightness.light, AppColors.light);

  static ThemeData dark() => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors appColors) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      extensions: [appColors],
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: AppRadius.lgAll),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
        clipBehavior: Clip.antiAlias,
      ),
      cardTheme: const CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
