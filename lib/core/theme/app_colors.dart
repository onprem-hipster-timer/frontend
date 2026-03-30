import 'package:flutter/material.dart';

/// 앱 전용 시맨틱 컬러를 정의하는 ThemeExtension.
///
/// Material 3 [ColorScheme]에 포함되지 않는 커스텀 컬러
/// (예: 성공 상태)를 테마 단위로 관리합니다.
///
/// 사용 예:
/// ```dart
/// final appColors = Theme.of(context).extension<AppColors>()!;
/// Container(color: appColors.success);
/// ```
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color success;
  final Color onSuccess;

  const AppColors({required this.success, required this.onSuccess});

  @override
  AppColors copyWith({Color? success, Color? onSuccess}) => AppColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
    );
  }
}
