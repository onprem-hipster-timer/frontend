// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo_group_update.freezed.dart';
part 'todo_group_update.g.dart';

/// 할 일 그룹 업데이트 DTO
@Freezed()
abstract class TodoGroupUpdate with _$TodoGroupUpdate {
  const factory TodoGroupUpdate({
    String? name,
    String? color,
    String? description,
  }) = _TodoGroupUpdate;

  factory TodoGroupUpdate.fromJson(Map<String, Object?> json) =>
      _$TodoGroupUpdateFromJson(json);
}
