//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'visibility_level.g.dart';

class VisibilityLevel extends EnumClass {

  /// 가시성 레벨
  @BuiltValueEnumConst(wireName: r'private')
  static const VisibilityLevel private = _$private;
  /// 가시성 레벨
  @BuiltValueEnumConst(wireName: r'friends')
  static const VisibilityLevel friends = _$friends;
  /// 가시성 레벨
  @BuiltValueEnumConst(wireName: r'selected')
  static const VisibilityLevel selected = _$selected;
  /// 가시성 레벨
  @BuiltValueEnumConst(wireName: r'public')
  static const VisibilityLevel public = _$public;

  static Serializer<VisibilityLevel> get serializer => _$visibilityLevelSerializer;

  const VisibilityLevel._(String name): super(name);

  static BuiltSet<VisibilityLevel> get values => _$values;
  static VisibilityLevel valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class VisibilityLevelMixin = Object with _$VisibilityLevelMixin;

