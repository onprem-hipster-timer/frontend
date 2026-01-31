//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:openapi_client/src/model/todo_include_reason.dart';
import 'package:built_collection/built_collection.dart';
import 'package:openapi_client/src/model/tag_read.dart';
import 'package:openapi_client/src/model/todo_status.dart';
import 'package:openapi_client/src/model/visibility_level.dart';
import 'package:openapi_client/src/model/schedule_read.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'todo_read.g.dart';

/// Todo 조회 DTO
///
/// Properties:
/// * [id] 
/// * [title] 
/// * [description] 
/// * [deadline] 
/// * [tagGroupId] 
/// * [parentId] 
/// * [status] 
/// * [createdAt] 
/// * [tags] 
/// * [schedules] 
/// * [includeReason] 
/// * [ownerId] 
/// * [visibilityLevel] 
/// * [isShared] 
@BuiltValue()
abstract class TodoRead implements Built<TodoRead, TodoReadBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'title')
  String get title;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'deadline')
  DateTime? get deadline;

  @BuiltValueField(wireName: r'tag_group_id')
  String get tagGroupId;

  @BuiltValueField(wireName: r'parent_id')
  String? get parentId;

  @BuiltValueField(wireName: r'status')
  TodoStatus get status;
  // enum statusEnum {  UNSCHEDULED,  SCHEDULED,  DONE,  CANCELLED,  };

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'tags')
  BuiltList<TagRead>? get tags;

  @BuiltValueField(wireName: r'schedules')
  BuiltList<ScheduleRead>? get schedules;

  @BuiltValueField(wireName: r'include_reason')
  TodoIncludeReason? get includeReason;
  // enum includeReasonEnum {  MATCH,  ANCESTOR,  };

  @BuiltValueField(wireName: r'owner_id')
  String? get ownerId;

  @BuiltValueField(wireName: r'visibility_level')
  VisibilityLevel? get visibilityLevel;
  // enum visibilityLevelEnum {  private,  friends,  selected,  public,  };

  @BuiltValueField(wireName: r'is_shared')
  bool? get isShared;

  TodoRead._();

  factory TodoRead([void updates(TodoReadBuilder b)]) = _$TodoRead;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TodoReadBuilder b) => b
      ..tags = ListBuilder()
      ..schedules = ListBuilder()
      ..includeReason = const ._(TodoIncludeReason.MATCH)
      ..isShared = false;

  @BuiltValueSerializer(custom: true)
  static Serializer<TodoRead> get serializer => _$TodoReadSerializer();
}

class _$TodoReadSerializer implements PrimitiveSerializer<TodoRead> {
  @override
  final Iterable<Type> types = const [TodoRead, _$TodoRead];

  @override
  final String wireName = r'TodoRead';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TodoRead object, {
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
    if (object.deadline != null) {
      yield r'deadline';
      yield serializers.serialize(
        object.deadline,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    yield r'tag_group_id';
    yield serializers.serialize(
      object.tagGroupId,
      specifiedType: const FullType(String),
    );
    if (object.parentId != null) {
      yield r'parent_id';
      yield serializers.serialize(
        object.parentId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(TodoStatus),
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
    if (object.schedules != null) {
      yield r'schedules';
      yield serializers.serialize(
        object.schedules,
        specifiedType: const FullType(BuiltList, [FullType(ScheduleRead)]),
      );
    }
    if (object.includeReason != null) {
      yield r'include_reason';
      yield serializers.serialize(
        object.includeReason,
        specifiedType: const FullType(TodoIncludeReason),
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
    TodoRead object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TodoReadBuilder result,
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
        case r'deadline':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.deadline = valueDes;
          break;
        case r'tag_group_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.tagGroupId = valueDes;
          break;
        case r'parent_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.parentId = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TodoStatus),
          ) as TodoStatus;
          result.status = valueDes;
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
        case r'schedules':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ScheduleRead)]),
          ) as BuiltList<ScheduleRead>;
          result.schedules.replace(valueDes);
          break;
        case r'include_reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TodoIncludeReason),
          ) as TodoIncludeReason;
          result.includeReason = valueDes;
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
  TodoRead deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TodoReadBuilder();
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

