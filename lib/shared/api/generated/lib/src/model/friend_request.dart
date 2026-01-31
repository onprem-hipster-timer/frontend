//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'friend_request.g.dart';

/// 친구 요청 DTO
///
/// Properties:
/// * [addresseeId] 
@BuiltValue()
abstract class FriendRequest implements Built<FriendRequest, FriendRequestBuilder> {
  @BuiltValueField(wireName: r'addressee_id')
  String get addresseeId;

  FriendRequest._();

  factory FriendRequest([void updates(FriendRequestBuilder b)]) = _$FriendRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FriendRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FriendRequest> get serializer => _$FriendRequestSerializer();
}

class _$FriendRequestSerializer implements PrimitiveSerializer<FriendRequest> {
  @override
  final Iterable<Type> types = const [FriendRequest, _$FriendRequest];

  @override
  final String wireName = r'FriendRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FriendRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'addressee_id';
    yield serializers.serialize(
      object.addresseeId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FriendRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FriendRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'addressee_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.addresseeId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FriendRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FriendRequestBuilder();
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

