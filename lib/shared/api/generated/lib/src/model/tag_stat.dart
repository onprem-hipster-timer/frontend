//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'tag_stat.g.dart';

/// 태그별 통계
///
/// Properties:
/// * [tagId] 
/// * [tagName] 
/// * [count] 
@BuiltValue()
abstract class TagStat implements Built<TagStat, TagStatBuilder> {
  @BuiltValueField(wireName: r'tag_id')
  String get tagId;

  @BuiltValueField(wireName: r'tag_name')
  String get tagName;

  @BuiltValueField(wireName: r'count')
  int get count;

  TagStat._();

  factory TagStat([void updates(TagStatBuilder b)]) = _$TagStat;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TagStatBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TagStat> get serializer => _$TagStatSerializer();
}

class _$TagStatSerializer implements PrimitiveSerializer<TagStat> {
  @override
  final Iterable<Type> types = const [TagStat, _$TagStat];

  @override
  final String wireName = r'TagStat';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TagStat object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'tag_id';
    yield serializers.serialize(
      object.tagId,
      specifiedType: const FullType(String),
    );
    yield r'tag_name';
    yield serializers.serialize(
      object.tagName,
      specifiedType: const FullType(String),
    );
    yield r'count';
    yield serializers.serialize(
      object.count,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TagStat object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TagStatBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'tag_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.tagId = valueDes;
          break;
        case r'tag_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.tagName = valueDes;
          break;
        case r'count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.count = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TagStat deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TagStatBuilder();
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

