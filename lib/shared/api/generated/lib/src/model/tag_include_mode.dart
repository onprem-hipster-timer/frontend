//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'tag_include_mode.g.dart';

class TagIncludeMode extends EnumClass {

  /// 타이머 태그 포함 모드
  @BuiltValueEnumConst(wireName: r'none')
  static const TagIncludeMode none = _$none;
  /// 타이머 태그 포함 모드
  @BuiltValueEnumConst(wireName: r'timer_only')
  static const TagIncludeMode timerOnly = _$timerOnly;
  /// 타이머 태그 포함 모드
  @BuiltValueEnumConst(wireName: r'inherit_from_schedule')
  static const TagIncludeMode inheritFromSchedule = _$inheritFromSchedule;
  /// 타이머 태그 포함 모드
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const TagIncludeMode unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<TagIncludeMode> get serializer => _$tagIncludeModeSerializer;

  const TagIncludeMode._(String name): super(name);

  static BuiltSet<TagIncludeMode> get values => _$values;
  static TagIncludeMode valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class TagIncludeModeMixin = Object with _$TagIncludeModeMixin;

