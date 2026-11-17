// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'meeting_mode.dart';

part 'meeting_create.freezed.dart';
part 'meeting_create.g.dart';

/// 일정 조율 생성 DTO.
///
/// 수정(PATCH) 때도 저장된 값에 수정 내용을 합쳐 이 DTO로 다시 검증한다 (MeetingService.update_meeting).
/// 방식의 규칙은 그때 MODE_RULE_FIELDS 중 하나라도 저장된 값과 달라질 때만 본다 (검증 context의 skip_mode_rules).
@Freezed()
abstract class MeetingCreate with _$MeetingCreate {
  const factory MeetingCreate({
    required String title,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') required DateTime endDate,
    required String timezone,
    required MeetingMode mode,
    @JsonKey(name: 'start_time') required String startTime,
    @JsonKey(name: 'end_time') required String endTime,
    @JsonKey(name: 'excluded_dates') @Default([]) List<DateTime> excludedDates,
    @JsonKey(name: 'time_slot_minutes') @Default(30) int timeSlotMinutes,
    @JsonKey(name: 'allow_guests') @Default(false) bool allowGuests,
    String? description,
  }) = _MeetingCreate;

  factory MeetingCreate.fromJson(Map<String, Object?> json) =>
      _$MeetingCreateFromJson(json);
}
