// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// 마감 취소·Todo 삭제 시 연결 Schedule의 수명주기 처리 정책. 서버 기본값은 없다.
@JsonEnum()
enum LinkedSchedulePolicy {
  @JsonValue('delete')
  delete('delete'),
  @JsonValue('unlink')
  unlink('unlink'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const LinkedSchedulePolicy(this.json);

  factory LinkedSchedulePolicy.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<LinkedSchedulePolicy> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
