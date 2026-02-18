// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'holiday_item.freezed.dart';
part 'holiday_item.g.dart';

/// 도메인 국경일 정보 항목 (정제된 데이터)
@Freezed()
abstract class HolidayItem with _$HolidayItem {
  const factory HolidayItem({
    required String locdate,
    required int seq,
    required String dateKind,
    required String dateName,
    required bool isHoliday,
  }) = _HolidayItem;

  factory HolidayItem.fromJson(Map<String, Object?> json) =>
      _$HolidayItemFromJson(json);
}
