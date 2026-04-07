// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// 접근권한 레벨
@JsonEnum()
enum VisibilityLevel {
  @JsonValue('private')
  private('private'),
  @JsonValue('friends')
  friends('friends'),
  @JsonValue('selected')
  selected('selected'),
  @JsonValue('allowed_emails')
  allowedEmails('allowed_emails'),
  @JsonValue('public')
  public('public'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const VisibilityLevel(this.json);

  factory VisibilityLevel.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<VisibilityLevel> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
