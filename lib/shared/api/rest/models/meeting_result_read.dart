// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'availability_date_group.dart';
import 'meeting_read.dart';

part 'meeting_result_read.freezed.dart';
part 'meeting_result_read.g.dart';

/// 공통 가능 시간 분석 결과 DTO
@Freezed()
abstract class MeetingResultRead with _$MeetingResultRead {
  const factory MeetingResultRead({
    required MeetingRead meeting,
    @JsonKey(name: 'availability_grid')
    required List<AvailabilityDateGroup> availabilityGrid,
  }) = _MeetingResultRead;

  factory MeetingResultRead.fromJson(Map<String, Object?> json) =>
      _$MeetingResultReadFromJson(json);
}
