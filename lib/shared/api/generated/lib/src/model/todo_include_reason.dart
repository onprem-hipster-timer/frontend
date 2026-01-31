//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'todo_include_reason.g.dart';

class TodoIncludeReason extends EnumClass {

  /// Todo가 응답에 포함된 사유
  @BuiltValueEnumConst(wireName: r'MATCH')
  static const TodoIncludeReason MATCH = _$MATCH;
  /// Todo가 응답에 포함된 사유
  @BuiltValueEnumConst(wireName: r'ANCESTOR')
  static const TodoIncludeReason ANCESTOR = _$ANCESTOR;

  static Serializer<TodoIncludeReason> get serializer => _$todoIncludeReasonSerializer;

  const TodoIncludeReason._(String name): super(name);

  static BuiltSet<TodoIncludeReason> get values => _$values;
  static TodoIncludeReason valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class TodoIncludeReasonMixin = Object with _$TodoIncludeReasonMixin;

