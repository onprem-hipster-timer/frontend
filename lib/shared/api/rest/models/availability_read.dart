// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'participant_read.dart';
import 'time_slot_read.dart';

part 'availability_read.freezed.dart';
part 'availability_read.g.dart';

/// 참여자별 가능 시간 조회 DTO
@Freezed()
abstract class AvailabilityRead with _$AvailabilityRead {
  const factory AvailabilityRead({
    required ParticipantRead participant,
    @JsonKey(name: 'time_slots') required List<TimeSlotRead> timeSlots,
  }) = _AvailabilityRead;

  factory AvailabilityRead.fromJson(Map<String, Object?> json) =>
      _$AvailabilityReadFromJson(json);
}
