// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// 참여자가 고른 시간 구간의 종류
@JsonEnum()
enum TimeSlotKind {
  @JsonValue('available')
  available('available'),
  @JsonValue('unavailable')
  unavailable('unavailable'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const TimeSlotKind(this.json);

  factory TimeSlotKind.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<TimeSlotKind> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
