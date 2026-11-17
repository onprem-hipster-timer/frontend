// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// 참여자가 미팅에 답하는 방식. 프론트엔드는 이 값으로 화면을 정한다
@JsonEnum()
enum MeetingMode {
  @JsonValue('hourly')
  hourly('hourly'),
  @JsonValue('daily')
  daily('daily'),
  @JsonValue('weekly')
  weekly('weekly'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const MeetingMode(this.json);

  factory MeetingMode.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<MeetingMode> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
