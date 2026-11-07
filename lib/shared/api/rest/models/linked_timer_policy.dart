// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// 연결된 Todo·Schedule 삭제 시 연결 타이머 처리 정책. 서버 기본값은 없다.
@JsonEnum()
enum LinkedTimerPolicy {
  @JsonValue('delete')
  delete('delete'),
  @JsonValue('unlink')
  unlink('unlink'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const LinkedTimerPolicy(this.json);

  factory LinkedTimerPolicy.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<LinkedTimerPolicy> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
