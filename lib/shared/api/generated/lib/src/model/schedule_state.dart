//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'schedule_state.g.dart';

class ScheduleState extends EnumClass {

  /// Schedule 상태
  @BuiltValueEnumConst(wireName: r'PLANNED')
  static const ScheduleState PLANNED = _$PLANNED;
  /// Schedule 상태
  @BuiltValueEnumConst(wireName: r'CONFIRMED')
  static const ScheduleState CONFIRMED = _$CONFIRMED;
  /// Schedule 상태
  @BuiltValueEnumConst(wireName: r'CANCELLED')
  static const ScheduleState CANCELLED = _$CANCELLED;
  /// Schedule 상태
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const ScheduleState unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<ScheduleState> get serializer => _$scheduleStateSerializer;

  const ScheduleState._(String name): super(name);

  static BuiltSet<ScheduleState> get values => _$values;
  static ScheduleState valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ScheduleStateMixin = Object with _$ScheduleStateMixin;

