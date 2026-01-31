//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:openapi_client/src/model/tag_read.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'tag_group_read_with_tags.g.dart';

/// 태그 그룹 조회 DTO (태그 포함)
///
/// Properties:
/// * [id] 
/// * [name] 
/// * [color] 
/// * [description] 
/// * [goalRatios] 
/// * [isTodoGroup] 
/// * [createdAt] 
/// * [updatedAt] 
/// * [tags] 
@BuiltValue()
abstract class TagGroupReadWithTags implements Built<TagGroupReadWithTags, TagGroupReadWithTagsBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'color')
  String get color;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'goal_ratios')
  BuiltMap<String, num>? get goalRatios;

  @BuiltValueField(wireName: r'is_todo_group')
  bool get isTodoGroup;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updated_at')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'tags')
  BuiltList<TagRead>? get tags;

  TagGroupReadWithTags._();

  factory TagGroupReadWithTags([void updates(TagGroupReadWithTagsBuilder b)]) = _$TagGroupReadWithTags;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TagGroupReadWithTagsBuilder b) => b
      ..tags = ListBuilder();

  @BuiltValueSerializer(custom: true)
  static Serializer<TagGroupReadWithTags> get serializer => _$TagGroupReadWithTagsSerializer();
}

class _$TagGroupReadWithTagsSerializer implements PrimitiveSerializer<TagGroupReadWithTags> {
  @override
  final Iterable<Type> types = const [TagGroupReadWithTags, _$TagGroupReadWithTags];

  @override
  final String wireName = r'TagGroupReadWithTags';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TagGroupReadWithTags object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
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
    yield r'is_todo_group';
    yield serializers.serialize(
      object.isTodoGroup,
      specifiedType: const FullType(bool),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'updated_at';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.tags != null) {
      yield r'tags';
      yield serializers.serialize(
        object.tags,
        specifiedType: const FullType(BuiltList, [FullType(TagRead)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    TagGroupReadWithTags object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TagGroupReadWithTagsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
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
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'updated_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        case r'tags':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(TagRead)]),
          ) as BuiltList<TagRead>;
          result.tags.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TagGroupReadWithTags deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TagGroupReadWithTagsBuilder();
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

