//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'todo_status.g.dart';

class TodoStatus extends EnumClass {

  /// Todo 상태
  @BuiltValueEnumConst(wireName: r'UNSCHEDULED')
  static const TodoStatus UNSCHEDULED = _$UNSCHEDULED;
  /// Todo 상태
  @BuiltValueEnumConst(wireName: r'SCHEDULED')
  static const TodoStatus SCHEDULED = _$SCHEDULED;
  /// Todo 상태
  @BuiltValueEnumConst(wireName: r'DONE')
  static const TodoStatus DONE = _$DONE;
  /// Todo 상태
  @BuiltValueEnumConst(wireName: r'CANCELLED')
  static const TodoStatus CANCELLED = _$CANCELLED;
  /// Todo 상태
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const TodoStatus unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<TodoStatus> get serializer => _$todoStatusSerializer;

  const TodoStatus._(String name): super(name);

  static BuiltSet<TodoStatus> get values => _$values;
  static TodoStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class TodoStatusMixin = Object with _$TodoStatusMixin;

