//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:openapi_client/src/model/tag_read.dart';
import 'package:openapi_client/src/model/visibility_level.dart';
import 'package:openapi_client/src/model/schedule_state.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'schedule_read.g.dart';

/// 일정 조회 DTO
///
/// Properties:
/// * [id] 
/// * [title] 
/// * [description] 
/// * [startTime] 
/// * [endTime] 
/// * [recurrenceRule] 
/// * [recurrenceEnd] 
/// * [parentId] 
/// * [tagGroupId] 
/// * [sourceTodoId] 
/// * [state] 
/// * [createdAt] 
/// * [tags] 
/// * [ownerId] 
/// * [visibilityLevel] 
/// * [isShared] 
@BuiltValue()
abstract class ScheduleRead implements Built<ScheduleRead, ScheduleReadBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'title')
  String get title;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'start_time')
  DateTime get startTime;

  @BuiltValueField(wireName: r'end_time')
  DateTime get endTime;

  @BuiltValueField(wireName: r'recurrence_rule')
  String? get recurrenceRule;

  @BuiltValueField(wireName: r'recurrence_end')
  DateTime? get recurrenceEnd;

  @BuiltValueField(wireName: r'parent_id')
  String? get parentId;

  @BuiltValueField(wireName: r'tag_group_id')
  String? get tagGroupId;

  @BuiltValueField(wireName: r'source_todo_id')
  String? get sourceTodoId;

  @BuiltValueField(wireName: r'state')
  ScheduleState get state;
  // enum stateEnum {  PLANNED,  CONFIRMED,  CANCELLED,  };

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'tags')
  BuiltList<TagRead>? get tags;

  @BuiltValueField(wireName: r'owner_id')
  String? get ownerId;

  @BuiltValueField(wireName: r'visibility_level')
  VisibilityLevel? get visibilityLevel;
  // enum visibilityLevelEnum {  private,  friends,  selected,  public,  };

  @BuiltValueField(wireName: r'is_shared')
  bool? get isShared;

  ScheduleRead._();

  factory ScheduleRead([void updates(ScheduleReadBuilder b)]) = _$ScheduleRead;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ScheduleReadBuilder b) => b
      ..tags = ListBuilder()
      ..isShared = false;

  @BuiltValueSerializer(custom: true)
  static Serializer<ScheduleRead> get serializer => _$ScheduleReadSerializer();
}

class _$ScheduleReadSerializer implements PrimitiveSerializer<ScheduleRead> {
  @override
  final Iterable<Type> types = const [ScheduleRead, _$ScheduleRead];

  @override
  final String wireName = r'ScheduleRead';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ScheduleRead object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'start_time';
    yield serializers.serialize(
      object.startTime,
      specifiedType: const FullType(DateTime),
    );
    yield r'end_time';
    yield serializers.serialize(
      object.endTime,
      specifiedType: const FullType(DateTime),
    );
    if (object.recurrenceRule != null) {
      yield r'recurrence_rule';
      yield serializers.serialize(
        object.recurrenceRule,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.recurrenceEnd != null) {
      yield r'recurrence_end';
      yield serializers.serialize(
        object.recurrenceEnd,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.parentId != null) {
      yield r'parent_id';
      yield serializers.serialize(
        object.parentId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.tagGroupId != null) {
      yield r'tag_group_id';
      yield serializers.serialize(
        object.tagGroupId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.sourceTodoId != null) {
      yield r'source_todo_id';
      yield serializers.serialize(
        object.sourceTodoId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'state';
    yield serializers.serialize(
      object.state,
      specifiedType: const FullType(ScheduleState),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.tags != null) {
      yield r'tags';
      yield serializers.serialize(
        object.tags,
        specifiedType: const FullType(BuiltList, [FullType(TagRead)]),
      );
    }
    if (object.ownerId != null) {
      yield r'owner_id';
      yield serializers.serialize(
        object.ownerId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.visibilityLevel != null) {
      yield r'visibility_level';
      yield serializers.serialize(
        object.visibilityLevel,
        specifiedType: const FullType.nullable(VisibilityLevel),
      );
    }
    if (object.isShared != null) {
      yield r'is_shared';
      yield serializers.serialize(
        object.isShared,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ScheduleRead object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ScheduleReadBuilder result,
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
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.description = valueDes;
          break;
        case r'start_time':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.startTime = valueDes;
          break;
        case r'end_time':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.endTime = valueDes;
          break;
        case r'recurrence_rule':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.recurrenceRule = valueDes;
          break;
        case r'recurrence_end':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.recurrenceEnd = valueDes;
          break;
        case r'parent_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.parentId = valueDes;
          break;
        case r'tag_group_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.tagGroupId = valueDes;
          break;
        case r'source_todo_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.sourceTodoId = valueDes;
          break;
        case r'state':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ScheduleState),
          ) as ScheduleState;
          result.state = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'tags':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(TagRead)]),
          ) as BuiltList<TagRead>;
          result.tags.replace(valueDes);
          break;
        case r'owner_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.ownerId = valueDes;
          break;
        case r'visibility_level':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(VisibilityLevel),
          ) as VisibilityLevel?;
          if (valueDes == null) continue;
          result.visibilityLevel = valueDes;
          break;
        case r'is_shared':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isShared = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ScheduleRead deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ScheduleReadBuilder();
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

