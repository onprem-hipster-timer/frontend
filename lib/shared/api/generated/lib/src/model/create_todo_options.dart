//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_todo_options.g.dart';

/// Schedule 생성 시 함께 생성할 Todo 옵션
///
/// Properties:
/// * [tagGroupId] 
@BuiltValue()
abstract class CreateTodoOptions implements Built<CreateTodoOptions, CreateTodoOptionsBuilder> {
  @BuiltValueField(wireName: r'tag_group_id')
  String get tagGroupId;

  CreateTodoOptions._();

  factory CreateTodoOptions([void updates(CreateTodoOptionsBuilder b)]) = _$CreateTodoOptions;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateTodoOptionsBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateTodoOptions> get serializer => _$CreateTodoOptionsSerializer();
}

class _$CreateTodoOptionsSerializer implements PrimitiveSerializer<CreateTodoOptions> {
  @override
  final Iterable<Type> types = const [CreateTodoOptions, _$CreateTodoOptions];

  @override
  final String wireName = r'CreateTodoOptions';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateTodoOptions object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'tag_group_id';
    yield serializers.serialize(
      object.tagGroupId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateTodoOptions object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateTodoOptionsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'tag_group_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.tagGroupId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateTodoOptions deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateTodoOptionsBuilder();
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

