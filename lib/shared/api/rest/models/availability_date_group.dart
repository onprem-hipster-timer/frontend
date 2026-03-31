// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'availability_time_slot.dart';

part 'availability_date_group.freezed.dart';
part 'availability_date_group.g.dart';

/// 날짜별 가용 시간 그룹 DTO
@Freezed()
abstract class AvailabilityDateGroup with _$AvailabilityDateGroup {
  const factory AvailabilityDateGroup({
    required String date,
    required List<AvailabilityTimeSlot> slots,
  }) = _AvailabilityDateGroup;

  factory AvailabilityDateGroup.fromJson(Map<String, Object?> json) =>
      _$AvailabilityDateGroupFromJson(json);
}
