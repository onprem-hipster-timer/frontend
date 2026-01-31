//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'tag_group_update.g.dart';

/// 태그 그룹 업데이트 DTO
///
/// Properties:
/// * [name] 
/// * [color] 
/// * [description] 
/// * [goalRatios] 
/// * [isTodoGroup] 
@BuiltValue()
abstract class TagGroupUpdate implements Built<TagGroupUpdate, TagGroupUpdateBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'color')
  String? get color;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'goal_ratios')
  BuiltMap<String, num>? get goalRatios;

  @BuiltValueField(wireName: r'is_todo_group')
  bool? get isTodoGroup;

  TagGroupUpdate._();

  factory TagGroupUpdate([void updates(TagGroupUpdateBuilder b)]) = _$TagGroupUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TagGroupUpdateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TagGroupUpdate> get serializer => _$TagGroupUpdateSerializer();
}

class _$TagGroupUpdateSerializer implements PrimitiveSerializer<TagGroupUpdate> {
  @override
  final Iterable<Type> types = const [TagGroupUpdate, _$TagGroupUpdate];

  @override
  final String wireName = r'TagGroupUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TagGroupUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.color != null) {
      yield r'color';
      yield serializers.serialize(
        object.color,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.goalRatios != null) {
      yield r'goal_ratios';
      yield serializers.serialize(
        object.goalRatios,
        specifiedType: const FullType.nullable(BuiltMap, [FullType(String), FullType(num)]),
      );
    }
    if (object.isTodoGroup != null) {
      yield r'is_todo_group';
      yield serializers.serialize(
        object.isTodoGroup,
        specifiedType: const FullType.nullable(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    TagGroupUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TagGroupUpdateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.name = valueDes;
          break;
        case r'color':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.color = valueDes;
          break;
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.description = valueDes;
          break;
        case r'goal_ratios':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltMap, [FullType(String), FullType(num)]),
          ) as BuiltMap<String, num>?;
          if (valueDes == null) continue;
          result.goalRatios.replace(valueDes);
          break;
        case r'is_todo_group':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          if (valueDes == null) continue;
          result.isTodoGroup = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TagGroupUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TagGroupUpdateBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

