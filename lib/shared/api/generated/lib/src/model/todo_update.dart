//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:openapi_client/src/model/todo_status.dart';
import 'package:openapi_client/src/model/visibility_settings.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'todo_update.g.dart';

/// Todo 업데이트 DTO
///
/// Properties:
/// * [title] 
/// * [description] 
/// * [tagGroupId] 
/// * [tagIds] 
/// * [deadline] 
/// * [parentId] 
/// * [status] 
/// * [visibility] 
@BuiltValue()
abstract class TodoUpdate implements Built<TodoUpdate, TodoUpdateBuilder> {
  @BuiltValueField(wireName: r'title')
  String? get title;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'tag_group_id')
  String? get tagGroupId;

  @BuiltValueField(wireName: r'tag_ids')
  BuiltList<String>? get tagIds;

  @BuiltValueField(wireName: r'deadline')
  DateTime? get deadline;

  @BuiltValueField(wireName: r'parent_id')
  String? get parentId;

  @BuiltValueField(wireName: r'status')
  TodoStatus? get status;
  // enum statusEnum {  UNSCHEDULED,  SCHEDULED,  DONE,  CANCELLED,  };

  @BuiltValueField(wireName: r'visibility')
  VisibilitySettings? get visibility;

  TodoUpdate._();

  factory TodoUpdate([void updates(TodoUpdateBuilder b)]) = _$TodoUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TodoUpdateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TodoUpdate> get serializer => _$TodoUpdateSerializer();
}

class _$TodoUpdateSerializer implements PrimitiveSerializer<TodoUpdate> {
  @override
  final Iterable<Type> types = const [TodoUpdate, _$TodoUpdate];

  @override
  final String wireName = r'TodoUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TodoUpdate object, {
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
    if (object.tagGroupId != null) {
      yield r'tag_group_id';
      yield serializers.serialize(
        object.tagGroupId,
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
    if (object.deadline != null) {
      yield r'deadline';
      yield serializers.serialize(
        object.deadline,
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
    if (object.status != null) {
      yield r'status';
      yield serializers.serialize(
        object.status,
        specifiedType: const FullType.nullable(TodoStatus),
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
    TodoUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TodoUpdateBuilder result,
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
        case r'tag_group_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.tagGroupId = valueDes;
          break;
        case r'tag_ids':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltList, [FullType(String)]),
          ) as BuiltList<String>?;
          if (valueDes == null) continue;
          result.tagIds.replace(valueDes);
          break;
        case r'deadline':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.deadline = valueDes;
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
            specifiedType: const FullType.nullable(TodoStatus),
          ) as TodoStatus?;
          if (valueDes == null) continue;
          result.status = valueDes;
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
  TodoUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TodoUpdateBuilder();
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

