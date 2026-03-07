// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'availability_time_slot.freezed.dart';
part 'availability_time_slot.g.dart';

/// 시간 슬롯별 가용 인원 DTO
@Freezed()
abstract class AvailabilityTimeSlot with _$AvailabilityTimeSlot {
  const factory AvailabilityTimeSlot({
    required String time,
    required int count,
  }) = _AvailabilityTimeSlot;

  factory AvailabilityTimeSlot.fromJson(Map<String, Object?> json) =>
      _$AvailabilityTimeSlotFromJson(json);
}
