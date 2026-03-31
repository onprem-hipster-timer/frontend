// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// 타이머 태그 포함 모드
@JsonEnum()
enum TagIncludeMode {
  @JsonValue('none')
  none('none'),
  @JsonValue('timer_only')
  timerOnly('timer_only'),
  @JsonValue('inherit_from_schedule')
  inheritFromSchedule('inherit_from_schedule'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const TagIncludeMode(this.json);

  factory TagIncludeMode.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<TagIncludeMode> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
