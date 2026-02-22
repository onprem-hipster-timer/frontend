// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// Todo 상태
@JsonEnum()
enum TodoStatus {
  @JsonValue('UNSCHEDULED')
  unscheduled('UNSCHEDULED'),
  @JsonValue('SCHEDULED')
  scheduled('SCHEDULED'),
  @JsonValue('DONE')
  done('DONE'),
  @JsonValue('CANCELLED')
  cancelled('CANCELLED'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const TodoStatus(this.json);

  factory TodoStatus.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<TodoStatus> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
