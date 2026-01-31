//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'resource_scope.g.dart';

class ResourceScope extends EnumClass {

  /// 리소스 조회 범위 (공유 리소스 포함 여부)
  @BuiltValueEnumConst(wireName: r'mine')
  static const ResourceScope mine = _$mine;
  /// 리소스 조회 범위 (공유 리소스 포함 여부)
  @BuiltValueEnumConst(wireName: r'shared')
  static const ResourceScope shared = _$shared;
  /// 리소스 조회 범위 (공유 리소스 포함 여부)
  @BuiltValueEnumConst(wireName: r'all')
  static const ResourceScope all = _$all;

  static Serializer<ResourceScope> get serializer => _$resourceScopeSerializer;

  const ResourceScope._(String name): super(name);

  static BuiltSet<ResourceScope> get values => _$values;
  static ResourceScope valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ResourceScopeMixin = Object with _$ResourceScopeMixin;

