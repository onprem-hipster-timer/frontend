import 'package:material_ui/material_ui.dart';

/// 태그가 없는 일정의 상태별 기본 색.
///
/// 달력 데이터 소스는 테마 밖(provider)에서 만들어져 테마를 읽지 못하므로 고정 색을 쓴다.
abstract final class ScheduleStateColors {
  static const confirmed = Color(0xFF2196F3);
  static const planned = Color(0xFF009688);
  static const cancelled = Color(0xFF9E9E9E);
}
