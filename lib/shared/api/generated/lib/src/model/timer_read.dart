//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:openapi_client/src/model/tag_read.dart';
import 'package:openapi_client/src/model/visibility_level.dart';
import 'package:openapi_client/src/model/schedule_read.dart';
import 'package:built_value/json_object.dart';
import 'package:openapi_client/src/model/todo_read.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'timer_read.g.dart';

/// 타이머 조회 DTO
///
/// Properties:
/// * [id] 
/// * [scheduleId] 
/// * [todoId] 
/// * [title] 
/// * [description] 
/// * [allocatedDuration] 
/// * [elapsedTime] 
/// * [status] 
/// * [startedAt] 
/// * [pausedAt] 
/// * [endedAt] 
/// * [createdAt] 
/// * [updatedAt] 
/// * [pauseHistory] 
/// * [schedule] 
/// * [todo] 
/// * [tags] 
/// * [ownerId] 
/// * [visibilityLevel] 
/// * [isShared] 
@BuiltValue()
abstract class TimerRead implements Built<TimerRead, TimerReadBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'schedule_id')
  String? get scheduleId;

  @BuiltValueField(wireName: r'todo_id')
  String? get todoId;

  @BuiltValueField(wireName: r'title')
  String? get title;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'allocated_duration')
  int get allocatedDuration;

  @BuiltValueField(wireName: r'elapsed_time')
  int get elapsedTime;

  @BuiltValueField(wireName: r'status')
  String get status;

  @BuiltValueField(wireName: r'started_at')
  DateTime? get startedAt;

  @BuiltValueField(wireName: r'paused_at')
  DateTime? get pausedAt;

  @BuiltValueField(wireName: r'ended_at')
  DateTime? get endedAt;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updated_at')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'pause_history')
  BuiltList<BuiltMap<String, JsonObject?>>? get pauseHistory;

  @BuiltValueField(wireName: r'schedule')
  ScheduleRead? get schedule;

  @BuiltValueField(wireName: r'todo')
  TodoRead? get todo;

  @BuiltValueField(wireName: r'tags')
  BuiltList<TagRead>? get tags;

  @BuiltValueField(wireName: r'owner_id')
  String? get ownerId;

  @BuiltValueField(wireName: r'visibility_level')
  VisibilityLevel? get visibilityLevel;
  // enum visibilityLevelEnum {  private,  friends,  selected,  public,  };

  @BuiltValueField(wireName: r'is_shared')
  bool? get isShared;

  TimerRead._();

  factory TimerRead([void updates(TimerReadBuilder b)]) = _$TimerRead;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TimerReadBuilder b) => b
      ..pauseHistory = ListBuilder()
      ..tags = ListBuilder()
      ..isShared = false;

  @BuiltValueSerializer(custom: true)
  static Serializer<TimerRead> get serializer => _$TimerReadSerializer();
}

class _$TimerReadSerializer implements PrimitiveSerializer<TimerRead> {
  @override
  final Iterable<Type> types = const [TimerRead, _$TimerRead];

  @override
  final String wireName = r'TimerRead';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TimerRead object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    if (object.scheduleId != null) {
      yield r'schedule_id';
      yield serializers.serialize(
        object.scheduleId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.todoId != null) {
      yield r'todo_id';
      yield serializers.serialize(
        object.todoId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.title != null) {
      yield r'title';
      yield serializers.serialize(
        object.title,
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
    yield r'allocated_duration';
    yield serializers.serialize(
      object.allocatedDuration,
      specifiedType: const FullType(int),
    );
    yield r'elapsed_time';
    yield serializers.serialize(
      object.elapsedTime,
      specifiedType: const FullType(int),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(String),
    );
    if (object.startedAt != null) {
      yield r'started_at';
      yield serializers.serialize(
        object.startedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.pausedAt != null) {
      yield r'paused_at';
      yield serializers.serialize(
        object.pausedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.endedAt != null) {
      yield r'ended_at';
      yield serializers.serialize(
        object.endedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
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
    if (object.pauseHistory != null) {
      yield r'pause_history';
      yield serializers.serialize(
        object.pauseHistory,
        specifiedType: const FullType(BuiltList, [FullType(BuiltMap, [FullType(String), FullType.nullable(JsonObject)])]),
      );
    }
    if (object.schedule != null) {
      yield r'schedule';
      yield serializers.serialize(
        object.schedule,
        specifiedType: const FullType.nullable(ScheduleRead),
      );
    }
    if (object.todo != null) {
      yield r'todo';
      yield serializers.serialize(
        object.todo,
        specifiedType: const FullType.nullable(TodoRead),
      );
    }
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
    TimerRead object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TimerReadBuilder result,
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
        case r'schedule_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.scheduleId = valueDes;
          break;
        case r'todo_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.todoId = valueDes;
          break;
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
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
        case r'allocated_duration':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.allocatedDuration = valueDes;
          break;
        case r'elapsed_time':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.elapsedTime = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.status = valueDes;
          break;
        case r'started_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.startedAt = valueDes;
          break;
        case r'paused_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.pausedAt = valueDes;
          break;
        case r'ended_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.endedAt = valueDes;
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
        case r'pause_history':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(BuiltMap, [FullType(String), FullType.nullable(JsonObject)])]),
          ) as BuiltList<BuiltMap<String, JsonObject?>>;
          result.pauseHistory.replace(valueDes);
          break;
        case r'schedule':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(ScheduleRead),
          ) as ScheduleRead?;
          if (valueDes == null) continue;
          result.schedule.replace(valueDes);
          break;
        case r'todo':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(TodoRead),
          ) as TodoRead?;
          if (valueDes == null) continue;
          result.todo.replace(valueDes);
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
  TimerRead deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TimerReadBuilder();
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

