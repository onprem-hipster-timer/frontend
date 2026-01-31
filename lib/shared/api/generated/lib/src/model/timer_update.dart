//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:openapi_client/src/model/visibility_settings.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'timer_update.g.dart';

/// 타이머 업데이트 DTO  todo_id, schedule_id 필드 동작: - 필드가 요청에 포함되지 않음 (undefined): 기존 값 유지 - 필드가 UUID 값: 해당 ID로 연결 변경 - 필드가 null: 연결 해제  Note: 자동 연결 기능은 적용되지 않음 (명시적 변경만 수행)
///
/// Properties:
/// * [title] 
/// * [description] 
/// * [tagIds] 
/// * [todoId] 
/// * [scheduleId] 
/// * [visibility] 
@BuiltValue()
abstract class TimerUpdate implements Built<TimerUpdate, TimerUpdateBuilder> {
  @BuiltValueField(wireName: r'title')
  String? get title;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'tag_ids')
  BuiltList<String>? get tagIds;

  @BuiltValueField(wireName: r'todo_id')
  String? get todoId;

  @BuiltValueField(wireName: r'schedule_id')
  String? get scheduleId;

  @BuiltValueField(wireName: r'visibility')
  VisibilitySettings? get visibility;

  TimerUpdate._();

  factory TimerUpdate([void updates(TimerUpdateBuilder b)]) = _$TimerUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TimerUpdateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TimerUpdate> get serializer => _$TimerUpdateSerializer();
}

class _$TimerUpdateSerializer implements PrimitiveSerializer<TimerUpdate> {
  @override
  final Iterable<Type> types = const [TimerUpdate, _$TimerUpdate];

  @override
  final String wireName = r'TimerUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TimerUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
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
    if (object.tagIds != null) {
      yield r'tag_ids';
      yield serializers.serialize(
        object.tagIds,
        specifiedType: const FullType.nullable(BuiltList, [FullType(String)]),
      );
    }
    if (object.todoId != null) {
      yield r'todo_id';
      yield serializers.serialize(
        object.todoId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.scheduleId != null) {
      yield r'schedule_id';
      yield serializers.serialize(
        object.scheduleId,
        specifiedType: const FullType.nullable(String),
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
    TimerUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TimerUpdateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
        case r'tag_ids':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltList, [FullType(String)]),
          ) as BuiltList<String>?;
          if (valueDes == null) continue;
          result.tagIds.replace(valueDes);
          break;
        case r'todo_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.todoId = valueDes;
          break;
        case r'schedule_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.scheduleId = valueDes;
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
  TimerUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TimerUpdateBuilder();
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

