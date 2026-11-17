// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'meeting_mode.dart';
import 'visibility_level.dart';

part 'meeting_read.freezed.dart';
part 'meeting_read.g.dart';

/// 일정 조율 조회 DTO
@Freezed()
abstract class MeetingRead with _$MeetingRead {
  const factory MeetingRead({
    required String id,
    required String title,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') required DateTime endDate,
    @JsonKey(name: 'excluded_dates') required List<DateTime> excludedDates,
    required String timezone,
    required MeetingMode mode,
    @JsonKey(name: 'start_time') required String startTime,
    @JsonKey(name: 'end_time') required String endTime,
    @JsonKey(name: 'time_slot_minutes') required int timeSlotMinutes,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'allow_guests') @Default(false) bool allowGuests,
    @JsonKey(name: 'is_shared') @Default(false) bool isShared,
    @JsonKey(name: 'owner_id') String? ownerId,
    String? description,
    @JsonKey(name: 'visibility_level') VisibilityLevel? visibilityLevel,
  }) = _MeetingRead;

  factory MeetingRead.fromJson(Map<String, Object?> json) =>
      _$MeetingReadFromJson(json);
}
