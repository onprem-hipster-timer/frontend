//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'tag_group_create.g.dart';

/// 태그 그룹 생성 DTO
///
/// Properties:
/// * [name] 
/// * [color] 
/// * [description] 
/// * [goalRatios] 
/// * [isTodoGroup] 
@BuiltValue()
abstract class TagGroupCreate implements Built<TagGroupCreate, TagGroupCreateBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'color')
  String get color;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'goal_ratios')
  BuiltMap<String, num>? get goalRatios;

  @BuiltValueField(wireName: r'is_todo_group')
  bool? get isTodoGroup;

  TagGroupCreate._();

  factory TagGroupCreate([void updates(TagGroupCreateBuilder b)]) = _$TagGroupCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TagGroupCreateBuilder b) => b
      ..isTodoGroup = false;

  @BuiltValueSerializer(custom: true)
  static Serializer<TagGroupCreate> get serializer => _$TagGroupCreateSerializer();
}

class _$TagGroupCreateSerializer implements PrimitiveSerializer<TagGroupCreate> {
  @override
  final Iterable<Type> types = const [TagGroupCreate, _$TagGroupCreate];

  @override
  final String wireName = r'TagGroupCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TagGroupCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'color';
    yield serializers.serialize(
      object.color,
      specifiedType: const FullType(String),
    );
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
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    TagGroupCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TagGroupCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'color':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
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
            specifiedType: const FullType(bool),
          ) as bool;
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
  TagGroupCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TagGroupCreateBuilder();
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

