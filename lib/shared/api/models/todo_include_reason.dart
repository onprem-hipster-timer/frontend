// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// Todo가 응답에 포함된 사유
@JsonEnum()
enum TodoIncludeReason {
  @JsonValue('MATCH')
  match('MATCH'),
  @JsonValue('ANCESTOR')
  ancestor('ANCESTOR'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const TodoIncludeReason(this.json);

  factory TodoIncludeReason.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<TodoIncludeReason> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
