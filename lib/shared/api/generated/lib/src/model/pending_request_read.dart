//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'pending_request_read.g.dart';

/// 대기 중인 친구 요청 DTO
///
/// Properties:
/// * [id] 
/// * [requesterId] 
/// * [addresseeId] 
/// * [createdAt] 
@BuiltValue()
abstract class PendingRequestRead implements Built<PendingRequestRead, PendingRequestReadBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'requester_id')
  String get requesterId;

  @BuiltValueField(wireName: r'addressee_id')
  String get addresseeId;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  PendingRequestRead._();

  factory PendingRequestRead([void updates(PendingRequestReadBuilder b)]) = _$PendingRequestRead;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PendingRequestReadBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PendingRequestRead> get serializer => _$PendingRequestReadSerializer();
}

class _$PendingRequestReadSerializer implements PrimitiveSerializer<PendingRequestRead> {
  @override
  final Iterable<Type> types = const [PendingRequestRead, _$PendingRequestRead];

  @override
  final String wireName = r'PendingRequestRead';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PendingRequestRead object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'requester_id';
    yield serializers.serialize(
      object.requesterId,
      specifiedType: const FullType(String),
    );
    yield r'addressee_id';
    yield serializers.serialize(
      object.addresseeId,
      specifiedType: const FullType(String),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PendingRequestRead object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PendingRequestReadBuilder result,
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
        case r'requester_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.requesterId = valueDes;
          break;
        case r'addressee_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.addresseeId = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PendingRequestRead deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PendingRequestReadBuilder();
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

