import 'package:material_ui/material_ui.dart';

/// [ColorScheme]에 없는 앱 전용 색 역할.
///
/// ```dart
/// final colors = AppColors.of(context);
/// Container(color: colors.successContainer);
/// ```
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.holiday,
    required this.saturday,
    required this.categorical,
  });

  static const light = AppColors(
    success: Color(0xFF2E7D32),
    onSuccess: Colors.white,
    successContainer: Color(0xFFC8E6C9),
    onSuccessContainer: Color(0xFF1B5E20),
    warning: Color(0xFFEF6C00),
    onWarning: Colors.white,
    warningContainer: Color(0xFFFFE0B2),
    onWarningContainer: Color(0xFFE65100),
    holiday: Color(0xFFD32F2F),
    saturday: Color(0xFF1976D2),
    categorical: _categorical,
  );

  static const dark = AppColors(
    success: Color(0xFF81C784),
    onSuccess: Colors.black,
    successContainer: Color(0xFF1B5E20),
    onSuccessContainer: Color(0xFFC8E6C9),
    warning: Color(0xFFFFB74D),
    onWarning: Colors.black,
    warningContainer: Color(0xFF8A4B00),
    onWarningContainer: Color(0xFFFFE0B2),
    holiday: Color(0xFFEF9A9A),
    saturday: Color(0xFF90CAF9),
    categorical: _categorical,
  );

  /// 차트처럼 항목마다 다른 색이 필요할 때 차례로 쓰는 색.
  static const _categorical = [
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
    Color(0xFFFF9800),
    Color(0xFF4CAF50),
    Color(0xFFF44336),
    Color(0xFF009688),
    Color(0xFF3F51B5),
    Color(0xFFE91E63),
    Color(0xFFFFC107),
    Color(0xFF00BCD4),
  ];

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  /// 공휴일·일요일 날짜 글자
  final Color holiday;

  /// 토요일 날짜 글자
  final Color saturday;

  final List<Color> categorical;

  /// 테마에 확장이 없으면 밝기에 맞는 기본값을 쓴다.
  static AppColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  AppColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? holiday,
    Color? saturday,
    List<Color>? categorical,
  }) => AppColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    holiday: holiday ?? this.holiday,
    saturday: saturday ?? this.saturday,
    categorical: categorical ?? this.categorical,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      success: mix(success, other.success),
      onSuccess: mix(onSuccess, other.onSuccess),
      successContainer: mix(successContainer, other.successContainer),
      onSuccessContainer: mix(onSuccessContainer, other.onSuccessContainer),
      warning: mix(warning, other.warning),
      onWarning: mix(onWarning, other.onWarning),
      warningContainer: mix(warningContainer, other.warningContainer),
      onWarningContainer: mix(onWarningContainer, other.onWarningContainer),
      holiday: mix(holiday, other.holiday),
      saturday: mix(saturday, other.saturday),
      categorical: t < 0.5 ? categorical : other.categorical,
    );
  }
}
