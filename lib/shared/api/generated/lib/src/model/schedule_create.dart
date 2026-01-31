//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:openapi_client/src/model/visibility_settings.dart';
import 'package:openapi_client/src/model/create_todo_options.dart';
import 'package:openapi_client/src/model/schedule_state.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'schedule_create.g.dart';

/// 일정 생성 DTO
///
/// Properties:
/// * [title] 
/// * [description] 
/// * [startTime] 
/// * [endTime] 
/// * [recurrenceRule] 
/// * [recurrenceEnd] 
/// * [tagIds] 
/// * [tagGroupId] 
/// * [sourceTodoId] 
/// * [state] 
/// * [createTodoOptions] 
/// * [visibility] 
@BuiltValue()
abstract class ScheduleCreate implements Built<ScheduleCreate, ScheduleCreateBuilder> {
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

  @BuiltValueField(wireName: r'tag_ids')
  BuiltList<String>? get tagIds;

  @BuiltValueField(wireName: r'tag_group_id')
  String? get tagGroupId;

  @BuiltValueField(wireName: r'source_todo_id')
  String? get sourceTodoId;

  @BuiltValueField(wireName: r'state')
  ScheduleState? get state;
  // enum stateEnum {  PLANNED,  CONFIRMED,  CANCELLED,  };

  @BuiltValueField(wireName: r'create_todo_options')
  CreateTodoOptions? get createTodoOptions;

  @BuiltValueField(wireName: r'visibility')
  VisibilitySettings? get visibility;

  ScheduleCreate._();

  factory ScheduleCreate([void updates(ScheduleCreateBuilder b)]) = _$ScheduleCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ScheduleCreateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ScheduleCreate> get serializer => _$ScheduleCreateSerializer();
}

class _$ScheduleCreateSerializer implements PrimitiveSerializer<ScheduleCreate> {
  @override
  final Iterable<Type> types = const [ScheduleCreate, _$ScheduleCreate];

  @override
  final String wireName = r'ScheduleCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ScheduleCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
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
    if (object.tagIds != null) {
      yield r'tag_ids';
      yield serializers.serialize(
        object.tagIds,
        specifiedType: const FullType.nullable(BuiltList, [FullType(String)]),
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
    if (object.state != null) {
      yield r'state';
      yield serializers.serialize(
        object.state,
        specifiedType: const FullType.nullable(ScheduleState),
      );
    }
    if (object.createTodoOptions != null) {
      yield r'create_todo_options';
      yield serializers.serialize(
        object.createTodoOptions,
        specifiedType: const FullType.nullable(CreateTodoOptions),
      );
    }
    if (object.visibility != null) {
      yield r'visibility';
      yield serializers.serialize(
        object.visibility,
        specifiedType: const FullType.nullable(VisibilitySettings),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ScheduleCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ScheduleCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
        case r'tag_ids':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltList, [FullType(String)]),
          ) as BuiltList<String>?;
          if (valueDes == null) continue;
          result.tagIds.replace(valueDes);
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
            specifiedType: const FullType.nullable(ScheduleState),
          ) as ScheduleState?;
          if (valueDes == null) continue;
          result.state = valueDes;
          break;
        case r'create_todo_options':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(CreateTodoOptions),
          ) as CreateTodoOptions?;
          if (valueDes == null) continue;
          result.createTodoOptions.replace(valueDes);
          break;
        case r'visibility':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(VisibilitySettings),
          ) as VisibilitySettings?;
          if (valueDes == null) continue;
          result.visibility.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ScheduleCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ScheduleCreateBuilder();
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

