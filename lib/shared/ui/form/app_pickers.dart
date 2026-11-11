import 'package:material_ui/material_ui.dart';

/// 날짜 고르기. 한국어 달력이고, 고르지 않고 닫으면 null.
///
/// 기본 범위는 1년 전부터 2년 뒤까지다.
Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  required DateTime initial,
  DateTime? first,
  DateTime? last,
}) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first ?? now.subtract(const Duration(days: 365)),
    lastDate: last ?? now.add(const Duration(days: 365 * 2)),
    locale: const Locale('ko'),
  );
}

/// 시각 고르기. 24시간제이고, 고르지 않고 닫으면 null.
Future<TimeOfDay?> showAppTimePicker(
  BuildContext context, {
  required TimeOfDay initial,
}) {
  return showTimePicker(
    context: context,
    initialTime: initial,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );
}
