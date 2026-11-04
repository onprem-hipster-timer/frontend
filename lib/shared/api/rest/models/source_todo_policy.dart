// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// 투영 일정이 마감 표시이기를 그만둘 때(삭제·반복 전환) source Todo 처리 정책.
/// 서버 기본값은 없다.
@JsonEnum()
enum SourceTodoPolicy {
  @JsonValue('clear_deadline')
  clearDeadline('clear_deadline'),
  @JsonValue('keep_deadline')
  keepDeadline('keep_deadline'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const SourceTodoPolicy(this.json);

  factory SourceTodoPolicy.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<SourceTodoPolicy> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
