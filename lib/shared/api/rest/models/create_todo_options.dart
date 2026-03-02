// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_todo_options.freezed.dart';
part 'create_todo_options.g.dart';

/// Schedule 생성 시 함께 생성할 Todo 옵션
@Freezed()
abstract class CreateTodoOptions with _$CreateTodoOptions {
  const factory CreateTodoOptions({
    @JsonKey(name: 'tag_group_id') required String tagGroupId,
  }) = _CreateTodoOptions;

  factory CreateTodoOptions.fromJson(Map<String, Object?> json) =>
      _$CreateTodoOptionsFromJson(json);
}
