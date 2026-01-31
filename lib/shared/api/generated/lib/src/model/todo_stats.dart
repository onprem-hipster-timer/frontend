//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:momeet_api/src/model/tag_stat.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'todo_stats.g.dart';

/// Todo 통계
///
/// Properties:
/// * [groupId] 
/// * [totalCount] 
/// * [byTag] 
@BuiltValue()
abstract class TodoStats implements Built<TodoStats, TodoStatsBuilder> {
  @BuiltValueField(wireName: r'group_id')
  String? get groupId;

  @BuiltValueField(wireName: r'total_count')
  int get totalCount;

  @BuiltValueField(wireName: r'by_tag')
  BuiltList<TagStat> get byTag;

  TodoStats._();

  factory TodoStats([void updates(TodoStatsBuilder b)]) = _$TodoStats;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TodoStatsBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TodoStats> get serializer => _$TodoStatsSerializer();
}

class _$TodoStatsSerializer implements PrimitiveSerializer<TodoStats> {
  @override
  final Iterable<Type> types = const [TodoStats, _$TodoStats];

  @override
  final String wireName = r'TodoStats';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TodoStats object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.groupId != null) {
      yield r'group_id';
      yield serializers.serialize(
        object.groupId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'total_count';
    yield serializers.serialize(
      object.totalCount,
      specifiedType: const FullType(int),
    );
    yield r'by_tag';
    yield serializers.serialize(
      object.byTag,
      specifiedType: const FullType(BuiltList, [FullType(TagStat)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TodoStats object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TodoStatsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'group_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.groupId = valueDes;
          break;
        case r'total_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalCount = valueDes;
          break;
        case r'by_tag':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(TagStat)]),
          ) as BuiltList<TagStat>;
          result.byTag.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TodoStats deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TodoStatsBuilder();
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

